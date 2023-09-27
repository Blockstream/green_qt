#ifndef GREEN_CONTEXT_H
#define GREEN_CONTEXT_H

#include "green.h"

#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>

Q_MOC_INCLUDE("network.h")
Q_MOC_INCLUDE("device.h")
Q_MOC_INCLUDE("session.h")
Q_MOC_INCLUDE("wallet.h")

class Context : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(Device* device READ device NOTIFY deviceChanged)
    Q_PROPERTY(bool locked READ isLocked NOTIFY lockedChanged)
    Q_PROPERTY(QString username READ username NOTIFY usernameChanged)
    Q_PROPERTY(bool watchonly READ isWatchonly NOTIFY watchonlyChanged)
    Q_PROPERTY(QQmlListProperty<Session> sessions READ sessions NOTIFY sessionsChanged)
    Q_PROPERTY(QQmlListProperty<Account> accounts READ accounts NOTIFY accountsChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic NOTIFY mnemonicChanged)
    Q_PROPERTY(bool hasBalance READ hasBalance NOTIFY hasBalanceChanged)
    Q_PROPERTY(TaskDispatcher* dispatcher READ dispatcher CONSTANT)

    QML_ELEMENT

public:
    Context(QObject* parent = nullptr);

    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);

    Session* getOrCreateSession(Network* network);

    Device* device() const { return m_device; }
    void setDevice(Device* device);

    QJsonObject credentials() const { return m_credentials; }
    void setCredentials(const QJsonObject& credentials);

    QStringList mnemonic() const { return m_mnemonic; }
    void setMnemonic(const QStringList& mnemonic);

    bool isLocked() const { return m_locked; }
    void setLocked(bool locked);

    QString username() const { return m_username; }
    void setUsername(const QString& username);

    bool isWatchonly() const { return m_watchonly; }
    void setWatchonly(bool watchonly);

    bool hasBalance() const;

    QQmlListProperty<Session> sessions();
    QQmlListProperty<Account> accounts();

    Q_INVOKABLE Asset* getOrCreateAsset(const QString& id);
    Account* getOrCreateAccount(Network* network, const QJsonObject& data);
    Account* getAccountByPointer(Network* network, int pointer) const;

    QString m_wallet_hash_id;
    QJsonObject m_pin_data;

    void autoLogout();

    TaskDispatcher* dispatcher() const { return m_dispatcher; }

    void refresh();

    void setXPubHashId(const QString& xpub_hash_id);

signals:
    void walletChanged();
    void deviceChanged();
    void credentialsChanged();
    void mnemonicChanged();
    void lockedChanged();
    void accountsChanged();
    void usernameChanged();
    void watchonlyChanged();
    void hasBalanceChanged();
    void sessionsChanged();

private:
    Wallet* m_wallet{nullptr};
    Device* m_device{nullptr};
    QString m_xpub_hash_id;
    QJsonObject m_credentials;
    QStringList m_mnemonic;
    QMap<Network*, Session*> m_sessions;
    QList<Session*> m_sessions_list;
    bool m_locked{false};
    QString m_username;
    bool m_watchonly{false};

public:
    QMap<QString, Asset*> m_assets;
    QList<Account*> m_accounts;
    QMap<QPair<Network*, int>, Account*> m_accounts_by_pointer;

    TaskDispatcher* const m_dispatcher;
};

#endif // GREEN_CONTEXT_H
