#ifndef GREEN_CONTEXT_H
#define GREEN_CONTEXT_H

#include "green.h"

#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>
#include <QStandardItemModel>

Q_MOC_INCLUDE("network.h")
Q_MOC_INCLUDE("device.h")
Q_MOC_INCLUDE("notification.h")
Q_MOC_INCLUDE("session.h")
Q_MOC_INCLUDE("wallet.h")

class Context : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString deployment READ deployment CONSTANT)
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
    Q_PROPERTY(TaskDispatcher* dispatcher READ dispatcher CONSTANT)
    Q_PROPERTY(QQmlListProperty<Notification> notifications READ notifications NOTIFY notificationsChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    Context(const QString& deployment, bool bip39, QObject* parent);
    ~Context();

    QString deployment() const { return m_deployment; }
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

    TaskDispatcher* dispatcher() const { return m_dispatcher; }

    QString xpubHashId() const { return m_xpub_hash_id; }
    void setXPubHashId(const QString& xpub_hash_id);

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
    void loadNetwork2(TaskGroup* group, Network* network);
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

private:
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

    QMap<Transaction*, QStandardItem*> m_transaction_item;
    QStandardItemModel* const m_transaction_model;
    void addTransaction(Transaction* transaction);
    QStandardItemModel* transactionModel() const { return m_transaction_model; }

    QMap<Address*, QStandardItem*> m_address_item;
    QStandardItemModel* const m_address_model;
    void addAddress(Address* address);
    QStandardItemModel* addressModel() const { return m_address_model; }

    QMap<Output*, QStandardItem*> m_coin_item;
    QStandardItemModel* const m_coin_model;
    void addCoin(Output* coin);
    QStandardItemModel* coinModel() const { return m_coin_model; }
};


#include <QSortFilterProxyModel>

class ContextModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context WRITE setContext NOTIFY contextChanged)
    Q_PROPERTY(QQmlListProperty<Account> filterAccounts READ filterAccounts NOTIFY filterAccountsChanged)
    Q_PROPERTY(QQmlListProperty<Asset> filterAssets READ filterAssets NOTIFY filterAssetsChanged)
    Q_PROPERTY(QStringList filterTypes READ filterTypes NOTIFY filterTypesChanged)
    Q_PROPERTY(bool filterHasTransactions READ filterHasTransactions NOTIFY filterHasTransactionsChanged)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ContextModel(QObject* parent = nullptr);
    Context* context() const { return m_context; }
    void setContext(Context* context);
    QQmlListProperty<Account> filterAccounts();
    QQmlListProperty<Asset> filterAssets();
    QStringList filterTypes() const { return m_filter_types; }
    bool filterHasTransactions() const { return m_filter_has_transactions; }
    QString filterText() const { return m_filter_text; }
    void setFilterText(const QString& filter_text);
signals:
    void contextChanged();
    void filterAccountsChanged();
    void filterAssetsChanged();
    void filterTypesChanged();
    void filterHasTransactionsChanged();
    void filterTextChanged();
public slots:
    void clearFilters();
    void setFilterAccount(Account* account);
    void setFilterAsset(Asset* asset);
    void updateFilterAccounts(Account* account, bool filter);
    void updateFilterAssets(Asset* asset, bool filter);
    void updateFilterTypes(const QString& type, bool filter);
    void updateFilterHasTransactions(bool has_transactions);
    virtual void exportToFile();
protected:
    virtual void update(Context* context) = 0;
protected:
    QList<Account*> m_filter_accounts;
    QList<Asset*> m_filter_assets;
    QStringList m_filter_types;
    bool m_filter_has_transactions{false};
    QString m_filter_text;
private:
    Context* m_context{nullptr};
};

class TransactionModel : public ContextModel
{
    Q_OBJECT
    QML_ELEMENT
public:
    TransactionModel(QObject* parent = nullptr);
    void exportToFile() override;
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    void update(Context* context) override;
private:
    bool filterAccountsAcceptsTransaction(Transaction* transaction) const;
    bool filterAssetsAcceptsTransaction(Transaction* transaction) const;
    bool filterTextAcceptsTransaction(Transaction* transaction) const;
};

class AddressModel : public ContextModel
{
    Q_OBJECT
    QML_ELEMENT
public:
    AddressModel(QObject* parent = nullptr);
    void exportToFile() override;
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    void update(Context* context) override;
private:
    bool filterAccountsAcceptsAddress(Address* address) const;
    bool filterTextAcceptsAddress(Address* address) const;
    bool filterTypesAcceptsAddress(Address* address) const;
    bool filterHasTransactionAcceptsAddress(Address* address) const;
};

class CoinModel : public ContextModel
{
    Q_OBJECT
    QML_ELEMENT
public:
    CoinModel(QObject* parent = nullptr);
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    void update(Context* context) override;
private:
    bool filterAccountsAcceptsCoin(Output* coin) const;
    bool filterAssetsAcceptsCoin(Output* coin) const;
    bool filterTextAcceptsCoin(Output* coin) const;
};

class LimitModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QAbstractItemModel* source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(int limit READ limit WRITE setLimit NOTIFY limitChanged)
    QML_ELEMENT
public:
    LimitModel(QObject* parent = nullptr);
    QAbstractItemModel* source() const { return m_source; }
    void setSource(QAbstractItemModel* source);
    int limit() const { return m_limit; }
    void setLimit(int limit);
signals:
    void sourceChanged();
    void limitChanged();
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const;
private:
    QAbstractItemModel* m_source{nullptr};
    int m_limit{-1};
};

#endif // GREEN_CONTEXT_H
