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
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(Device* device READ device NOTIFY deviceChanged)
    Q_PROPERTY(bool remember READ remember NOTIFY rememberChanged)
    Q_PROPERTY(bool locked READ isLocked NOTIFY lockedChanged)
    Q_PROPERTY(bool watchonly READ isWatchonly NOTIFY watchonlyChanged)
    Q_PROPERTY(QQmlListProperty<Session> sessions READ sessions NOTIFY sessionsChanged)
    Q_PROPERTY(Session* primarySession READ primarySession NOTIFY sessionsChanged)
    Q_PROPERTY(QQmlListProperty<Account> accounts READ accounts NOTIFY accountsChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic NOTIFY mnemonicChanged)
    Q_PROPERTY(TaskDispatcher* dispatcher READ dispatcher CONSTANT)
    Q_PROPERTY(QQmlListProperty<Notification> notifications READ notifications NOTIFY notificationsChanged)
    QML_ELEMENT

public:
    Context(QObject* parent = nullptr);
    Context(const QString& deployment, QObject* parent = nullptr);

    QString deployment() const { return m_deployment; }

    TaskGroup* cleanAccounts();

    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);

    Session* getOrCreateSession(Network* network);
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

    bool isLocked() const { return m_locked; }
    void setLocked(bool locked);

    bool isWatchonly() const { return m_watchonly; }
    void setWatchonly(bool watchonly);

    QList<Network*> getActiveNetworks() const { return m_sessions.keys(); }
    QList<Session*> getSessions() const { return m_sessions.values(); }
    QList<Account*> getAccounts() const { return m_accounts; }

    QQmlListProperty<Session> sessions();
    QQmlListProperty<Account> accounts();

    Q_INVOKABLE Asset* getOrCreateAsset(const QString& id);
    Account* getOrCreateAccount(Network* network, quint32 pointer);
    Account* getOrCreateAccount(Network* network, const QJsonObject& data);
    Account* getAccountByPointer(Network* network, int pointer) const;

    QJsonObject m_pin_data;

    TaskDispatcher* dispatcher() const { return m_dispatcher; }

    QString xpubHashId() const { return m_xpub_hash_id; }
    void setXPubHashId(const QString& xpub_hash_id);

    Q_INVOKABLE bool attachToWallet(Wallet* wallet);

    QList<Notification*> getNotifications() const { return m_notifications; }
    QQmlListProperty<Notification> notifications();
    void addNotification(Notification* notification);
    void removeNotification(Notification* notification);

public slots:
    void refreshAccounts();

signals:
    void walletChanged();
    void deviceChanged();
    void rememberChanged();
    void credentialsChanged();
    void mnemonicChanged();
    void lockedChanged();
    void accountsChanged();
    void watchonlyChanged();
    void sessionsChanged();
    void autoLogout();
    void notificationAdded(Notification* notification);
    void notificationRemoved(Notification* notification);
    void notificationsChanged();

private:
    const QString m_deployment;
    Wallet* m_wallet{nullptr};
    Device* m_device{nullptr};
    bool m_remember{true};
    QString m_xpub_hash_id;
    QJsonObject m_credentials;
    QStringList m_mnemonic;
    QMap<Network*, Session*> m_sessions;
    QList<Session*> m_sessions_list;
    bool m_locked{false};
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
