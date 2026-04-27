#include "account.h"
#include "address.h"
#include "appupdatecontroller.h"
#include "asset.h"
#include "context.h"
#include "device.h"
#include "green_settings.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
#include "notification.h"
#include "output.h"
#include "payment.h"
#include "session.h"
#include "sessionmanager.h"
#include "swap.h"
#include "task.h"
#include "transaction.h"
#include "wallet.h"

#include <gdk.h>

#include <algorithm>

#include <QDateTime>
#include <QDesktopServices>
#include <QFile>
#include <QFileDialog>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>
#include <QUrl>
#include <QtConcurrentRun>

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

void fetchCoins(TaskGroup* group, Account* account);
void fetchTransactions(TaskGroup* group, Account* account);
void fetchTransactions(TaskGroup* group, Account* account, int page, int size);

Context::Context(const QString& deployment, bool bip39, QObject* parent)
    : QObject(parent)
    , m_deployment(deployment)
    , m_bip39(bip39)
    , m_dispatcher(new TaskDispatcher(this))
    , m_transaction_model(new QStandardItemModel(this))
    , m_address_model(new QStandardItemModel(this))
    , m_coin_model(new QStandardItemModel(this))
    , m_payment_model(new QStandardItemModel(this))
{
    Q_ASSERT(deployment == "mainnet" || deployment == "testnet" || deployment == "development");

    m_transaction_model->setItemRoleNames({{ Qt::UserRole, "transaction" }});
    m_address_model->setItemRoleNames({{ Qt::UserRole, "address" }});
    m_coin_model->setItemRoleNames({{ Qt::UserRole, "output" }});
    m_payment_model->setItemRoleNames({{ Qt::UserRole, "payment" }});
}

Context::~Context()
{
    for (auto session : m_sessions_list) {
        SessionManager::instance()->release(session);
        session->setContext(nullptr);
        session->setActive(false);
    }
}

void Context::setSkipLoadAccounts(bool skip_load_accounts)
{
    m_skip_load_accounts = skip_load_accounts;
}

TaskGroup* Context::cleanAccounts()
{
    auto group = new TaskGroup(this);
    if (m_watchonly) return group;
    for (auto account : m_accounts) {
        if (account->pointer() > 0) {
            continue;
        }
        if (!account->name().isEmpty()) {
            continue;
        }
        if (account->session()->isTwoFactorResetActive()) {
            continue;
        }
        if (account->isSinglesig() && account->json().value("bip44_discovered").toBool()) {
            continue;
        }
        if (account->hasBalance()) {
            continue;
        }
        account->setHidden(true);
        group->add(new UpdateAccountTask({
            { "subaccount", static_cast<qint64>(account->pointer()) },
            { "hidden", true },
        }, account->session()));
    }
    return group;
}

