#include "account.h"
#include "asset.h"
#include "context.h"
#include "device.h"
#include "json.h"
#include "network.h"
#include "session.h"
#include "task.h"
#include "wallet.h"

#include <gdk.h>
#include <nlohmann/json.hpp>

namespace {
void UpdateAsset(GA_session* session, Asset* asset)
{
    const auto id = asset->id().toStdString();

    const nlohmann::json params = {{ "assets_id", { id } }};
    nlohmann::json* output;

    const auto err = GA_get_assets(session, (const GA_json*) &params, (GA_json**) &output);
    Q_ASSERT(err == GA_OK);

    if (output->at("assets").contains(id)) {
        const auto data = output->at("assets").at(id);
        asset->setData(Json::toObject((GA_json*) &data));
    }
    if (output->at("icons").contains(id)) {
        const auto icon = output->at("icons").at(id).get<std::string>();
        asset->setIcon(QString("data:image/png;base64,") + QString::fromStdString(icon));
    }
    GA_destroy_json((GA_json*) output);
}
}


Context::Context(QObject* parent)
    : QObject(parent)
    , m_dispatcher(new TaskDispatcher(this))
{
}

void Context::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
}

Session* Context::getOrCreateSession(Network* network)
{
    if (!network) return nullptr;

    auto session = m_sessions.value(network);
    if (!session) {
        session = new Session(network, this);
        session->setActive(true);
        connect(session, &Session::blockEvent, this, [=](const QJsonObject& event) {
            for (auto account : m_accounts) {
                emit account->blockEvent(event);
            }
        });
        connect(session, &Session::twoFactorResetEvent, this, [=](const QJsonObject& event) {
            setLocked(event.value("is_active").toBool());
        });
        connect(session, &Session::transactionEvent, this, [=](const QJsonObject& transaction) {
            for (auto pointer : transaction.value("subaccounts").toArray()) {
                auto account = m_accounts_by_pointer.value({ network, pointer.toInt() });
                if (account) {
                    emit account->transactionEvent(transaction);
                }
            }
            emit hasBalanceChanged();
        });
        m_sessions.insert(network, session);
        m_sessions_list.append(session);
        emit sessionsChanged();
    }
    return session;
//    if (!m_network && m_session) {
//        delete m_session;
//        m_session = nullptr;
//        emit sessionChanged();
//    }
}

void Context::setDevice(Device* device)
{
    if (m_device == device) return;
    m_device = device;
    if (m_device) {
        QObject::connect(m_device, &QObject::destroyed, this, [=] {
            setDevice(nullptr);
        });

        if (m_wallet) {
            m_wallet->updateDeviceDetails(m_device->details());
        }
    }
    emit deviceChanged();
}

void Context::setCredentials(const QJsonObject &credentials)
{
    if (m_credentials == credentials) return;
    m_credentials = credentials;
    emit credentialsChanged();
    setMnemonic(credentials.value("mnemonic").toString().split(" "));
}

void Context::setMnemonic(const QStringList& mnemonic)
{
    if (m_mnemonic == mnemonic) return;
    m_mnemonic = mnemonic;
    emit mnemonicChanged();
}

void Context::setLocked(bool locked)
{
    if (m_locked == locked) return;
    m_locked = locked;
    emit lockedChanged();
}

void Context::setUsername(const QString& username)
{
    if (m_username == username) return;
    m_username = username;
    emit usernameChanged();
}

void Context::setWatchonly(bool watchonly)
{
    if (m_watchonly == watchonly) return;
    m_watchonly = watchonly;
    emit watchonlyChanged();
}

bool Context::hasBalance() const
{
    for (const auto& account : m_accounts) {
        if (account->hasBalance()) return true;
    }
    return false;
}

Asset* Context::getOrCreateAsset(Network* network, const QString& id)
{
    Q_ASSERT(network && network->isLiquid());
    Q_ASSERT(id != "btc");

    const auto session = getOrCreateSession(network);
    if (!session) return nullptr;

    Asset* asset = m_assets.value({ network, id });
    if (!asset) {
        asset = new Asset(id, network, this);
        m_assets.insert({ network, id }, asset);
        UpdateAsset(session->m_session, asset);
    }
    return asset;
}

Account* Context::getOrCreateAccount(Network* network, const QJsonObject& data)
{
    Q_ASSERT(data.contains("pointer"));
    const int pointer = data.value("pointer").toInt();
    Account* account = m_accounts_by_pointer.value({ network, pointer });
    if (account) {
        account->update(data);
    } else {
        auto session = getOrCreateSession(network);
        account = new Account(data, session);
        m_accounts_by_pointer.insert({ network, pointer }, account);
        m_accounts.append(account);
        emit accountsChanged();
    }
    return account;
}

Account* Context::getAccountByPointer(Network* network, int pointer) const
{
    return m_accounts_by_pointer.value({ network, pointer });
}

void Context::autoLogout()
{
    // avoid autologout in the following cases
    if (!m_wallet || m_device || m_accounts.empty()) return;

    m_wallet->setContext(nullptr);
    QTimer::singleShot(5000, this, &QObject::deleteLater);
    connect(qApp, &QCoreApplication::aboutToQuit, this, &QObject::deleteLater);
}

void Context::refreshAccounts()
{
    auto session = getOrCreateSession(m_wallet->network());
    m_dispatcher->add(new LoadAccountsTask(true, session));
}

QQmlListProperty<Account> Context::accounts()
{
    return { this, &m_accounts };
}

QQmlListProperty<Session> Context::sessions()
{
    return { this, &m_sessions_list };
}
