#ifndef GREEN_LOGINWITHPINCONTROLLER_H
#define GREEN_LOGINWITHPINCONTROLLER_H

#include "green.h"
#include "controller.h"

#include <QObject>
#include <QQmlEngine>

class PinLoginController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    Q_PROPERTY(QString pin READ pin WRITE setPin NOTIFY pinChanged)
    QML_ELEMENT

public:
    PinLoginController(QObject* parent = nullptr);

    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);

    QString pin() const { return m_pin; }
    void setPin(const QString& pin);

    void update();
    void login();
    void load();

signals:
    void walletChanged();
    void pinChanged();

    void loginFinished(Wallet* wallet);
    void loginFailed();

private:
    Wallet* m_wallet{nullptr};
    QString m_pin;
};

#endif // GREEN_LOGINWITHPINCONTROLLER_H
