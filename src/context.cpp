#include "account.h"
#include "asset.h"
#include "context.h"
#include "device.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
#include "notification.h"
#include "session.h"
#include "sessionmanager.h"
#include "task.h"
#include "wallet.h"

#include <gdk.h>

#include <algorithm>

namespace {
void UpdateAsset(GA_session* session, Asset* asset)
{
    const auto id = asset->id();

    auto params = Json::fromObject({{ "assets_id", QJsonArray{id} }});
    GA_json* output;

    const auto err = GA_get_assets(session, params.get(), &output);
    Q_ASSERT(err == GA_OK);

    const auto result = Json::toObject(output);
    const auto data = result.value("assets").toObject().value(id);
    if (!data.isNull()) {
      asset->setData(data.toObject());
    }
    const auto icon = result.value("icons").toObject().value(id);
    if (!icon.isNull()) {
        asset->setIcon(QString("data:image/png;base64,") + icon.toString());
    }
    GA_destroy_json(output);
}
}

Context::Context(const QString& deployment, bool bip39, QObject* parent)
    : QObject(parent)
    , m_deployment(deployment)
    , m_bip39(bip39)
    , m_dispatcher(new TaskDispatcher(this))
{
    Q_ASSERT(deployment == "mainnet" || deployment == "testnet" || deployment == "development");
}

Context::~Context()
{
    for (auto session : m_sessions_list) {
        SessionManager::instance()->release(session);
        session->setContext(nullptr);
    }
}

TaskGroup* Context::cleanAccounts()
{
    auto group = new TaskGroup(this);
    if (m_watchonly) return group;
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
        if (!m_bip39 && !m_xpub_hash_id.isEmpty()) {
            m_wallet->setXPubHashId(m_xpub_hash_id);
        }
        if (m_device) {
            // m_wallet->updateDeviceDetails(m_device->details());
        }
    }
}

Session* Context::getOrCreateSession(Network* network)
{
    if (!network) return nullptr;

    auto session = m_sessions.value(network);
    if (!session) {
        session = SessionManager::instance()->create(network);
        session->setContext(this);
        session->setActive(true);
        connect(session, &Session::autoLogoutTriggered, this, [=] {
            if (m_wallet && !qobject_cast<DeviceData*>(m_wallet->login())) {
                emit autoLogout();
            }
        });
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
            if (event.value("is_active").toBool()) {
                auto notification = new TwoFactorResetNotification(session->network(), this);
                addNotification(notification);
            }
        });
        connect(session, &Session::transactionEvent, this, [=](const QJsonObject& transaction) {
            for (auto pointer : transaction.value("subaccounts").toArray()) {
                auto account = getOrCreateAccount(network, quint32(pointer.toInteger()));
                account->getOrCreateTransaction(transaction);
                emit account->transactionEvent(transaction);
                account->loadBalance();
            }
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
        auto network = primaryNetwork();
        auto session = getOrCreateSession(network);
        return session;
    }
}

