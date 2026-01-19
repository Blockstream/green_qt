#include "watchonlylogincontroller.h"

#include <gdk.h>

#include "context.h"
#include "network.h"
#include "session.h"
#include "task.h"
#include "wallet.h"
#include "walletmanager.h"

#include <QJsonDocument>

WatchOnlyLoginController::WatchOnlyLoginController(QObject* parent)
    : Controller(parent)
{
//    new WatchOnlyCreateWalletTask(this);

//    connect(m_dispatcher, &TaskDispatcher::finished, this, [=] {
//        if (m_wallet) {
//            m_wallet->setContext(m_context);
//            WalletManager::instance()->addWallet(m_wallet);
//            setWallet(nullptr);
//        }
//    });

//    connect(this, &LoginController::walletChanged, this, [=] {
//        if (m_wallet && m_wallet->isWatchOnly()) {
//            setUsername(m_wallet->username());
//            setNetwork(m_wallet->network());
//        }
//        updateValid();
//    });
}

void WatchOnlyLoginController::setNetwork(Network* network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged();
    void update();
}

void WatchOnlyLoginController::setUsername(const QString& username)
{
    if (m_username == username) return;
    m_username = username;
    emit usernameChanged();
    update();
}

void WatchOnlyLoginController::setPassword(const QString& password)
{
    if (m_password == password) return;
    m_password = password;
    emit passwordChanged();
    update();
}

void WatchOnlyLoginController::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
    if (m_context) m_context->setWallet(wallet);
    update();
}

void WatchOnlyLoginController::setSaveWallet(bool save_wallet)
{
    if (m_save_wallet == save_wallet) return;
    m_save_wallet = save_wallet;
    emit saveWalletChanged();
}

void WatchOnlyLoginController::update()
{
    if (m_wallet) {
        auto watchonly_data = qobject_cast<WatchonlyData*>(m_wallet->login());
        if (!watchonly_data || !watchonly_data->network()) {
            setValid(false);
        } else if (!watchonly_data->network()->isElectrum()) {
            setValid(!m_password.isEmpty());
        } else {
            setValid(true);
        }
    } else {
        setValid(m_network && !m_username.isEmpty() && !m_password.isEmpty());
    }
}

void WatchOnlyLoginController::login()
{
    auto watchonly_data = m_wallet ? qobject_cast<WatchonlyData*>(m_wallet->login()) : nullptr;

    const auto network = watchonly_data ? watchonly_data->network() : m_network;

    setContext(ContextManager::instance()->create(network->deployment(), false));
    m_context->setWatchonly(true);

    auto session = m_context->getOrCreateSession(network);

    if (!network->isElectrum()) {
        const auto username = watchonly_data ? watchonly_data->username() : m_username;
        login(new LoginTask(username, m_password, session));
    } else if (!watchonly_data->extendedPubkeys().isEmpty()) {
        setValid(true);
        const auto slip132_extended_pubkeys = QJsonArray::fromStringList(watchonly_data->extendedPubkeys());
        login(new LoginTask(QJsonObject{{ "slip132_extended_pubkeys", slip132_extended_pubkeys }}, QJsonObject{}, session));
    } else if (!watchonly_data->coreDescriptors().isEmpty()) {
        setValid(true);
        const auto core_descriptors = QJsonArray::fromStringList(watchonly_data->coreDescriptors());
        login(new LoginTask(QJsonObject{{ "core_descriptors", core_descriptors }}, QJsonObject{}, session));
    }
}

void WatchOnlyLoginController::login(LoginTask* login_task)
{
    Q_ASSERT(m_valid);
    m_error.clear();

    if (m_monitor) m_monitor->deleteLater();
    m_monitor = new TaskGroupMonitor(this);
    emit monitorChanged();

    auto session = login_task->session();
    auto network = session->network();

    auto connect_session = new ConnectTask(session);
    auto create_wallet = new WatchOnlyCreateWalletTask(this);

    connect(connect_session, &Task::failed, this, [=](const QString& error) {
        if (!m_error.isEmpty()) return;
        if (error == "timeout error") {
            m_error = "id_connection_failed";
        } else {
            m_error = error;
        }
    });
    connect(login_task, &Task::failed, this, [=](const QString& error) {
        if (!m_error.isEmpty()) return;
        m_error = error;
    });

    m_context->setWallet(m_wallet);

    connect_session->then(login_task);
    login_task->then(create_wallet);

    auto group = new TaskGroup(this);

    group->add(connect_session);
    group->add(login_task);
    group->add(create_wallet);

    dispatcher()->add(group);
    m_monitor->add(group);

    connect(group, &TaskGroup::finished, this, &WatchOnlyLoginController::loginFinished);
    connect(group, &TaskGroup::failed, this, [=] {
        emit loginFailed(m_error);
    });
}

