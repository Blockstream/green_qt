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
                        fetchTransactions(group, account, 0, 30);
                        fetchCoins(group, account);
                    }
                }
            }
            dispatcher()->add(group);
        });
        connect(session, &Session::subaccountEvent, this, [=](const QJsonObject& event) {
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
        connect(session, &Session::twoFactorResetEvent, this, [=](const QJsonObject& event) {
            if (event.value("is_active").toBool()) {
                auto notification = new TwoFactorResetNotification(session->network(), this);
                addNotification(notification);
            }
        });
        connect(session, &Session::transactionEvent, this, [=](const QJsonObject& event) {
            auto group = new TaskGroup(this);
            for (auto pointer : event.value("subaccounts").toArray()) {
                auto account = getOrCreateAccount(network, quint32(pointer.toInteger()));
                fetchTransactions(group, account, 0, 30);
                fetchCoins(group, account);
                emit account->transactionEvent(event);
                connect(group, &TaskGroup::finished, account, &Account::loadBalance);
            }
            dispatcher()->add(group);
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

QList<Transaction *> Context::getTransaction(const QString &hash) const
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

        connect(payment, &Payment::dataChanged, this, &Context::paymentUpdated);
        connect(payment, &Payment::addressChanged, this, &Context::paymentUpdated);
        connect(payment, &Payment::transactionChanged, this, &Context::paymentUpdated);

        connect(payment, &Payment::updatedAtChanged, this, [=] {
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

void fetchTransactions(TaskGroup* group, Account* account, int page, int size)
{
    auto task = new GetTransactionsTask(page * size, size, account);

    QObject::connect(task, &Task::finished, account, [=] {
        task->deleteLater();

        for (const QJsonValue& value : task->transactions()) {
            account->getOrCreateTransaction(value.toObject());
        }

        if (task->transactions().size() == size) {
            fetchTransactions(group, account, page + 1, size);
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

    qDebug() << Q_FUNC_INFO << network->id() << network->isElectrum() << isWatchonly();

    // if (network->isElectrum()) {
    auto load_accounts = new LoadAccountsTask((network->isElectrum() && isWatchonly()) ? false : true, session);
        auto sync_accounts = new SyncAccountsTask(session);
        auto load_accounts2 = new LoadAccountsTask(false, session);
        load_accounts->then(sync_accounts);
        sync_accounts->then(load_accounts2);
        group->add(load_accounts);
        group->add(sync_accounts);
        group->add(load_accounts2);
    // }

    // qDebug() << isWatchonly() << network->isElectrum();
    // if (true) { // !isWatchonly() || !network->isElectrum()) {
        // auto load_accounts = new LoadAccountsTask(false, session);
        connect(load_accounts2, &Task::finished, this, [=] {
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
        connect(load_accounts2, &Task::failed, this, [=](auto error) {
            // TODO: deal with these errors
            qDebug() << Q_FUNC_INFO << error;
        });
        // group->add(load_accounts);
}

void Context::createStandardAccount(TaskGroup *group, Network *network)
{
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

    connect(create_account, &Task::finished, this, [=] {
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
    connect(load_accounts, &Task::finished, this, [=] {
        for (auto account : load_accounts->accounts()) {
            group->add(new LoadBalanceTask(account));
            fetchCoins(group, account);
            fetchTransactions(group, account, 0, 30);
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
        auto load_accounts = new LoadAccountsTask(!isWatchonly(), session);
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

void Context::addTransaction(Transaction* transaction)
{
    auto item = m_transaction_item.value(transaction);

    if (!item) {
        m_transaction_map.insert(transaction->hash(), transaction);

        item = new QStandardItem;
        item->setData(QVariant::fromValue(transaction), Qt::UserRole);
        m_transaction_item.insert(transaction, item);
        m_transaction_model->appendRow(item);
    }

    const auto created_at_ts = transaction->data().value("created_at_ts");
    const auto timestamp = created_at_ts.isNull() ? QDateTime::currentDateTime() : QDateTime::fromMSecsSinceEpoch(created_at_ts.toInteger() / 1000);

    item->setData(QVariant::fromValue(timestamp), Qt::UserRole + 1);
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

ContextModel::ContextModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    sort(0, Qt::DescendingOrder);
}

void ContextModel::setContext(Context* context)
{
    if (m_context == context) return;
    if (m_context) {
        setSourceModel(nullptr);
    }
    m_context = context;
    if (m_context) {
        update(context);
    }
    emit contextChanged();
}

QQmlListProperty<Account> ContextModel::filterAccounts()
{
    return { this, &m_filter_accounts };
}

QQmlListProperty<Asset> ContextModel::filterAssets()
{
    return { this, &m_filter_assets };
}

void ContextModel::setFilterText(const QString& filter_text)
{
    if (m_filter_text == filter_text) return;
    m_filter_text = filter_text;
    emit filterTextChanged();
    invalidate();
}

void ContextModel::clearFilters()
{
    m_filter_accounts.clear();
    emit filterAccountsChanged();
    m_filter_assets.clear();
    emit filterAssetsChanged();
    m_filter_text.clear();
    emit filterTextChanged();
    m_filter_types.clear();
    emit filterTypesChanged();
    m_filter_statuses.clear();
    emit filterStatusesChanged();
    m_filter_has_transactions = false;
    emit filterHasTransactionsChanged();
    invalidate();
}

void ContextModel::setFilterAccount(Account* account)
{
    m_filter_accounts.clear();
    m_filter_accounts.append(account);
    emit filterAccountsChanged();
    invalidate();
}

void ContextModel::setFilterAsset(Asset* asset)
{
    m_filter_assets.clear();
    m_filter_assets.append(asset);
    emit filterAssetsChanged();
    invalidate();
}

void ContextModel::updateFilterAccounts(Account* account, bool filter)
{
    if (filter) {
        if (m_filter_accounts.contains(account)) return;
        m_filter_accounts.append(account);
    } else {
        if (!m_filter_accounts.contains(account)) return;
        m_filter_accounts.removeOne(account);
    }
    emit filterAccountsChanged();
    invalidate();
}

void ContextModel::updateFilterAssets(Asset* asset, bool filter)
{
    if (filter) {
        if (m_filter_assets.contains(asset)) return;
        m_filter_assets.append(asset);
    } else {
        if (!m_filter_assets.contains(asset)) return;
        m_filter_assets.removeOne(asset);
    }
    emit filterAssetsChanged();
    invalidate();
}

void ContextModel::updateFilterTypes(const QString& type, bool filter)
{
    if (filter) {
        if (m_filter_types.contains(type)) return;
        m_filter_types.append(type);
    } else {
        if (!m_filter_types.contains(type)) return;
        m_filter_types.removeOne(type);
    }
    emit filterTypesChanged();
    invalidate();
}

void ContextModel::updateFilterStatuses(const QString& status, bool filter)
{
    if (filter) {
        if (m_filter_statuses.contains(status)) return;
        m_filter_statuses.append(status);
    } else {
        if (!m_filter_statuses.contains(status)) return;
        m_filter_statuses.removeOne(status);
    }
    emit filterStatusesChanged();
    invalidate();
}

void ContextModel::updateFilterHasTransactions(bool filter)
{
    if (m_filter_has_transactions == filter) return;
    m_filter_has_transactions = filter;
    emit filterHasTransactionsChanged();
    invalidate();
}

void ContextModel::exportToFile()
{
}

TransactionModel::TransactionModel(QObject* parent)
    : ContextModel(parent)
{
    setSortRole(Qt::UserRole + 1);
}

void TransactionModel::exportToFile()
{
    auto datetime = QDateTime::currentDateTime();

    const QString suggestion =
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + QDir::separator() +
        context()->wallet()->name() + " - transactions - " +
        datetime.toString("yyyyMMddhhmmss") + ".csv";

    auto dialog = new QFileDialog(nullptr, "Save As", suggestion);
    dialog->setAcceptMode(QFileDialog::AcceptSave);
    dialog->setFileMode(QFileDialog::AnyFile);
    dialog->selectFile(suggestion);
    connect(dialog, &QFileDialog::fileSelected, this, [=](const QString& filename) {
        if (filename.isEmpty()) return;

        const auto wallet = context()->wallet();
        const auto session = context()->primarySession();
        const auto settings = session->settings();
        const auto display_unit = session->displayUnit();
        const auto pricing = settings.value("pricing").toObject();
        const auto currency = session->network()->isMainnet() ? pricing.value("currency").toString() : "FIAT";
        const auto exchange = pricing.value("exchange").toString();
        const auto unit = session->unit().toLower().replace("µbtc", "ubtc");

        QString fee_field = QString("fee (%1)").arg(display_unit);
        QString fiat_field = QString("fiat (%1 %2 %3)").arg(currency, exchange, datetime.toString(Qt::ISODate));
        QStringList fields = QStringList{"time", "network", "account", "description", "amount", "unit", fee_field, fiat_field, "txhash", "memo"};
        QStringList lines;
        QString separator{","};

        lines.append(fields.join(separator));

        const auto row_count = rowCount();
        for (int row = 0; row < row_count; ++row) {
            const auto transaction = index(row, 0).data(Qt::UserRole).value<Transaction*>();
            const auto network = transaction->account()->network();
            const auto data = transaction->data();
            const auto block_height = data.value("block_height").toInt();

            if (block_height == 0) continue;
            QJsonObject satoshi = transaction->data().value("satoshi").toObject();
            for (auto i = satoshi.begin(); i != satoshi.end(); ++i) {
                const auto asset = context()->getOrCreateAsset(i.key());
                QStringList values;
                for (auto field : fields) {
                    if (field == "network") {
                        values.append(network->displayName());
                    } else if (field == "account") {
                        auto name = transaction->account()->name();
                        values.append(name.isEmpty() ? qtTrId("id_main_account") : name);
                    } else if (field == "time") {
                        const auto created_at_ts = data.value("created_at_ts").toDouble();
                        const auto created_at = QDateTime::fromMSecsSinceEpoch(created_at_ts / 1000);
                        values.append(created_at.toString(Qt::ISODate));
                    } else if (field == "description") {
                        values.append(data.value("type").toString());
                    } else if (field == "amount") {
                        const auto amount = i.value().toInteger();
                        if (asset && asset->id() != network->policyAsset()) {
                            const auto precision = asset->data().value("precision").toInt(0);
                            const auto value = static_cast<double>(amount) / qPow(10, precision);
                            values.append(QString::number(value, 'f', precision));
                        } else {
                            const auto converted = wallet->convert({{ "satoshi", satoshi }});
                            values.append(converted.value(unit).toString());
                        }
                    } else if (field == "unit") {
                        if (asset && asset->id() != network->policyAsset()) {
                            values.append(asset->data().value("ticker").toString());
                        } else {
                            values.append(display_unit);
                        }
                    } else if (field == fee_field) {
                        if (data.value("type").toString() == "outgoing") {
                            const double fee = data.value("fee").toInt();
                            const auto converted = wallet->convert({{ "satoshi", fee }});
                            values.append(converted.value(unit).toString());
                        } else {
                            values.append("");
                        }
                    } else if (field == fiat_field) {
                        if (asset && asset->id() != network->policyAsset()) {
                            values.append("");
                        } else {
                            const auto amount = i.value().toInteger();
                            values.append(wallet->convert({{ "satoshi", amount }}).value("fiat").toString());
                        }
                    } else if (field == "txhash") {
                        values.append(data.value("txhash").toString());
                    } else if (field == "memo") {
                        values.append(data.value("memo").toString().replace("\n", " ").replace(",", "-"));
                    } else {
                        Q_UNREACHABLE();
                    }
                }
                lines.append(values.join(separator));
            }
        }

        QFile file(filename);
        bool result = file.open(QFile::WriteOnly);
        Q_ASSERT(result);

        QTextStream stream(&file);
        stream << lines.join("\n");

        QFileInfo info(file);
        QDesktopServices::openUrl(QUrl::fromLocalFile(info.absoluteFilePath()));
    });
    connect(this, &QObject::destroyed, dialog, &QFileDialog::deleteLater);
    dialog->open();
}

bool TransactionModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    auto transaction = sourceModel()->index(source_row, 0, source_parent).data(Qt::UserRole).value<Transaction*>();

    if (!transaction->data().contains("satoshi")) return false;
    if (!transaction->data().contains("type")) return false;

    if (!filterAccountsAcceptsTransaction(transaction)) return false;
    if (!filterAssetsAcceptsTransaction(transaction)) return false;
    if (!filterTextAcceptsTransaction(transaction)) return false;

    return ContextModel::filterAcceptsRow(source_row, source_parent);
}

bool TransactionModel::filterAccountsAcceptsTransaction(Transaction* transaction) const
{
    if (m_filter_accounts.isEmpty()) return true;

    for (auto account : m_filter_accounts) {
        if (transaction->account() == account) return true;
    }

    return false;
}

bool TransactionModel::filterAssetsAcceptsTransaction(Transaction* transaction) const
{
    if (m_filter_assets.isEmpty()) return true;

    for (auto asset : m_filter_assets) {
        if (transaction->hasAsset(asset)) return true;
    }

    return false;
}

bool TransactionModel::filterTextAcceptsTransaction(Transaction* transaction) const
{
    if (m_filter_text.isEmpty()) {
        return true;
    }
    if (transaction->hash().contains(m_filter_text)) {
        return true;
    }
    if (!transaction->memo().isEmpty() && transaction->memo().contains(m_filter_text)) {
        return true;
    }
    for (const auto output : transaction->data().value("outputs").toArray()) {
        if (output.toObject().value("address").toString().contains(m_filter_text)) {
            return true;
        }
    }
    return false;
}

void TransactionModel::update(Context* context)
{
    setSourceModel(context->transactionModel());
    connect(context, &Context::transactionUpdated, this, [=] {
        sort(0, Qt::DescendingOrder);
    });
}

AddressModel::AddressModel(QObject* parent)
    : ContextModel(parent)
{
    setSortRole(Qt::UserRole + 1);
}

void AddressModel::exportToFile()
{
    auto datetime = QDateTime::currentDateTime();

    const QString suggestion =
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + QDir::separator() +
        context()->wallet()->name() + " - addresses - " +
        datetime.toString("yyyyMMddhhmmss") + ".csv";

    auto dialog = new QFileDialog(nullptr, "Save As", suggestion);
    dialog->setAcceptMode(QFileDialog::AcceptSave);
    dialog->setFileMode(QFileDialog::AnyFile);
    dialog->selectFile(suggestion);
    connect(dialog, &QFileDialog::fileSelected, this, [=](const QString& filename) {
        if (filename.isEmpty()) return;

        QStringList fields = QStringList{"network", "account", "address", "tx_count"};
        QStringList lines;
        QString separator{","};

        lines.append(fields.join(separator));

        const auto row_count = rowCount();
        for (int row = 0; row < row_count; ++row) {
            const auto address = index(row, 0).data(Qt::UserRole).value<Address*>();            
            QStringList values;
            values.append(address->account()->network()->displayName());
            auto name = address->account()->name();
            values.append(name.isEmpty() ? qtTrId("id_main_account") : name);
            values.append(address->address());
            values.append(QString::number(address->data().value("tx_count").toInt()));
            lines.append(values.join(separator));
        }

        QFile file(filename);
        bool result = file.open(QFile::WriteOnly);
        Q_ASSERT(result);

        QTextStream stream(&file);
        stream << lines.join("\n");

        QFileInfo info(file);
        QDesktopServices::openUrl(QUrl::fromLocalFile(info.absoluteFilePath()));
    });
    connect(this, &QObject::destroyed, dialog, &QFileDialog::deleteLater);
    dialog->open();
}

bool AddressModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    auto address = sourceModel()->index(source_row, 0, source_parent).data(Qt::UserRole).value<Address*>();

    if (!filterAccountsAcceptsAddress(address)) return false;
    if (!filterTextAcceptsAddress(address)) return false;
    if (!filterTypesAcceptsAddress(address)) return false;
    if (!filterHasTransactionAcceptsAddress(address)) return false;

    return ContextModel::filterAcceptsRow(source_row, source_parent);
}

bool AddressModel::filterAccountsAcceptsAddress(Address* address) const
{
    if (m_filter_accounts.isEmpty()) return true;

    for (auto account : m_filter_accounts) {
        if (address->account() == account) return true;
    }

    return false;
}

bool AddressModel::filterTextAcceptsAddress(Address* address) const
{
    if (m_filter_text.isEmpty()) {
        return true;
    }
    if (address->address().contains(m_filter_text)) {
        return true;
    }
    return false;
}


bool AddressModel::filterTypesAcceptsAddress(Address* address) const
{
    if (m_filter_types.isEmpty()) {
        return true;
    }
    if (m_filter_types.contains(address->type())) {
        return true;
    }
    return false;
}

bool AddressModel::filterHasTransactionAcceptsAddress(Address* address) const
{
    if (!m_filter_has_transactions) {
        return true;
    }
    return address->data().value("tx_count").toInt() > 0;
}

void AddressModel::update(Context* context)
{
    setSourceModel(context->addressModel());
    connect(context, &Context::addressUpdated, this, [=] {
        sort(0, Qt::DescendingOrder);
    });
}

CoinModel::CoinModel(QObject* parent)
    : ContextModel(parent)
{
    setSortRole(Qt::UserRole + 1);
}

bool CoinModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    auto coin = sourceModel()->index(source_row, 0, source_parent).data(Qt::UserRole).value<Output*>();

    if (coin->spendingTransaction()) return false;

    if (!filterAccountsAcceptsCoin(coin)) return false;
    if (!filterAssetsAcceptsCoin(coin)) return false;
    if (!filterTextAcceptsCoin(coin)) return false;

    return ContextModel::filterAcceptsRow(source_row, source_parent);
}

void CoinModel::update(Context* context)
{
    setSourceModel(context->coinModel());
    connect(context, &Context::coinUpdated, this, [=] {
        sort(0, Qt::DescendingOrder);
    });
}

bool CoinModel::filterAccountsAcceptsCoin(Output* coin) const
{
    if (m_filter_accounts.isEmpty()) return true;

    for (auto account : m_filter_accounts) {
        if (coin->account() == account) return true;
    }

    return false;
}

bool CoinModel::filterAssetsAcceptsCoin(Output* coin) const
{
    if (m_filter_assets.isEmpty()) return true;

    for (auto asset : m_filter_assets) {
        if (coin->asset() == asset) {
            return true;
        }
    }

    return false;
}

bool CoinModel::filterTextAcceptsCoin(Output* coin) const
{
    if (m_filter_text.isEmpty()) {
        return true;
    }
    if (coin->address().contains(m_filter_text)) {
        return true;
    }
    return false;
}

LimitModel::LimitModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
}

void LimitModel::setSource(QAbstractItemModel* source)
{
    if (m_source == source) return;
    setSourceModel(nullptr);
    m_source = source;
    emit sourceChanged();
    setSourceModel(m_source);
}

void LimitModel::setLimit(int limit)
{
    if (m_limit == limit) return;
    m_limit = limit;
    emit limitChanged();
    invalidate();
}

bool LimitModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    return m_limit >= 0 && source_row < m_limit;
}

PaymentModel::PaymentModel(QObject* parent)
    : ContextModel(parent)
{
    setSortRole(Qt::UserRole + 1);
}

void PaymentModel::update(Context* context)
{
    setSourceModel(context->paymentModel());
    connect(context, &Context::paymentUpdated, this, &PaymentModel::invalidate);
}

bool PaymentModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    auto payment = sourceModel()->index(source_row, 0, source_parent).data(Qt::UserRole).value<Payment*>();

    if (!filterStatusesAcceptsPayment(payment)) return false;

    if (payment->transaction()) return false;
    if (payment->status() == "SETTLING") return true;

    return false;
}

bool PaymentModel::filterStatusesAcceptsPayment(Payment* payment) const
{
    if (m_filter_statuses.isEmpty()) {
        return true;
    }
    if (m_filter_statuses.contains(payment->status())) {
        return true;
    }
    return false;
}
