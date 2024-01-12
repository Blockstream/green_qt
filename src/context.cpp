#include "account.h"
#include "asset.h"
#include "context.h"
#include "device.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
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
    : Context({}, parent)
{
}

Context::Context(const QString& deployment, QObject* parent)
    : QObject(parent)
    , m_deployment(deployment)
    , m_dispatcher(new TaskDispatcher(this))
{
    Q_ASSERT(deployment == "mainnet" || deployment == "testnet" || deployment == "development");
}

TaskGroup* Context::cleanAccounts()
{
    auto group = new TaskGroup(this);
    for (auto account : m_accounts) {
        if (account->pointer() == 0 && account->name().isEmpty()) {
            bool hide = true;
            if (account->isSinglesig()) {
                if (account->json().value("bip44_discovered").toBool()) {
                    hide = false;
                }
            }
            const auto satoshi = account->json().value("satoshi").toObject();
            for (auto key : satoshi.keys()) {
                if (satoshi.value(key).toInteger() > 0) {
                    hide = false;
                    break;
                }
            }
            if (hide) {
                auto task = new UpdateAccountTask({
                    { "subaccount", static_cast<qint64>(account->pointer()) },
                    { "hidden", true },
                }, account->session());
                account->setHidden(true);
                group->add(task);
            }
        }
    }
    return group;
}

void Context::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
    if (m_wallet) {
        setParent(m_wallet);
        if (!m_xpub_hash_id.isEmpty()) {
            m_wallet->setXPubHashId(m_xpub_hash_id);
        }
        if (m_device) {
            m_wallet->updateDeviceDetails(m_device->details());
        }
    }
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
                    uint32_t block_height = block.value("block_height").toInteger();
                    if (!network->isLiquid() || (block_height % 10) == 0) {
                        account->loadBalance();
                    }
                    emit account->blockEvent(event);
                }
            }
        });
        connect(session, &Session::subaccountEvent, this, [=](const QJsonObject& event) {
            uint32_t pointer = event.value("pointer").toInteger();
            auto event_type = event.value("event_type").toString();
            if (event_type == "new") {
                auto account = getOrCreateAccount(session->network(), pointer);
            } else if (event_type == "synced") {
                auto account = getOrCreateAccount(session->network(), pointer);
                if (!account->synced()) {
                    account->setSynced(true);
                    account->loadBalance();
                }
            }
        });
        connect(session, &Session::twoFactorResetEvent, this, [=](const QJsonObject& event) {
            setLocked(event.value("is_active").toBool());
        });
        connect(session, &Session::transactionEvent, this, [=](const QJsonObject& transaction) {
            for (auto pointer : transaction.value("subaccounts").toArray()) {
                auto account = getOrCreateAccount(network, quint32(pointer.toInteger()));
                account->getOrCreateTransaction(transaction);
                emit account->transactionEvent(transaction);
            }
            emit hasBalanceChanged();
        });
        m_sessions.insert(network, session);
        m_sessions_list.append(session);
        emit sessionsChanged();
    }
    return session;
}

Session* Context::primarySession()
{
    if (m_sessions_list.size() > 0) {
        return m_sessions_list.first();
    } else {
        auto network = NetworkManager::instance()->networkForDeployment(m_deployment);
        auto session = getOrCreateSession(network);
        return session;
    }
}

void Context::releaseSession(Session* session)
{
    qDebug() << Q_FUNC_INFO << session->network()->id();
    for (auto account : m_accounts) {
        Q_ASSERT(account->session() != session);
    }
    m_sessions.take(session->network());
    m_sessions_list.removeOne(session);
    emit sessionsChanged();
    session->deleteLater();
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

void Context::setRemember(bool remember)
{
    if (m_remember == remember) return;
    m_remember = remember;
    emit rememberChanged();
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
    Q_ASSERT(m_mnemonic.isEmpty());
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
    return AssetManager::instance()->assetWithId(m_deployment, id);
}

Account* Context::getOrCreateAccount(Network* network, quint32 pointer)
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
    const quint32 pointer = data.value("pointer").toInteger();
    auto account = getOrCreateAccount(network, pointer);
    account->update(data);
    return account;
}

Account* Context::getAccountByPointer(Network* network, int pointer) const
{
    return m_accounts_by_pointer.value({ network, pointer });
}

void Context::setXPubHashId(const QString& xpub_hash_id)
{
    if (m_xpub_hash_id == xpub_hash_id) return;
    Q_ASSERT(m_xpub_hash_id.isEmpty());
    m_xpub_hash_id = xpub_hash_id;
    if (m_wallet) {
        m_wallet->setXPubHashId(xpub_hash_id);
    }
}

bool Context::attachToWallet(Wallet* wallet)
{
    Q_ASSERT(!m_xpub_hash_id.isEmpty());
    Q_ASSERT(wallet);
    Q_ASSERT(!wallet->m_xpub_hash_id.isEmpty());

    if (m_xpub_hash_id != wallet->m_xpub_hash_id) {
        return false;
    }
    setWallet(wallet);
    return true;
}

void Context::refreshAccounts()
{
    auto group = new TaskGroup(this);
    group->setName("id_loading_accounts");
    for (auto session : m_sessions_list) {
        auto load_accounts = new LoadAccountsTask(true, session);
        connect(load_accounts, &Task::finished, this, [=] {
            for (auto account : load_accounts->accounts()) {
                group->add(new LoadBalanceTask(account));
            }
        });
        group->add(load_accounts);
    }
    m_dispatcher->add(group);
    connect(group, &TaskGroup::finished, group, &QObject::deleteLater);
}

QQmlListProperty<Account> Context::accounts()
{
    return { this, &m_accounts };
}

QQmlListProperty<Session> Context::sessions()
{
    return { this, &m_sessions_list };
}
