#ifndef GREEN_FEEESTIMATES_H
#define GREEN_FEEESTIMATES_H

#include <QJsonArray>
#include <QObject>
#include <QQmlEngine>
#include <QTimer>

#include "connectable.h"

class Wallet;

class FeeEstimates : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    Q_PROPERTY(QJsonArray fees READ fees NOTIFY feesChanged)
    QML_ELEMENT
public:
    FeeEstimates(QObject* parent = nullptr);
    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);
    QJsonArray fees() const { return m_fees; }
signals:
    void walletChanged();
    void feesChanged();
private slots:
    void update();
private:
    Connectable<Wallet> m_wallet;
    QJsonArray m_fees;
    QTimer m_update_timer;
};

#endif // GREEN_FEEESTIMATES_H