void Context::releaseSession(Session* session)
{
    qDebug() << Q_FUNC_INFO << session->network()->id();

    for (auto account : m_accounts) {
        if (account->session() == session) {
            qWarning() << Q_FUNC_INFO << "should remove account" << account->network()->id() << account->pointer();
        }
    }
    m_sessions.take(session->network());
    m_sessions_list.removeOne(session);
    emit sessionsChanged();

    SessionManager::instance()->release(session);
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
            auto device_data = qobject_cast<DeviceData*>(m_wallet->login());
            if (device_data) {
                device_data->setDevice(m_device->details());
                m_wallet->save();
            }
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

void Context::setWatchonly(bool watchonly)
{
    if (m_watchonly == watchonly) return;
    m_watchonly = watchonly;
    emit watchonlyChanged();
}

QList<Network*> Context::getActiveNetworks() const
{
    QList<Network*> networks;
    for (auto session : m_sessions_list) {
        if (session->isConnected() && session->m_ready) {
            networks.append(session->network());
        }
    }
    return networks;
}

Asset* Context::getOrCreateAsset(const QString& id)
{
    return AssetManager::instance()->assetWithId(m_deployment, id);
}

Account* Context::getOrCreateAccount(Network* network, quint32 pointer)
{
    qDebug() << Q_FUNC_INFO << network->id() << pointer;
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
    qDebug() << Q_FUNC_INFO << network->id() << data;
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
    if (!m_bip39 && m_wallet) {
        m_wallet->setXPubHashId(xpub_hash_id);
    }
    emit xpubHashIdChanged();
}

QQmlListProperty<Notification> Context::notifications()
{
    return { this, &m_notifications };
}

void Context::addNotification(Notification* notification)
{
    m_notifications.append(notification);
    emit notificationsChanged();
    emit notificationAdded(notification);
    connect(notification, &Notification::triggered, this, [=] {
        emit notificationTriggered(notification);
    });
}

void Context::removeNotification(Notification* notification)
{
    emit notificationRemoved(notification);
    m_notifications.removeOne(notification);
    emit notificationsChanged();
}

Network *Context::primaryNetwork()
{
    for (auto network : NetworkManager::instance()->networkForDeployment(m_deployment)) {
        if (m_device) {
            if (m_device->supportsNetwork(network)) return network;
        } else {
            return network;
        }
    }
    return nullptr;
}

QString Context::getDisplayUnit(const QString& unit)
{
    return ComputeDisplayUnit(primarySession()->network(), unit);
}

void Context::loadNetwork(TaskGroup *group, Network *network)
{
    auto session = getOrCreateSession(network);
    if (!session->m_ready) return;
    if (isWatchonly() && session->network()->isLiquid()) {
        group->add(new LoadAssetsTask(false, session));
    }
    group->add(new GetWatchOnlyDetailsTask(session));
    group->add(new LoadTwoFactorConfigTask(session));
    group->add(new LoadCurrenciesTask(session));
    if (!isWatchonly() || !network->isElectrum()) {
        auto load_accounts = new LoadAccountsTask(false, session);
        connect(load_accounts, &Task::finished, this, [=] {
            for (auto account : load_accounts->accounts()) {
                group->add(new LoadBalanceTask(account));

                auto get_unspent_outputs = new GetUnspentOutputsTask(0, true, account);

                connect(get_unspent_outputs, &Task::finished, this, [=] {
                    for (const QJsonValue& assets_values : get_unspent_outputs->unspentOutputs()) {
                        for (const QJsonValue& asset_value : assets_values.toArray()) {
                            auto output = account->getOrCreateOutput(asset_value.toObject());
                        }
                    }
                });

                group->add(get_unspent_outputs);
            }
        });
        connect(load_accounts, &Task::failed, this, [=](auto error) {
            // TODO: deal with these errors
            qDebug() << Q_FUNC_INFO << error;
        });
        group->add(load_accounts);
    }
}

QJsonObject device_details_from_device(Device* device);

void Context::loginNetwork(TaskGroup *group, Network *network)
{
    auto session = getOrCreateSession(network);
    auto connect_session = new ConnectTask(10000, session);
    LoginTask* login{nullptr};

    if (m_device) {
        login = new LoginTask(device_details_from_device(m_device), session);
    } else if (m_credentials.contains("mnemonic")) {
        login = new LoginTask(m_credentials, {}, session);
    }

    if (network->isLiquid() && !m_assets_loaded) {
        m_assets_loaded = true;
        auto load_assets = new LoadAssetsTask(false, session);
        connect_session->then(load_assets);
        load_assets->then(login);
        group->add(load_assets);
    }

    connect(connect_session, &Task::failed, this, [=](const QString& error) {
        if (error == "timeout error") {
            // TODO
            // setError("session", "id_connection_failed");
            releaseSession(session);
            if (!m_outage_notification) {
                m_outage_notification = new OutageNotification(this);
                addNotification(m_outage_notification);
            }
            m_outage_notification->add(network);
        }
    });

    connect(login, &Task::finished, this, [=] {
        if (m_outage_notification) {
            m_outage_notification->remove(network);
            if (m_outage_notification->isEmpty()) {
                removeNotification(m_outage_notification);
                // TODO m_outage_notification->deleteLater();
                m_outage_notification = nullptr;
            }
        }
        loadNetwork(group, network);
    });

    connect(login, &Task::failed, this, [=](const QString& error) {
        qDebug() << "ignoring login failed for network" << network->id() << "errr:" << error;
        releaseSession(session);
    });

    group->add(connect_session);
    group->add(login);
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
