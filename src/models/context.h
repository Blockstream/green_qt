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
Q_MOC_INCLUDE("controllers/lwkamp2accountcontroller.h")

class LightningSession;
class LwkAmp2AccountController;
struct LightningPayment;

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

class ContextPrivate;
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
    Q_PROPERTY(bool lightningEnabled READ lightningEnabled NOTIFY lightningEnabledChanged)
    Q_PROPERTY(LightningSession* lightningSession READ lightningSession NOTIFY lightningSessionChanged)
    Q_PROPERTY(QJsonObject lightningNodeInfo READ lightningNodeInfo NOTIFY lightningNodeInfoChanged)
    Q_PROPERTY(TaskDispatcher* dispatcher READ dispatcher CONSTANT)
    Q_PROPERTY(QQmlListProperty<Notification> notifications READ notifications NOTIFY notificationsChanged)
    Q_DECLARE_PRIVATE(Context)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    Context(const QString& deployment, bool bip39, QObject* parent);
    ~Context();

    QString deployment() const;
    bool isMainnet() const;
    bool bip39() const;

    void setSkipLoadAccounts(bool skip_load_accounts);

    TaskGroup* cleanAccounts();

    Wallet* wallet() const;
    void setWallet(Wallet* wallet);

    Q_INVOKABLE Session* getOrCreateSession(Network* network);
    Session* primarySession();
    void releaseSession(Session *session);

    Device* device() const;
    void setDevice(Device* device);

    QJsonObject deviceDetails() const;
    void setDeviceDetails(const QJsonObject& device_details);

    bool remember() const;
    void setRemember(bool remember);

    QJsonObject credentials() const;
    void setCredentials(const QJsonObject& credentials);
    Q_INVOKABLE QStringList mnemonic() const;
    Q_INVOKABLE QString bip39Passphrase() const;

    bool isSoftwareSigner() const;

    bool isWatchonly() const;
    void setWatchonly(bool watchonly);

    QList<Network*> getActiveNetworks() const;
    QList<Session*> getSessions() const;
    QList<Account*> getAccounts() const;

    QQmlListProperty<Session> sessions();
    QQmlListProperty<Account> accounts();

    Q_INVOKABLE Asset* getOrCreateAsset(const QString& id);
    Q_INVOKABLE Account* getOrCreateAccount(Network* network, quint32 pointer);
    Account* getOrCreateAccount(Network* network, const QJsonObject& data);

    // Create/lookup the synthetic AMP2 account (no gdk subaccount exists).
    Account* getOrCreateAmp2Account(Network* network);
    // All lwk/AMP2 runtime state (wollet, waterfalls client/subscription,
    // derivation) lives on LwkAmp2AccountController, not here. Lazily
    // instantiated once the wallet has a registered AMP2 wid (see
    // Wallet::m_amp2_wid); returns nullptr otherwise. Mirrors lightningSession().
    LwkAmp2AccountController* amp2AccountController();

    Account* getAccountByPointer(Network* network, int pointer) const;
    ChainTransaction* getOrCreateChainTransaction(const QString& hash);
    QList<ContextTransaction*> getTransaction(const QString& hash) const;
    Address* getOrCreateAddress(const QString& address);
    Payment* getOrCreatePayment(const QString& id);

    TaskDispatcher* dispatcher() const;

    QString xpubHashId() const;
    void setXPubHashId(const QString& xpub_hash_id);

    bool lightningEnabled() const;
    void setLightningEnabled(bool enabled);

    Q_INVOKABLE QStringList lightningMnemonic() const;
    LightningSession* lightningSession();
    QJsonObject lightningNodeInfo() const;

    QList<Notification*> getNotifications() const;
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
    void refresh();

signals:
    void walletChanged();
    void deviceChanged();
    void rememberChanged();
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
    void lightningSessionChanged();
    void lightningNodeInfoChanged();

private:
    void releaseLightningSession();
    void updateLightningEnabled(bool was_enabled);
    void updateLightningTransactions(const std::vector<LightningPayment>& payments);

    ContextPrivate* const d_ptr;

public:
    void addTransaction(ContextTransaction* transaction);
    void removeTransaction(ContextTransaction* transaction);
    QStandardItemModel* transactionModel() const;

    QStandardItemModel* addressModel() const;

    void addCoin(Output* coin);
    QStandardItemModel* coinModel() const;

    QMap<QString, Payment*> m_payments;
    QStandardItemModel* paymentModel() const;

    void addSwap(Swap* swap);
    void removeSwap(Swap* swap);
    std::shared_ptr<lwk::BoltzSession> m_boltz_session;
    QJsonObject m_boltz_swaps_infos;
    QList<Swap*> m_swaps;
};

class ContextManager : public QObject
{
public:
    ContextManager();
    ~ContextManager();
    static ContextManager* instance();
    Context* create(const QString& deployment, bool bip39);
    void exit();
private:
    QList<Context*> m_contexts;
};

#endif // BLOCKSTREAM_CONTEXT_H
