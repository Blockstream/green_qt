#include "loginwithpincontroller.h"

#include "context.h"
#include "jadedevice.h"
#include "network.h"
#include "networkmanager.h"
#include "session.h"
#include "task.h"
#include "wallet.h"
#include "walletmanager.h"

#include <QJsonDocument>

LoginController::LoginController(QObject* parent)
    : Controller(parent)
{
}

void LoginController::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
}

void LoginController::loginWithPin(const QString& pin)
{
    if (!m_wallet) return;
    if (pin.isEmpty()) return;

    if (!m_context) {
        setContext(new Context(m_wallet->network()->deployment(), this));
    }

    auto session = m_context->getOrCreateSession(m_wallet->network());

    auto login_task = new LoginTask(pin, m_wallet->pinData(), session);

    connect(login_task, &Task::failed, this, [=](const QString& error) {
        if (error == "id_invalid_pin") {
            m_wallet->decrementLoginAttempts();
            emit invalidPin();
        } else if (error == "id_connection_failed") {
            emit sessionError(error);
        }
        emit loginFailed();
    });

    connect(login_task, &Task::finished, this, [=] {
        m_wallet->resetLoginAttempts();
    });

    login(login_task);
}

static QJsonObject device_details_from_device(JadeDevice* device)
{
    const bool supports_host_unblinding = QVersionNumber::fromString(device->version()) >= QVersionNumber(0, 1, 27);
    return {{
        "device", QJsonObject({
            { "name", device->uuid() },
            { "supports_arbitrary_scripts", true },
            { "supports_low_r", true },
            { "supports_liquid", 1 },
            { "supports_ae_protocol", 1 },
            { "supports_host_unblinding", supports_host_unblinding }
        })
    }};
}

void LoginController::loginWithDevice()
{
    if (!m_context) {
        setContext(new Context(this));
    }

    auto jade_device = qobject_cast<JadeDevice*>(m_context->device());
    if (jade_device) {
        const auto hw_device = device_details_from_device(jade_device);
        auto session = m_context->primarySession();
        auto login_task = new LoginTask(hw_device, session);

        connect(login_task, &Task::finished, this, [=] {
            m_context->m_hw_device = hw_device;

            m_wallet = WalletManager::instance()->createWallet();
            m_wallet->setName(jade_device->name());
            m_wallet->updateDeviceDetails(jade_device->details());
            WalletManager::instance()->insertWallet(m_wallet);
        });

        login(login_task);
    }
}

void LoginController::login(LoginTask* login_task)
{
    clearErrors();

    auto group = new TaskGroup(this);
    group->setName("login");

    login(group, login_task);

    dispatcher()->add(group);

    connect(group, &TaskGroup::failed, this, &LoginController::loginFailed);
    connect(group, &TaskGroup::finished, this, [=] {
        m_context->setWallet(m_wallet);
        emit loginFinished(m_context);
        setContext(nullptr);
    });
}

void LoginController::login(TaskGroup* group, LoginTask* login_task)
{
    auto session = m_context->primarySession();
    auto connect_session = new ConnectTask(session);
    auto get_credentials = new GetCredentialsTask(session);

    connect_session->then(login_task);
    login_task->then(get_credentials);

    connect(connect_session, &Task::failed, this, [=](const QString& error) {
        if (error == "timeout error") {
            emit sessionError("id_connection_failed");
        }
    });

    group->add(connect_session);
    group->add(login_task);
    group->add(get_credentials);
}

LoadController::LoadController(QObject* parent)
    : Controller(parent)
    , m_monitor(new TaskGroupMonitor(this))
{
    connect(m_monitor, &TaskGroupMonitor::allFinishedOrFailed, this, &LoadController::loadFinished);
}

static bool compatibleToNetworks(Network* network, const QList<Network*> networks)
{
    for (auto net : networks) {
        if (net == network) return false;
        if (net->isMainnet() != network->isMainnet()) return false;
        if (net->isDevelopment() != network->isDevelopment()) return false;
    }
    return true;
}

