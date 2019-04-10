#ifndef TWOFACTORCONTROLLER_H
#define TWOFACTORCONTROLLER_H

#include <QObject>
#include "ga.h"

class Wallet;

class TwoFactorController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)

public:
    explicit TwoFactorController(QObject *parent = nullptr);

    Wallet* wallet() const;
    void setWallet(Wallet* wallet);

private:
    void call();

signals:
    void walletChanged(Wallet* wallet);
    void promptCode();

public slots:
    void go();
    void disable();
    void resolveCode(const QByteArray &code);
    void enableEmail();

private:
    Wallet* m_wallet{nullptr};
    GA_auth_handler* m_call{nullptr};
};

#endif // TWOFACTORCONTROLLER_H
