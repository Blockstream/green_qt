#include "account.h"
#include "address.h"
#include "appupdatecontroller.h"
#include "asset.h"
#include "assetmanager.h"
#include "bip85.h"
#include "context.h"
#include "context_p.h"
#include "controllers/lwkamp2accountcontroller.h"
#include "device.h"
#include "green_settings.h"
#include "json.h"
#include "lightningsession.h"
#include "lwk/lwk.hpp"
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
#include <memory>
#include <optional>

#include <QDateTime>
#include <QDesktopServices>
#include <QFile>
#include <QFileDialog>
#include <QStandardPaths>
#include <QTextStream>
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
    , d_ptr(new ContextPrivate(this, deployment, bip39))
{
    Q_ASSERT(deployment == "mainnet" || deployment == "testnet" || deployment == "development");
}

Context::~Context()
{
    Q_D(Context);

    releaseLightningSession();

    for (auto session : d->sessions_list) {
        SessionManager::instance()->release(session);
        session->setContext(nullptr);
        session->setActive(false);
    }

    delete d_ptr;
}

QString Context::deployment() const
{
    Q_D(const Context);
    return d->deployment;
}

bool Context::isMainnet() const
{
    Q_D(const Context);
    return d->deployment == "mainnet";
}

bool Context::bip39() const
{
    Q_D(const Context);
    return d->bip39;
}

void Context::setSkipLoadAccounts(bool skip_load_accounts)
{
    Q_D(Context);

    d->skip_load_accounts = skip_load_accounts;
}