void LoadController::load()
{
    const auto networks = m_context->getActiveNetworks();
    const auto sessions = m_context->getSessions();

    auto group = new TaskGroup(this);

    for (auto network : networks) {
        loadNetwork(group, network);
    }

    m_monitor->add(group);
    dispatcher()->add(group);

    connect(group, &TaskGroup::finished, this, [=] {
        auto wallet = m_context->wallet();
        Q_ASSERT(wallet);
        WalletManager::instance()->addWallet(wallet);
        wallet->setContext(m_context);
    });

    for (auto network : NetworkManager::instance()->networks()) {
        if (compatibleToNetworks(network, networks)) {
            qDebug() << Q_FUNC_INFO << "ATTEMPT LOGIN" << network->id() << network->name();
            loginNetwork(network);
        }
    }
}

void LoadController::loadNetwork(TaskGroup* group, Network* network)
{
    auto session = m_context->getOrCreateSession(network);
    group->add(new GetWatchOnlyDetailsTask(session));
    group->add(new LoadTwoFactorConfigTask(session));
    group->add(new LoadCurrenciesTask(session));
    if (network->isLiquid()) group->add(new LoadAssetsTask(session));
    auto load_accounts = new LoadAccountsTask(false, session);
    connect(load_accounts, &Task::finished, this, [=] {
        for (auto account : load_accounts->accounts()) {
            group->add(new LoadBalanceTask(account));
        }
    });
    group->add(load_accounts);
}

void LoadController::loginNetwork(Network* network)
{
    auto group = new TaskGroup(this);

    auto session = m_context->getOrCreateSession(network);
    auto connect_session = new ConnectTask(session);
    LoginTask* login;

    auto jade_device = qobject_cast<JadeDevice*>(m_context->device());
    if (jade_device) {
        login = new LoginTask(device_details_from_device(jade_device), session);
    } else if (m_context->credentials().contains("mnemonic")) {
        const auto mnemonic = m_context->credentials().value("mnemonic").toString().split(' ');
        login = new LoginTask(mnemonic, {}, session);
    }

    connect_session->then(login);

    connect(connect_session, &Task::failed, this, [=](const QString& error) {
        if (error == "timeout error") {
            setError("session", "id_connection_failed");
        }
    });

    connect(login, &Task::finished, this, [=] {
        qDebug() << "FINISHED LOGIN" << network->id();
        loadNetwork(group, network);
    });

    connect(login, &Task::failed, this, [=](const QString& error) {
        qDebug() << "ignoring login failed for network" << network->id() << "errr:" << error;
//        emit loginFailed();
    });

    group->add(connect_session);
    group->add(login);

    m_monitor->add(group);
    dispatcher()->add(group);
}

PinDataController::PinDataController(QObject* parent)
    : Controller(parent)
{
}

void PinDataController::update(const QString& pin)
{
    if (!m_context) return;

    Q_ASSERT(m_context->wallet());

    auto session = m_context->primarySession();
    Q_ASSERT(session);

    auto task = new EncryptWithPinTask(m_context->credentials(), pin, session);
    connect(task, &Task::finished, this, [=] {
        const auto pin_data = task->result().value("result").toObject().value("pin_data").toObject();

        m_context->wallet()->setPinData(session->network(), QJsonDocument(pin_data).toJson());

        emit finished();
    });
    dispatcher()->add(task);
}

DeviceController::DeviceController(QObject* parent)
    : Controller(parent)
{
}

void DeviceController::setDevice(Device* device)
{
    if (m_device == device) return;
    m_device = device;
    void deviceChanged();
}

void DeviceController::bind()
{
    if (!m_context) {
        auto jade_device = qobject_cast<JadeDevice*>(m_device);
        if (jade_device) {
            const auto networks = jade_device->versionInfo().value("JADE_NETWORKS").toString();
            setContext(new Context(networks == "TEST" ? "testnet" : "mainnet", this));
        }
    }
    m_context->setDevice(m_device);
    Q_ASSERT(m_context && m_context->device());
    emit binded(m_context);
}
