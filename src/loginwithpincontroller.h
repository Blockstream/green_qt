#ifndef GREEN_LOGINWITHPINCONTROLLER_H
#define GREEN_LOGINWITHPINCONTROLLER_H

#include <QObject>
#include <QQmlEngine>

#include "session.h"

class Wallet;

class LoginWithPinController : public Entity
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    Q_PROPERTY(QString pin READ pin WRITE setPin NOTIFY pinChanged)
    QML_ELEMENT
public:
    LoginWithPinController(QObject* parent = nullptr);
    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);
    QString pin() const { return m_pin; }
    void setPin(const QString& pin);
signals:
    void walletChanged(Wallet* wallet);
    void pinChanged();
    void loginDone();
    void loginFailed();
private slots:
    void update();
private:
    Connectable<Wallet> m_wallet;
    Connectable<Session> m_session;
    QString m_pin;
};


#endif // GREEN_LOGINWITHPINCONTROLLER_H
