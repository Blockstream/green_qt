#ifndef GREEN_WATCHONLYLOGINCONTROLLER_H
#define GREEN_WATCHONLYLOGINCONTROLLER_H

#include "green.h"
#include "controller.h"
#include "task.h"

#include <QQmlEngine>
#include <QObject>

class WatchOnlyLoginController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Network* network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(bool saveWallet READ saveWallet WRITE setSaveWallet NOTIFY saveWalletChanged)
    Q_PROPERTY(bool valid READ isValid NOTIFY validChanged)
    QML_ELEMENT
public:
    WatchOnlyLoginController(QObject* parent = nullptr);

    Network* network() const { return m_network; }
    void setNetwork(Network* network);

    QString username() const { return m_username; }
    void setUsername(const QString& username);

    QString password() const { return m_password; }
    void setPassword(const QString& password);

    bool saveWallet() const { return m_save_wallet; }
    void setSaveWallet(bool save_wallet);

    bool isValid() const { return m_valid; }

    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);

public slots:
    void login();
    void load();

signals:
    void networkChanged();
    void usernameChanged();
    void passwordChanged();
    void saveWalletChanged();
    void validChanged();
    void walletChanged();
    void loginFinished(Wallet* wallet);
    void loginFailed();

private:
    void update();
    void setValid(bool valid);

private:
    Network* m_network{nullptr};
    QString m_username;
    QString m_password;
    bool m_save_wallet{false};
    bool m_valid{false};
    Wallet* m_wallet{nullptr};
};

class WatchOnlyCreateWalletTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
public:
    WatchOnlyCreateWalletTask(WatchOnlyLoginController* controller);
    void update() override;
private:
    WatchOnlyLoginController* const m_controller;
};

#endif // GREEN_WATCHONLYLOGINCONTROLLER_H
