#ifndef BLOCKSTREAM_CONTEXT_H
#define BLOCKSTREAM_CONTEXT_H

#include "green.h"

#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>
#include <QStandardItemModel>

#include <memory>
#include <vector>

#include "lwk/lwk.hpp"

Q_MOC_INCLUDE("network.h")
Q_MOC_INCLUDE("device.h")
Q_MOC_INCLUDE("lightningsession.h")
Q_MOC_INCLUDE("notification.h")
Q_MOC_INCLUDE("session.h")
Q_MOC_INCLUDE("wallet.h")

class LightningSession;

class ContextTransaction : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString id READ id CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ContextTransaction(const QString& id, Context* context);
    Context* context() const { return m_context; }
    QString id() const { return m_id; }
    virtual QDateTime timestamp() const;
protected:
    Context* const m_context;
    const QString m_id;
};

class Context : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString deployment READ deployment CONSTANT)
    Q_PROPERTY(bool mainnet READ isMainnet CONSTANT)
    Q_PROPERTY(bool bip39 READ bip39 CONSTANT)
    Q_PROPERTY(QString xpubHashId READ xpubHashId NOTIFY xpubHashIdChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(Device* device READ device NOTIFY deviceChanged)
    Q_PROPERTY(bool remember READ remember NOTIFY rememberChanged)
    Q_PROPERTY(bool watchonly READ isWatchonly NOTIFY watchonlyChanged)
    Q_PROPERTY(QQmlListProperty<Session> sessions READ sessions NOTIFY sessionsChanged)
    Q_PROPERTY(Session* primarySession READ primarySession NOTIFY sessionsChanged)
    Q_PROPERTY(QQmlListProperty<Account> accounts READ accounts NOTIFY accountsChanged)
    Q_PROPERTY(QJsonObject credentials READ credentials NOTIFY credentialsChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic NOTIFY mnemonicChanged)
    Q_PROPERTY(bool lightningEnabled READ lightningEnabled NOTIFY lightningEnabledChanged)
    Q_PROPERTY(QStringList lightningMnemonic READ lightningMnemonic NOTIFY lightningMnemonicChanged)
    Q_PROPERTY(LightningSession* lightningSession READ lightningSession NOTIFY lightningSessionChanged)
    Q_PROPERTY(QJsonObject lightningNodeInfo READ lightningNodeInfo NOTIFY lightningNodeInfoChanged)
    Q_PROPERTY(TaskDispatcher* dispatcher READ dispatcher CONSTANT)
    Q_PROPERTY(QQmlListProperty<Notification> notifications READ notifications NOTIFY notificationsChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    Context(const QString& deployment, bool bip39, QObject* parent);
    ~Context();

    QString deployment() const { return m_deployment; }
    bool isMainnet() const { return m_deployment == "mainnet"; }
    bool bip39() const { return m_bip39; }

    void setSkipLoadAccounts(bool skip_load_accounts);

    TaskGroup* cleanAccounts();

    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);

    Q_INVOKABLE Session* getOrCreateSession(Network* network);
    Session* primarySession();
    void releaseSession(Session *session);

    Device* device() const { return m_device; }
    void setDevice(Device* device);

    bool remember() const { return m_remember; }
    void setRemember(bool remember);

    QJsonObject credentials() const { return m_credentials; }
    void setCredentials(const QJsonObject& credentials);

    QStringList mnemonic() const { return m_mnemonic; }
    void setMnemonic(const QStringList& mnemonic);

    bool isWatchonly() const { return m_watchonly; }
    void setWatchonly(bool watchonly);

    QList<Network*> getActiveNetworks() const;
    QList<Session*> getSessions() const { return m_sessions.values(); }
    QList<Account*> getAccounts() const { return m_accounts; }

    QQmlListProperty<Session> sessions();
    QQmlListProperty<Account> accounts();

    Q_INVOKABLE Asset* getOrCreateAsset(const QString& id);
    Q_INVOKABLE Account* getOrCreateAccount(Network* network, quint32 pointer);
    Account* getOrCreateAccount(Network* network, const QJsonObject& data);
    Account* getAccountByPointer(Network* network, int pointer) const;
    ChainTransaction* getOrCreateChainTransaction(const QString& hash);
    QList<ContextTransaction*> getTransaction(const QString& hash) const;
    Address* getOrCreateAddress(const QString& address);
    Payment* getOrCreatePayment(const QString& id);

    TaskDispatcher* dispatcher() const { return m_dispatcher; }

    QString xpubHashId() const { return m_xpub_hash_id; }
    void setXPubHashId(const QString& xpub_hash_id);

    bool lightningEnabled() const;
    void setLightningEnabled(bool enabled);

    QStringList lightningMnemonic() const;
    LightningSession* lightningSession();
    QJsonObject lightningNodeInfo() const;

    QList<Notification*> getNotifications() const { return m_notifications; }
    QQmlListProperty<Notification> notifications();
    void addNotification(Notification* notification);
    Q_INVOKABLE void removeNotification(Notification* notification);

    Q_INVOKABLE Network* primaryNetwork();
    Q_INVOKABLE QString getDisplayUnit(const QString& unit);
    Q_INVOKABLE void addTestNotification(const QString& message = "This is a test notification for development purposes. You can safely dismiss this message.");
    Q_INVOKABLE void addTestSystemNotification(const QString& message = "This is a test notification for development purposes. You can safely dismiss this message.");
    Q_INVOKABLE void addTestOutageNotification();
    Q_INVOKABLE void addTestTwoFactorResetNotification();
    Q_INVOKABLE void addTestTwoFactorExpiredNotification();
    Q_INVOKABLE void addTestWarningNotification();
    Q_INVOKABLE void addTestUpdateNotification();
    Q_INVOKABLE void checkAndAddBackupWarningNotification();

    void loadNetwork(TaskGroup* group, Network* network);
    void loginNetwork(TaskGroup* group, Network* network);
    void createStandardAccount(TaskGroup* group, Network* network);

public slots:
    void refreshAccounts();

signals:
    void walletChanged();
    void deviceChanged();
    void rememberChanged();
    void credentialsChanged();
    void mnemonicChanged();
    void accountsChanged();
    void watchonlyChanged();
    void sessionsChanged();
    void autoLogout();
    void logout();
    void notificationAdded(Notification* notification);
    void notificationRemoved(Notification* notification);
    void notificationsChanged();
    void notificationTriggered(Notification* notification);
    void xpubHashIdChanged();
    void transactionUpdated();
    void coinUpdated();
    void addressUpdated();
    void paymentUpdated();
    void lightningEnabledChanged();
    void lightningMnemonicChanged();
    void lightningSessionChanged();
    void lightningNodeInfoChanged();

private:
    void releaseLightningSession();
    void updateLightningEnabled(bool was_enabled);

    const QString m_deployment;
    const bool m_bip39;
    bool m_skip_load_accounts{false};
    Wallet* m_wallet{nullptr};
    Device* m_device{nullptr};
    bool m_remember{true};
    QString m_xpub_hash_id;
    QJsonObject m_credentials;
    QStringList m_mnemonic;
    QMap<Network*, Session*> m_sessions;
    QList<Session*> m_sessions_list;
    bool m_watchonly{false};

    QList<Notification*> m_notifications;
    OutageNotification* m_outage_notification{nullptr};
    bool m_assets_loaded{false};

public:
    QMap<QString, Asset*> m_assets;
    QList<Account*> m_accounts;
    QMap<QPair<Network*, quint32>, Account*> m_accounts_by_pointer;

    TaskDispatcher* const m_dispatcher;

    QJsonObject m_hw_device;

    QMap<QString, ChainTransaction*> m_chain_transactions;
    QMap<ContextTransaction*, QStandardItem*> m_transaction_item;
    QMultiMap<QString, ContextTransaction*> m_transaction_map;
    QStandardItemModel* const m_transaction_model;
    void addTransaction(ContextTransaction* transaction);
    void removeTransaction(ContextTransaction* transaction);
    QStandardItemModel* transactionModel() const { return m_transaction_model; }

    QMap<Address*, QStandardItem*> m_address_item;
    QMap<QString, Address*> m_address_map;
    QStandardItemModel* const m_address_model;
    QStandardItemModel* addressModel() const { return m_address_model; }

    QMap<Output*, QStandardItem*> m_coin_item;
    QStandardItemModel* const m_coin_model;
    void addCoin(Output* coin);
    QStandardItemModel* coinModel() const { return m_coin_model; }

    QMap<QString, Payment*> m_payments;
    QMap<Payment*, QStandardItem*> m_payment_item;
    QStandardItemModel* const m_payment_model;
    QStandardItemModel* paymentModel() const { return m_payment_model; }

    void addSwap(Swap* swap);
    void removeSwap(Swap* swap);
    std::shared_ptr<lwk::BoltzSession> m_boltz_session;
    QJsonObject m_boltz_swaps_infos;
    QList<Swap*> m_swaps;

    LightningSession* m_lightning_session{nullptr};
};

class ContextManager : public QObject
{
public:
    ContextManager();
    ~ContextManager();
    static ContextManager* instance();
    Context* create(const QString& deployment, bool bip39);
private:
    QList<Context*> m_contexts;
};

#endif // BLOCKSTREAM_CONTEXT_H
