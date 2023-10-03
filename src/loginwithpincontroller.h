#ifndef GREEN_LOGINWITHPINCONTROLLER_H
#define GREEN_LOGINWITHPINCONTROLLER_H

#include "green.h"
#include "controller.h"

#include <QObject>
#include <QQmlEngine>

class LoginController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    QML_ELEMENT
public:
    LoginController(QObject* parent = nullptr);

    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);

    void update();
    void login();
    void login(TaskGroup *group, Network *network);
    void loginNetwork(Network* network);
public slots:
    void loginWithPin(const QString& pin);
signals:
    void walletChanged();
    void invalidPin();
    void sessionError(const QString& error);
    void loginFinished();
    void loginFailed();

private:
    Wallet* m_wallet{nullptr};
    QString m_pin;
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
    void add(TaskGroup* group);
    void remove(TaskGroup* group);
private:
    QList<TaskGroup*> m_task_groups;
};

#endif // GREEN_LOGINWITHPINCONTROLLER_H
