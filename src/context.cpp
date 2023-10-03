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
                if (account->session() == session) {
                    // FIXME: Until gdk notifies of chain reorgs, resync balance every
                    // 10 blocks in case a reorged tx is somehow evicted from the mempool
                    const auto block = event.value("block").toObject();
                    uint32_t block_height = block.value("block_height").toDouble();
                    if (!network->isLiquid() || (block_height % 10) == 0) {
                        account->loadBalance();
                    }
                    emit account->blockEvent(event);
                }
            }
        });
        connect(session, &Session::subaccountEvent, this, [=](const QJsonObject& event) {
            auto pointer = event.value("pointer").toInteger();
            auto event_type = event.value("event_type").toString();
            if (event_type == "synced") {
                auto account = getOrCreateAccount(session->network(), pointer);
                account->setSynced(true);
                m_dispatcher->add(new LoadBalanceTask(account));
            }
        });
        connect(session, &Session::twoFactorResetEvent, this, [=](const QJsonObject& event) {
            setLocked(event.value("is_active").toBool());
        });
        connect(session, &Session::transactionEvent, this, [=](const QJsonObject& transaction) {
            for (auto pointer : transaction.value("subaccounts").toArray()) {
                auto account = m_accounts_by_pointer.value({ network, pointer.toInt() });
                if (account) {
                    account->loadBalance();
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

Asset* Context::getOrCreateAsset(const QString& id)
{
    return AssetManager::instance()->assetWithId(id);
}

Account* Context::getOrCreateAccount(Network* network, int pointer)
{
    Account* account = m_accounts_by_pointer.value({ network, pointer });
    if (!account) {
        auto session = getOrCreateSession(network);
        account = new Account(pointer, session);
        m_accounts_by_pointer.insert({ network, pointer }, account);
        m_accounts.append(account);
        emit accountsChanged();
    }
    return account;
}

Account* Context::getOrCreateAccount(Network* network, const QJsonObject& data)
{
    Q_ASSERT(data.contains("pointer"));
    const int pointer = data.value("pointer").toInt();
    auto account = getOrCreateAccount(network, pointer);
    account->update(data);
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

void Context::refresh()
{
//    TODO: refresh should not be necessary after correct load controller implementation
//    auto session = getOrCreateSession(m_wallet->network());
//    auto load_accounts = new LoadAccountsTask(true, session);
//    connect(load_accounts, &Task::finished, this, [=] {
//        for (auto account : m_accounts) {
//            m_dispatcher->add(new LoadBalanceTask(account));
//        }
//    });
//    m_dispatcher->add(load_accounts);
}

void Context::setXPubHashId(const QString& xpub_hash_id)
{
    if (m_xpub_hash_id == xpub_hash_id) return;
    Q_ASSERT(m_xpub_hash_id.isEmpty());
    m_xpub_hash_id = xpub_hash_id;
    if (m_wallet) {
        m_wallet->m_xpub_hash_id = xpub_hash_id;
    }
}

QQmlListProperty<Account> Context::accounts()
{
    return { this, &m_accounts };
}

QQmlListProperty<Session> Context::sessions()
{
    return { this, &m_sessions_list };
}