TaskGroup* Context::cleanAccounts()
{
    Q_D(Context);

    auto group = new TaskGroup(this);
    if (d->watchonly) return group;
    for (auto account : d->accounts) {
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

Wallet *Context::wallet() const
{
    Q_D(const Context);
    return d->wallet;
}

void Context::setWallet(Wallet* wallet)
{
    Q_D(Context);

    if (d->wallet == wallet) return;
    const auto was_lightning_enabled = lightningEnabled();
    if (d->wallet) {
        disconnect(d->wallet, &Wallet::lightningEnabledChanged, this, nullptr);
    }
    d->wallet = wallet;
    emit walletChanged();
    if (d->wallet) {
        connect(d->wallet, &Wallet::lightningEnabledChanged, this, [this] {
            if (!lightningEnabled()) {
                releaseLightningSession();
            }
            emit lightningEnabledChanged();
        });
        if (!d->bip39 && !d->xpub_hash_id.isEmpty()) {
            d->wallet->setXPubHashId(d->xpub_hash_id);
        }
    }
    updateLightningEnabled(was_lightning_enabled);
}

Session* Context::getOrCreateSession(Network* network)
{
    Q_D(Context);

    if (!network) return nullptr;

    auto session = d->sessions.value(network);
    if (!session) {
        session = SessionManager::instance()->create(network);
        session->setContext(this);
        session->setActive(true);
        connect(session, &Session::autoLogoutTriggered, this, [=, this] {
            if (d->wallet && !qobject_cast<DeviceData*>(d->wallet->login())) {
                emit autoLogout();
            }
        });
        connect(session, &Session::blockEvent, this, [=, this](const QJsonObject& event) {
            auto group = new TaskGroup(this);
            for (auto account : d->accounts) {
                if (account->isAmp2()) continue;

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
            } else if (event_type == "synced" && !d->skip_load_accounts) {
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
            if (network->isLiquid()) {
                connect(group, &TaskGroup::finished, this, [=, this] {
                    const auto txhash = event.value("txhash").toString();
                    for (auto pointer : event.value("subaccounts").toArray()) {
                        auto account = getOrCreateAccount(network, quint32(pointer.toInteger()));
                        auto transaction = account->getTransaction(txhash);
                        if (!transaction) continue;
                        const auto satoshi = transaction->data().value("satoshi").toObject();
                        for (auto i = satoshi.begin(); i != satoshi.end(); ++i) {
                            if (!getOrCreateAsset(i.key())->hasData()) {
                                dispatcher()->add(new LoadAssetsTask(true, session));
                                return;
                            }
                        }
                    }
                });
            }
            dispatcher()->add(group);
        });
        connect(session, &Session::configChanged, this, [=, this] {
            TwoFactorResetNotification* two_factor_reset_notification = nullptr;
            for (auto notification : d->notifications) {
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
        d->sessions.insert(network, session);
        d->sessions_list.append(session);
        emit sessionsChanged();
    }
    return session;
}

Session* Context::primarySession()
{
    Q_D(Context);

    if (d->sessions_list.size() > 0) {
        return d->sessions_list.first();
    } else {
        auto network = primaryNetwork();
        auto session = getOrCreateSession(network);
        return session;
    }
}

void Context::releaseSession(Session* session)
{
    Q_D(Context);

    for (auto account : d->accounts) {
        if (account->session() == session) {
            qWarning() << Q_FUNC_INFO << "should remove account" << account->network()->id() << account->pointer();
        }
    }
    d->sessions.take(session->network());
    d->sessions_list.removeOne(session);
    emit sessionsChanged();

    SessionManager::instance()->release(session);
}

Device* Context::device() const
{
    Q_D(const Context);
    return d->device;
}

void Context::setDevice(Device* device)
{
    Q_D(Context);
    if (d->device == device) return;
    const auto was_lightning_enabled = lightningEnabled();
    d->device = device;
    if (d->device) {
        QObject::connect(d->device, &QObject::destroyed, this, [=, this] {
            setDevice(nullptr);
        });
        if (d->wallet) {
            auto device_data = qobject_cast<DeviceData*>(d->wallet->login());
            if (device_data) {
                device_data->setDevice(d->device->details());
                d->wallet->save();
            }
        }
    }
    emit deviceChanged();
    updateLightningEnabled(was_lightning_enabled);
}

QJsonObject Context::deviceDetails() const
{
    Q_D(const Context);
    return d->device_details;
}

void Context::setDeviceDetails(const QJsonObject& device_details)
{
    Q_D(Context);
    d->device_details = device_details;
}

bool Context::remember() const
{
    Q_D(const Context);
    return d->remember;
}

void Context::setRemember(bool remember)
{
    Q_D(Context);

    if (d->remember == remember) return;
    d->remember = remember;
    emit rememberChanged();
}

QJsonObject Context::credentials() const
{
    Q_D(const Context);
    return d->credentials;
}

void Context::setCredentials(const QJsonObject &credentials)
{
    Q_D(Context);

    if (d->credentials == credentials) return;
    const auto mnemonic = credentials.value("mnemonic").toString().split(" ");
    const auto mnemonic_changed = d->mnemonic != mnemonic;
    d->credentials = credentials;
    emit credentialsChanged();
    setMnemonic(mnemonic);
    if (!mnemonic_changed) {
        emit lightningMnemonicChanged();
    }
}

QStringList Context::mnemonic() const
{
    Q_D(const Context);
    return d->mnemonic;
}

void Context::setMnemonic(const QStringList& mnemonic)
{
    Q_D(Context);

    if (d->mnemonic == mnemonic) return;
    Q_ASSERT(d->mnemonic.isEmpty());
    d->mnemonic = mnemonic;
    emit mnemonicChanged();
    emit lightningMnemonicChanged();
}

bool Context::isWatchonly() const
{
    Q_D(const Context);
    return d->watchonly;
}

void Context::setWatchonly(bool watchonly)
{
    Q_D(Context);

    if (d->watchonly == watchonly) return;
    const auto was_lightning_enabled = lightningEnabled();
    d->watchonly = watchonly;
    emit watchonlyChanged();
    updateLightningEnabled(was_lightning_enabled);
}

QStringList Context::lightningMnemonic() const
{
    Q_D(const Context);

    if (d->bip39) return {};

    const auto source_mnemonic = d->mnemonic.join(' ');
    if (source_mnemonic.trimmed().isEmpty()) return {};

    const auto source_passphrase = d->credentials.value("bip39_passphrase").toString();
    const auto lightning_mnemonic = DeriveBip85Mnemonic(isMainnet(), source_mnemonic, source_passphrase, 0);
    if (lightning_mnemonic.isEmpty()) return {};

    return lightning_mnemonic.split(' ', Qt::SkipEmptyParts);
}

QList<Session*> Context::getSessions() const
{
    Q_D(const Context);
    return d->sessions.values();
}

QList<Account*> Context::getAccounts() const
{
    Q_D(const Context);
    return d->accounts;
}

QList<Network*> Context::getActiveNetworks() const
{
    Q_D(const Context);

    QList<Network*> networks;
    for (auto session : d->sessions_list) {
        if (session->isConnected() && session->m_ready) {
            networks.append(session->network());
        }
    }
    return networks;
}

Asset* Context::getOrCreateAsset(const QString& id)
{
    Q_D(Context);
    return AssetManager::instance()->assetWithId(d->deployment, id);
}

Account* Context::getOrCreateAccount(Network* network, quint32 pointer)
{
    Q_D(Context);

    Account* account = d->accounts_by_pointer.value({ network, pointer });
    if (!account) {
        account = new Account(network, pointer, this);
        d->accounts_by_pointer.insert({ network, pointer }, account);
        d->accounts.append(account);
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
    Q_D(const Context);

    return d->accounts_by_pointer.value({ network, pointer });
}

Account* Context::getOrCreateAmp2Account(Network* network)
{
    Q_D(Context);
    // AMP2 has no gdk subaccount, so reserve a synthetic pointer that gdk never
    // allocates to track the account alongside the gdk ones. The lwk wollet
    // lives on LwkAmp2AccountController, not the Account, so the generic path
    // is fine.
    constexpr quint32 AMP2_POINTER = 0x40000000;
    return getOrCreateAccount(network, QJsonObject{
        { "pointer", static_cast<qint64>(AMP2_POINTER) },
        { "type", "amp2" },
        { "name", "AMP Liquid" },
        { "hidden", false },
        { "amp2_wid", d->wallet ? d->wallet->m_amp2_wid : QString() },
    });
}

LwkAmp2AccountController* Context::amp2AccountController()
{
    Q_D(Context);
    if (!d->wallet || d->wallet->m_amp2_wid.isEmpty()) return nullptr;

    if (!d->amp2_account_controller) {
        d->amp2_account_controller = new LwkAmp2AccountController(this);
        d->amp2_account_controller->setContext(this);
    }

    return d->amp2_account_controller;
}

ChainTransaction* Context::getOrCreateChainTransaction(const QString &hash)
{
    Q_D(Context);

    auto chain_transaction = d->chain_transactions.value(hash);
    if (!chain_transaction) {
        chain_transaction = new ChainTransaction(hash, this);
        d->chain_transactions.insert(hash, chain_transaction);
    }
    return chain_transaction;
}

QList<ContextTransaction*> Context::getTransaction(const QString &hash) const
{
    Q_D(const Context);

    return d->transaction_map.values(hash);
}

void Context::updateLightningTransactions(const std::vector<LightningPayment>& payments)
{
    Q_D(Context);

    auto dangling_transactions = d->lightning_transactions.keys();

    for (const auto& payment : payments) {
        const auto id = payment.id;
        if (id.isEmpty()) continue;

        auto transaction = d->lightning_transactions.value(id);
        if (!transaction) {
            transaction = new LightningTransaction(id, this);
            d->lightning_transactions.insert(id, transaction);
        }

        transaction->updateFromPayment(payment);
        addTransaction(transaction);
        dangling_transactions.removeOne(id);
    }

    while (!dangling_transactions.isEmpty()) {
        const auto id = dangling_transactions.takeFirst();
        auto transaction = d->lightning_transactions.take(id);
        if (!transaction) continue;
        removeTransaction(transaction);
        transaction->deleteLater();
    }

    emit transactionUpdated();
}

QStandardItemModel* Context::paymentModel() const
{
    Q_D(const Context);
    return d->payment_model;
}

Payment* Context::getOrCreatePayment(const QString &id)
{
    Q_D(Context);

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

        d->payment_item.insert(payment, item);
        d->payment_model->appendRow(item);
    }
    return payment;
}

TaskDispatcher *Context::dispatcher() const
{
    Q_D(const Context);
    return d->dispatcher;
}

QString Context::xpubHashId() const
{
    Q_D(const Context);
    return d->xpub_hash_id;
}

void Context::setXPubHashId(const QString& xpub_hash_id)
{
    Q_D(Context);

    if (d->xpub_hash_id == xpub_hash_id) return;
    Q_ASSERT(d->xpub_hash_id.isEmpty());
    d->xpub_hash_id = xpub_hash_id;
    if (!d->bip39 && d->wallet) {
        d->wallet->setXPubHashId(xpub_hash_id);
    }
    emit xpubHashIdChanged();
}

LightningSession* Context::lightningSession()
{
    Q_D(Context);

    if (d->xpub_hash_id.isEmpty()) return nullptr;

    if (!d->lightning_session) {
        d->lightning_session = new LightningSession(this);
        connect(d->lightning_session, &LightningSession::nodeInfoChanged, this, &Context::lightningNodeInfoChanged);
        connect(d->lightning_session, &LightningSession::paymentsUpdated, this, [this](const std::vector<LightningPayment>& payments) {
            updateLightningTransactions(payments);
        });
        emit lightningSessionChanged();
    }

    return d->lightning_session;
}

QJsonObject Context::lightningNodeInfo() const
{
    Q_D(const Context);

    return d->lightning_session ? d->lightning_session->nodeInfo() : QJsonObject{};
}

bool Context::assetsLoaded() const
{
    Q_D(const Context);
    return d->assets_loaded;
}

void Context::setAssetsLoaded()
{
    Q_D(Context);
    d->assets_loaded = true;
}

bool Context::lightningEnabled() const
{
    Q_D(const Context);

    return !d->bip39 && isMainnet() && !d->watchonly && !d->device && d->wallet && d->wallet->lightningEnabled();
}

void Context::updateLightningEnabled(bool was_enabled)
{
    if (!lightningEnabled()) {
        releaseLightningSession();
    }
    if (was_enabled != lightningEnabled()) {
        emit lightningEnabledChanged();
    }
}

void Context::setLightningEnabled(bool enabled)
{
    Q_D(Context);
    if (!d->wallet || d->wallet->lightningEnabled() == enabled) return;
    d->wallet->setLightningEnabled(enabled);
}

void Context::releaseLightningSession()
{
    Q_D(Context);

    if (!d->lightning_session) return;

    auto session = d->lightning_session;
    d->lightning_session = nullptr;
    session->disconnectNode();
    delete session;

    emit lightningSessionChanged();
    emit lightningNodeInfoChanged();

    const auto transactions = d->lightning_transactions.values();
    d->lightning_transactions.clear();
    for (auto transaction : transactions) {
        removeTransaction(transaction);
        transaction->deleteLater();
    }
    emit transactionUpdated();
}

QList<Notification*> Context::getNotifications() const
{
    Q_D(const Context);
    return d->notifications;
}

QQmlListProperty<Notification> Context::notifications()
{
    Q_D(Context);

    return { this, &d->notifications };
}

void Context::addNotification(Notification* notification)
{
    Q_D(Context);

    d->notifications.append(notification);
    emit notificationsChanged();
    emit notificationAdded(notification);
    connect(notification, &Notification::triggered, this, [=, this] {
        emit notificationTriggered(notification);
    });
}

void Context::removeNotification(Notification* notification)
{
    Q_D(Context);

    emit notificationRemoved(notification);
    d->notifications.removeOne(notification);
    emit notificationsChanged();
}

Network *Context::primaryNetwork()
{
    Q_D(Context);
    for (auto network : NetworkManager::instance()->networkForDeployment(d->deployment)) {
        if (d->device) {
            if (d->device->supportsNetwork(network)) return network;
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
    Q_D(Context);
    if (!d->wallet || !qobject_cast<PinData*>(d->wallet->login())) {
        return;
    }

    auto settings = Settings::instance();
    const auto event = QJsonObject{
        { "walletId", d->xpub_hash_id },
        { "status", "pending" },
        { "type", "wallet_backup" }
    };
    const bool event_registered = settings->isEventRegistered(event);

    BackupNotification* backup_notification{nullptr};
    for (auto notification : d->notifications) {
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
    Q_D(Context);

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

    if (d->skip_load_accounts) {
        createStandardAccount(group, network);
        return;
    }

    auto load_accounts = new LoadAccountsTask(false, session);
    group->add(load_accounts);

    connect(load_accounts, &Task::finished, this, [=, this] {
        if (network->isElectrum()) {
            bool has_native_segwit = false;

            for (auto account : load_accounts->accounts()) {
                if (account->type() == "p2wpkh") {
                    has_native_segwit = true;
                    break;
                }
            }

            if (!has_native_segwit) {
                createStandardAccount(group, network);
            }
        }

        for (auto account : load_accounts->accounts()) {
            group->add(new LoadBalanceTask(account));
            fetchCoins(group, account);
            fetchTransactions(group, account);
        }
    });
    connect(load_accounts, &Task::failed, this, [=, this](auto error) {
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

QJsonObject device_details_from_device(Device* device);

void Context::loginNetwork(TaskGroup *group, Network *network)
{
    Q_D(Context);

    auto session = getOrCreateSession(network);
    auto connect_session = new ConnectTask(10000, session);
    LoginTask* login{nullptr};

    if (d->device) {
        login = new LoginTask(device_details_from_device(d->device), session);
    } else if (d->credentials.contains("mnemonic")) {
        login = new LoginTask(d->credentials, {}, session);
    }

    auto load_assets = new LoadAssetsTask(false, session);
    connect_session->then(load_assets);
    load_assets->then(login);
    group->add(load_assets);

    connect(connect_session, &Task::failed, this, [=, this](const QString& error) {
        if (error == "timeout error") {
            // TODO
            // setError("session", "id_connection_failed");
            releaseSession(session);
            if (!d->outage_notification) {
                d->outage_notification = new OutageNotification(this);
                addNotification(d->outage_notification);
            }
            d->outage_notification->add(network);
        }
    });

    const auto pricing = primarySession()->settings().value("pricing");
    if (pricing.isObject()) {
        auto sync_settings = new ChangeSettingsTask(QJsonObject{{ "pricing", pricing }}, session);
        login->then(sync_settings);
        group->add(sync_settings);
    }

    connect(login, &Task::finished, this, [=, this] {
        if (d->outage_notification) {
            d->outage_notification->remove(network);
            if (d->outage_notification->isEmpty()) {
                removeNotification(d->outage_notification);
                // TODO d->outage_notification->deleteLater();
                d->outage_notification = nullptr;
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

void Context::refresh()
{
    Q_D(Context);

    LoadAssetsTask* load_assets{nullptr};
    auto group = new TaskGroup(this);
    for (auto session : d->sessions_list) {
        if (session->network()->isLiquid() && !load_assets) {
            load_assets = new LoadAssetsTask(true, session);
            group->add(load_assets);
        }
        auto load_accounts = new LoadAccountsTask(!isWatchonly(), session);
        connect(load_accounts, &Task::finished, this, [=, this] {
            for (auto account : load_accounts->accounts()) {
                group->add(new LoadBalanceTask(account));
            }
        });
        group->add(load_accounts);
    }
    dispatcher()->add(group);
    connect(group, &TaskGroup::finished, group, &QObject::deleteLater);
}

QStandardItemModel* Context::transactionModel() const
{
    Q_D(const Context);
    return d->transaction_model;
}

void Context::addTransaction(ContextTransaction* transaction)
{
    Q_D(Context);

    auto item = d->transaction_item.value(transaction);

    if (!item) {
        d->transaction_map.insert(transaction->id(), transaction);

        item = new QStandardItem;
        item->setData(QVariant::fromValue(transaction), Qt::UserRole);
        d->transaction_item.insert(transaction, item);
        d->transaction_model->appendRow(item);
    }

    item->setData(QVariant::fromValue(transaction->timestamp()), Qt::UserRole + 1);
}

void Context::removeTransaction(ContextTransaction* transaction)
{
    Q_D(Context);

    auto item = d->transaction_item.take(transaction);
    d->transaction_map.remove(transaction->id(), transaction);

    if (item) {
        d->transaction_model->removeRow(item->row());
    }
}

QStandardItemModel* Context::addressModel() const
{
    Q_D(const Context);
    return d->address_model;
}

Address* Context::getOrCreateAddress(const QString& value)
{
    Q_D(Context);

    Address* address = d->address_map.value(value);
    if (address) return address;

    address = new Address(this, value);
    d->address_map.insert(value, address);

    auto item = new QStandardItem;
    item->setData(QVariant::fromValue(address), Qt::UserRole);
    item->setData(value, Qt::UserRole + 1);
    d->address_item.insert(address, item);
    d->address_model->appendRow(item);

    return address;
}

QStandardItemModel* Context::coinModel() const
{
    Q_D(const Context);
    return d->coin_model;
}

void Context::addCoin(Output* coin)
{
    Q_D(Context);

    auto item = d->coin_item.value(coin);

    if (!item) {
        item = new QStandardItem;
        item->setData(QVariant::fromValue(coin), Qt::UserRole);
        d->coin_item.insert(coin, item);
        d->coin_model->appendRow(item);
    }

    auto block_height = coin->data().value("block_height").toInt();
    item->setData(block_height > 0 ? block_height : INT_MAX, Qt::UserRole + 1);
}

QQmlListProperty<Account> Context::accounts()
{
    Q_D(Context);

    return { this, &d->accounts };
}

QQmlListProperty<Session> Context::sessions()
{
    Q_D(Context);

    return { this, &d->sessions_list };
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

void ContextManager::exit()
{
    // Contexts hold raw pointers to their sessions and release them from their
    // destructor, so they must be destroyed before SessionManager::exit() frees
    // the sessions. Contexts are usually torn down with deleteLater(), which
    // never runs once the event loop has stopped, so destroy them explicitly.
    if (!m_contexts.isEmpty()) {
        qDebug() << Q_FUNC_INFO << "total contexts:" << m_contexts.count();
        while (!m_contexts.isEmpty()) {
            delete m_contexts.takeFirst();
        }
    }
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
