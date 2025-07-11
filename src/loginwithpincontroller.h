#ifndef GREEN_LOGINWITHPINCONTROLLER_H
#define GREEN_LOGINWITHPINCONTROLLER_H

#include "green.h"
#include "controller.h"

#include <QObject>
#include <QQmlEngine>

class LoginTask;

class LoginController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    Q_PROPERTY(QString passphrase READ passphrase WRITE setPassphrase NOTIFY passphraseChanged)
    QML_ELEMENT
public:
    LoginController(QObject* parent = nullptr);

    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);
    QString passphrase() const { return m_passphrase; }
    void setPassphrase(const QString& passphrase);
    void login(LoginTask* login_task, const QString& passphrase = {});
    void login(TaskGroup *group, LoginTask* login_task);
    void loginNetwork(Network* network);
public slots:
    void loginWithPin(const QString& pin);
    void loginWithDevice(Device* device);
signals:
    void walletChanged();
    void passphraseChanged();
    void invalidPin();
    void loginFinished(Context* context);
    void loginFailed(const QString& error);
private:
    Wallet* m_wallet{nullptr};
    QString m_passphrase;
    QString m_error;
};

class LoadController : public Controller
{
    Q_OBJECT
    QML_ELEMENT
public:
    LoadController(QObject* parent = nullptr);
public slots:
    void load();
signals:
    void loadFinished();
private:
    void loadNetwork(TaskGroup* group, Network* network);
    void loginNetwork(Network* network);
};

class PinDataController : public Controller
{
    Q_OBJECT
    QML_ELEMENT
public:
    PinDataController(QObject * parent = nullptr);
public slots:
    void update(const QString& pin);
signals:
    void updateFailed(const QString& error);
};

#endif // GREEN_LOGINWITHPINCONTROLLER_H
