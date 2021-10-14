#ifndef GREEN_WATCHONLYLOGINCONTROLLER_H
#define GREEN_WATCHONLYLOGINCONTROLLER_H

#include "connectable.h"
#include "entity.h"
#include "wallet.h"

#include <QtQml>
#include <QObject>

class WatchOnlyLoginController : public Entity
{
    Q_OBJECT
    Q_PROPERTY(Session* session READ session NOTIFY sessionChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(Network* network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(bool saveWallet READ saveWallet WRITE setSaveWallet NOTIFY saveWalletChanged)
    Q_PROPERTY(bool valid READ isValid NOTIFY validChanged)
    QML_ELEMENT
public:
    WatchOnlyLoginController(QObject* parent = nullptr);
    Session* session() const { return m_session; }
    Wallet* wallet() const { return m_wallet; }
    Network* network() const { return m_network; }
    void setNetwork(Network* network);
    QString username() const { return m_username; }
    void setUsername(const QString& username);
    QString password() const { return m_password; }
    void setPassword(const QString& password);
    bool saveWallet() const { return m_save_wallet; }
    void setSaveWallet(bool save_wallet);
    bool isValid() const { return m_valid; }
public slots:
    void login();
signals:
    void sessionChanged(Session* session);
    void walletChanged(Wallet* wallet);
    void networkChanged(Network* network);
    void usernameChanged(const QString& username);
    void passwordChanged(const QString& passwod);
    void saveWalletChanged(bool save_wallet);
    void validChanged(bool valid);
    void unauthorized();
private:
    void updateValid();
    void setValid(bool valid);
private:
    Session* m_session{nullptr};
    Connectable<Wallet> m_wallet;
    Network* m_network{nullptr};
    QString m_username;
    QString m_password;
    bool m_save_wallet{false};
    bool m_valid{false};
};

#endif // GREEN_WATCHONLYLOGINCONTROLLER_H