void WatchOnlyLoginController::loginExtendedPublicKeys(const QString& input)
{
    qDebug() << m_network->id();

    setContext(ContextManager::instance()->create(m_network->deployment(), false));
    m_context->setWatchonly(true);

    auto session = m_context->getOrCreateSession(m_network);

    m_extended_pubkeys = input.split('\n', Qt::SkipEmptyParts);

    setValid(true);
    login(new LoginTask(QJsonObject{{ "slip132_extended_pubkeys", QJsonArray::fromStringList(m_extended_pubkeys) }}, QJsonObject{}, session));
}

void WatchOnlyLoginController::loginDescriptors(const QString& input)
{
    setContext(ContextManager::instance()->create(m_network->deployment(), false));
    m_context->setWatchonly(true);

    auto session = m_context->getOrCreateSession(m_network);

    m_core_descriptors = input.split('\n', Qt::SkipEmptyParts);

    QJsonObject details{{ "core_descriptors", QJsonArray::fromStringList(m_core_descriptors) }};

    setValid(true);
    login(new LoginTask(details, QJsonObject{}, session));
}

QStringList WatchOnlyLoginController::parseFile(const QUrl& url)
{
    if (!url.isLocalFile()) return {};
    const auto path = url.toLocalFile();
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return {};
    }
    const auto doc = QJsonDocument::fromJson(file.readAll());
    const auto content = doc.object();
    QStringList xpubs;
    if (content.value("chain").toString() == "BTC") {
        for (const auto i : content) {
            if (!i.isObject()) continue;
            const auto bip = i.toObject();
            const auto name = bip.value("name").toString();
            if (name != "p2pkh" && name != "p2sh-p2wpkh" && name != "p2wpkh" && name != "p2tr") continue;
            const auto pub = bip.value("_pub").toString();
            const auto xpub = bip.value("xpub").toString();
            if (!pub.isEmpty()) {
                xpubs.append(pub);
            } else if (!xpub.isEmpty()) {
                xpubs.append(xpub);
            }
        }
    } else if (content.value("wallet_type").toString() == "standard") {
        const auto keystore = content.value("keystore").toObject();
        const auto xpub = keystore.value("xpub").toString();
        xpubs.append(xpub);
    }
    return xpubs;
}

void WatchOnlyLoginController::setValid(bool valid)
{
    if (m_valid == valid) return;
    m_valid = valid;
    emit validChanged();
}

WatchOnlyCreateWalletTask::WatchOnlyCreateWalletTask(WatchOnlyLoginController* controller)
    : Task(controller)
    , m_controller(controller)
{
}

void WatchOnlyCreateWalletTask::update()
{
    if (m_status != Status::Ready) return;

    const auto context = m_controller->context();
    const auto xpub_hash_id = context->xpubHashId();
    if (xpub_hash_id.isEmpty()) return;

    setStatus(Status::Active);

    auto wallet = m_controller->wallet();
    if (!wallet) {
        for (auto w : WalletManager::instance()->getWallets()) {
            if (w->xpubHashId() != xpub_hash_id) continue;
            auto watchonly_data = qobject_cast<WatchonlyData*>(w->login());
            if (!watchonly_data) continue;
            if (watchonly_data->network() != m_controller->network()) continue;
            wallet = w;
            break;
        }
        if (!wallet) {
            wallet = WalletManager::instance()->createWallet();
            auto watchonly_data = new WatchonlyData(wallet);
            watchonly_data->setNetwork(m_controller->network());
            watchonly_data->setUsername(m_controller->username());
            watchonly_data->setExtendedPubkeys(m_controller->extendedPubkeys());
            watchonly_data->setCoreDescriptors(m_controller->coreDescriptors());

            QString name = qtTrId("id_watchonly_wallet");
            if (!m_controller->username().isEmpty()) {
                name = m_controller->username() + " " + name;
            }
            wallet->setName(WalletManager::instance()->uniqueWalletName(name));
            wallet->setLogin(watchonly_data);
            wallet->m_deployment = m_controller->network()->deployment();
            wallet->m_is_persisted = m_controller->saveWallet();
        }
        context->setWallet(wallet);
        wallet->save();
    }
    wallet->setContext(context);
    m_controller->setWallet(wallet);

    setStatus(Status::Finished);
}
