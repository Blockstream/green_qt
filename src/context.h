#ifndef GREEN_CONTEXT_H
#define GREEN_CONTEXT_H

#include "green.h"

#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>

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

    QList<Network*> getActiveNetworks() const { return m_sessions.keys(); }
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
    void removeNotification(Notification* notification);

    Q_INVOKABLE Network* primaryNetwork();
    Q_INVOKABLE QString getDisplayUnit(const QString& unit);

    void loadNetwork(TaskGroup* group, Network* network);

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
    void notificationAdded(Notification* notification);
    void notificationRemoved(Notification* notification);
    void notificationsChanged();
    void notificationTriggered(Notification* notification);
    void xpubHashIdChanged();

private:
    const QString m_deployment;
    const bool m_bip39;
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

public:
    QMap<QString, Asset*> m_assets;
    QList<Account*> m_accounts;
    QMap<QPair<Network*, quint32>, Account*> m_accounts_by_pointer;

    TaskDispatcher* const m_dispatcher;

    QJsonObject m_hw_device;
};

#endif // GREEN_CONTEXT_H
