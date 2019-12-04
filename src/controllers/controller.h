#ifndef GREEN_CONTROLLER_H
#define GREEN_CONTROLLER_H

#include <QDebug>
#include <QObject>

#include "../ga.h"

class Wallet;
class Account;

class Controller : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject result READ result NOTIFY resultChanged)
    Q_PROPERTY(QString state READ state NOTIFY stateChanged)
    Q_PROPERTY(bool busy READ isBusy NOTIFY busyChanged)
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)

public:
    explicit Controller(QObject* parent = nullptr);

    QJsonObject result() const { return m_result; }
    QString state() const;

    virtual Wallet* wallet() const;
    void setWallet(Wallet* wallet);

    void process(GA_json** output = nullptr);

    bool isBusy() const { return m_busy > 0; }

public slots:
    virtual void reset();
    void cancel();

    void requestCode(const QByteArray& method);
    void resolveCode(const QByteArray& code);

signals:
    void resultChanged(const QJsonObject& result);
    void stateChanged(const QString& state);
    void busyChanged(bool busy);
    void walletChanged(Wallet* wallet);
    void statusChanged(const QString& status);

protected:
    Wallet* m_wallet{nullptr};
    QString m_state;
    GA_auth_handler* m_auth_handler{nullptr};
    QJsonObject m_result;
    int m_busy{0};

    void setState(const QString& state);
    void incrementBusy();
    void decrementBusy();
};

#endif // GREEN_CONTROLLER_H