void Context::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
    if (m_wallet) {
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
        connect(session, &Session::autoLogoutTriggered, this, [=, this] {
            if (m_wallet && !qobject_cast<DeviceData*>(m_wallet->login())) {
                emit autoLogout();
            }
        });
        connect(session, &Session::blockEvent, this, [=, this](const QJsonObject& event) {
            auto group = new TaskGroup(this);
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

                    if (account->hasUnconfirmedTransactions()) {
                        fetchTransactions(group, account);
                        fetchCoins(group, account);
                    }
                }
            }
            dispatcher()->add(group);
        });
        connect(session, &Session::subaccountEvent, this, [=, this](const QJsonObject& event) {
            uint32_t pointer = event.value("pointer").toInteger();
            auto event_type = event.value("event_type").toString();
            if (event_type == "new") {
                auto account = getOrCreateAccount(session->network(), pointer);
            } else if (event_type == "synced" && !m_skip_load_accounts) {
                auto account = getOrCreateAccount(session->network(), pointer);
                if (!account->synced()) {
                    account->setSynced(true);
                    account->loadBalance();
                }
            }
        });
        connect(session, &Session::transactionEvent, this, [=, this](const QJsonObject& event) {
            auto group = new TaskGroup(this);
            for (auto pointer : event.value("subaccounts").toArray()) {
                auto account = getOrCreateAccount(network, quint32(pointer.toInteger()));
                fetchTransactions(group, account);
                fetchCoins(group, account);
                emit account->transactionEvent(event);
                connect(group, &TaskGroup::finished, account, &Account::loadBalance);
            }
            dispatcher()->add(group);
        });
        connect(session, &Session::configChanged, this, [=, this] {
            TwoFactorResetNotification* two_factor_reset_notification = nullptr;
            for (auto notification : m_notifications) {
                two_factor_reset_notification = qobject_cast<TwoFactorResetNotification*>(notification);
                if (two_factor_reset_notification) {
                    if (two_factor_reset_notification->network() == session->network()) {
                        break;
                    } else {
                        two_factor_reset_notification = nullptr;
                    }
                }
            }
            if (session->isTwoFactorResetActive()) {
                if (!two_factor_reset_notification) {
                    addNotification(new TwoFactorResetNotification(session->network(), this));
                }
            } else {
                if (two_factor_reset_notification) {
                    removeNotification(two_factor_reset_notification);
                }
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
        QObject::connect(m_device, &QObject::destroyed, this, [=, this] {
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
        account = new Account(network, pointer, this);
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

ChainTransaction* Context::getOrCreateChainTransaction(const QString &hash)
{
    auto chain_transaction = m_chain_transactions.value(hash);
    if (!chain_transaction) {
        chain_transaction = new ChainTransaction(hash, this);
        m_chain_transactions.insert(hash, chain_transaction);
    }
    return chain_transaction;
}

QList<ContextTransaction*> Context::getTransaction(const QString &hash) const
{
    return m_transaction_map.values(hash);
}

Payment* Context::getOrCreatePayment(const QString &id)
{
    auto payment = m_payments.value(id);
    if (!payment) {
        payment = new Payment(this);
        m_payments.insert(id, payment);
        auto item = new QStandardItem;
        item->setData(QVariant::fromValue(payment), Qt::UserRole);
        item->setData(payment->updatedAt(), Qt::UserRole + 1);

        connect(payment, &Payment::updatedAtChanged, this, [=, this] {
            item->setData(payment->updatedAt(), Qt::UserRole + 1);
        });

        m_payment_item.insert(payment, item);
        m_payment_model->appendRow(item);
    }
    return payment;
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
    connect(notification, &Notification::triggered, this, [=, this] {
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

void fetchTransactions(TaskGroup* group, Account* account)
{
    account->beginFetchTransactions();
    fetchTransactions(group, account, 0, 30);
}

void fetchTransactions(TaskGroup* group, Account* account, int page, int size)
{
    auto task = new GetTransactionsTask(page * size, size, account);

    QObject::connect(task, &Task::finished, account, [=] {
        task->deleteLater();

        for (const QJsonValue& value : task->transactions()) {
            auto transaction = account->getOrCreateTransaction(value.toObject());
            account->touchTransaction(transaction->hash());
        }

        if (task->transactions().size() == size) {
            fetchTransactions(group, account, page + 1, size);
        } else {
            account->endFetchTransactions();
        }
    });

    group->add(task);
}

void fetchCoins(TaskGroup* group, Account* account)
{
    auto task = new GetUnspentOutputsTask(0, true, account);

    QObject::connect(task, &Task::finished, account, [=] {
        for (const QJsonValue& assets_values : task->unspentOutputs()) {
            for (const QJsonValue& asset_value : assets_values.toArray()) {
                auto output = account->getOrCreateOutput(asset_value.toObject());
            }
        }
    });

    group->add(task);
}

void Context::addTestNotification(const QString& message)
{
    auto network = primaryNetwork();
    if (!network) {
        qDebug() << "No primary network available for test notification";
        return;
    }

    auto notification = new SystemNotification(message, network, this);
    addNotification(notification);
    qDebug() << "Test notification added:" << message;
}

void Context::addTestSystemNotification(const QString& message)
{
    addTestNotification(message);
}

void Context::addTestOutageNotification()
{
    auto network = primaryNetwork();
    if (!network) return;
    auto outage = new OutageNotification(this);
    outage->add(network);
    addNotification(outage);
}

void Context::addTestTwoFactorResetNotification()
{
    auto network = primaryNetwork();
    if (!network) return;
    auto reset = new TwoFactorResetNotification(network, this);
    addNotification(reset);
}

void Context::addTestTwoFactorExpiredNotification()
{
    auto expired = new TwoFactorExpiredNotification(this);
    addNotification(expired);
}

void Context::addTestWarningNotification()
{
    auto notification = new BackupNotification(this);
    addNotification(notification);
}

void Context::addTestUpdateNotification()
{
    auto update = new UpdateNotification("2.0.0", this);
    addNotification(update);
}

void Context::checkAndAddBackupWarningNotification()
{
    if (!m_wallet || !qobject_cast<PinData*>(m_wallet->login())) {
        return;
    }
    
    auto settings = Settings::instance();
    const auto event = QJsonObject{
        { "walletId", m_xpub_hash_id },
        { "status", "pending" },
        { "type", "wallet_backup" }
    };
    const bool event_registered = settings->isEventRegistered(event);
    
    BackupNotification* backup_notification{nullptr};
    for (auto notification : m_notifications) {
        backup_notification = qobject_cast<BackupNotification*>(notification);
        if (backup_notification) break;
    }

    if (event_registered && !backup_notification) {
        addNotification(new BackupNotification(this));
    }

    if (!event_registered && backup_notification) {
        removeNotification(backup_notification);
    }
}

void Context::loadNetwork(TaskGroup *group, Network *network)
{
    auto session = getOrCreateSession(network);
    if (!session->m_ready) {
        Q_UNREACHABLE();
        return;
    }
    if (isWatchonly() && session->network()->isLiquid()) {
        group->add(new LoadAssetsTask(false, session));
    }
    group->add(new GetWatchOnlyDetailsTask(session));
    group->add(new LoadTwoFactorConfigTask(session));
    group->add(new LoadCurrenciesTask(session));

    if (m_skip_load_accounts) {
        createStandardAccount(group, network);
        return;
    }

    auto load_accounts = new LoadAccountsTask(false, session);
    auto sync_accounts = new SyncAccountsTask(session);
    auto load_accounts2 = new LoadAccountsTask(false, session);
    load_accounts->then(sync_accounts);
    sync_accounts->then(load_accounts2);
    group->add(load_accounts);
    group->add(sync_accounts);
    group->add(load_accounts2);

    connect(load_accounts2, &Task::finished, this, [=, this] {
        if (network->isElectrum()) {
            bool has_native_segwit = false;

            for (auto account : load_accounts2->accounts()) {
                if (account->type() == "p2wpkh") {
                    has_native_segwit = true;
                    break;
                }
            }

            if (!has_native_segwit) {
                createStandardAccount(group, network);
            }
        }

        loadNetwork2(group, network);
    });
    connect(load_accounts2, &Task::failed, this, [=, this](auto error) {
        // TODO: deal with these errors
        qDebug() << Q_FUNC_INFO << error;
    });
}

void Context::createStandardAccount(TaskGroup *group, Network *network)
{
    if (isWatchonly()) return;

    auto session = getOrCreateSession(network);
    if (!session->m_ready) {
        Q_UNREACHABLE();
        return;
    }

    const QString name = network->isLiquid() ? "Standard Liquid" : "Standard";
    auto details = QJsonObject{
        { "name", name },
        { "type", "p2wpkh" },
    };

    auto create_account = new CreateAccountTask(details, session);

    connect(create_account, &Task::finished, this, [=, this] {
        auto account = getAccountByPointer(network, create_account->pointer());
        auto load_account_task = new LoadAccountTask(create_account->pointer(), session);
        auto load_balance_task = new LoadBalanceTask(account);

        load_account_task->then(load_balance_task);

        group->add(load_account_task);
        group->add(load_balance_task);
    });

    group->add(create_account);
}

void Context::loadNetwork2(TaskGroup *group, Network *network)
{
    auto session = getOrCreateSession(network);
    if (!session->m_ready) {
        Q_UNREACHABLE();
        return;
    }

    auto load_accounts = new LoadAccountsTask(false, session);
    connect(load_accounts, &Task::finished, this, [=, this] {
        for (auto account : load_accounts->accounts()) {
            group->add(new LoadBalanceTask(account));
            fetchCoins(group, account);
            fetchTransactions(group, account);
        }
    });
    group->add(load_accounts);
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

    connect(connect_session, &Task::failed, this, [=, this](const QString& error) {
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

    const auto pricing = primarySession()->settings().value("pricing");
    if (pricing.isObject()) {
        auto sync_settings = new ChangeSettingsTask(QJsonObject{{ "pricing", pricing }}, session);
        login->then(sync_settings);
        group->add(sync_settings);
    }

    connect(login, &Task::finished, this, [=, this] {
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

    connect(login, &Task::failed, this, [=, this](const QString& error) {
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
        auto load_accounts = new LoadAccountsTask(!isWatchonly(), session);
        connect(load_accounts, &Task::finished, this, [=, this] {
            for (auto account : load_accounts->accounts()) {
                group->add(new LoadBalanceTask(account));
            }
        });
        group->add(load_accounts);
    }
    m_dispatcher->add(group);
    connect(group, &TaskGroup::finished, group, &QObject::deleteLater);
}

void Context::addTransaction(ContextTransaction* transaction)
{
    auto item = m_transaction_item.value(transaction);

    if (!item) {
        m_transaction_map.insert(transaction->id(), transaction);

        item = new QStandardItem;
        item->setData(QVariant::fromValue(transaction), Qt::UserRole);
        m_transaction_item.insert(transaction, item);
        m_transaction_model->appendRow(item);
    }

    item->setData(QVariant::fromValue(transaction->timestamp()), Qt::UserRole + 1);
}

void Context::removeTransaction(ContextTransaction* transaction)
{
    auto item = m_transaction_item.take(transaction);

    if (item) {
        m_transaction_model->removeRow(item->row());
    }
}

Address* Context::getOrCreateAddress(const QString& value)
{
    Address* address = m_address_map.value(value);
    if (address) return address;

    address = new Address(this, value);
    m_address_map.insert(value, address);

    auto item = new QStandardItem;
    item->setData(QVariant::fromValue(address), Qt::UserRole);
    item->setData(value, Qt::UserRole + 1);
    m_address_item.insert(address, item);
    m_address_model->appendRow(item);

    return address;
}

void Context::addCoin(Output* coin)
{
    auto item = m_coin_item.value(coin);

    if (!item) {
        item = new QStandardItem;
        item->setData(QVariant::fromValue(coin), Qt::UserRole);
        m_coin_item.insert(coin, item);
        m_coin_model->appendRow(item);
    }

    auto block_height = coin->data().value("block_height").toInt();
    item->setData(block_height > 0 ? block_height : INT_MAX, Qt::UserRole + 1);
}

QQmlListProperty<Account> Context::accounts()
{
    return { this, &m_accounts };
}

QQmlListProperty<Session> Context::sessions()
{
    return { this, &m_sessions_list };
}

static ContextManager* g_context_manager{nullptr};

ContextManager::ContextManager()
    : QObject(nullptr)
{
    Q_ASSERT(!g_context_manager);
    g_context_manager = this;
}

ContextManager::~ContextManager()
{
    qDebug() << Q_FUNC_INFO << "contexts to destroy:" << m_contexts.length();
    m_contexts.clear();
    g_context_manager = nullptr;
}

ContextManager *ContextManager::instance()
{
    Q_ASSERT(g_context_manager);
    return g_context_manager;
}

Context* ContextManager::create(const QString& deployment, bool bip39)
{
    auto context = new Context(deployment, bip39, this);
    connect(context, &QObject::destroyed, this, [=, this] {
        m_contexts.removeOne(context);
    });
    m_contexts.append(context);
    return context;
}

ContextTransaction::ContextTransaction(const QString& id, Context* context)
    : QObject(context)
    , m_context(context)
    , m_id(id)
{
}

QDateTime ContextTransaction::timestamp() const
{
    return QDateTime::currentDateTime();
}

void Context::addSwap(Swap* swap)
{
    m_swaps.append(swap);
    swap->sync();
    // TODO addTransaction(swap);
}

void Context::removeSwap(Swap* swap)
{
    Q_ASSERT(m_boltz_session);
    m_swaps.removeOne(swap);
    m_boltz_session->remove_swap(swap->id().toStdString());
}
