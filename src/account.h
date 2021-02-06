#ifndef GREEN_ACCOUNT_H
#define GREEN_ACCOUNT_H

#include <QtQml>
#include <QObject>

QT_FORWARD_DECLARE_CLASS(Balance)
QT_FORWARD_DECLARE_CLASS(Transaction)
QT_FORWARD_DECLARE_CLASS(Wallet)

class Account : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(bool mainAccount READ isMainAccount NOTIFY jsonChanged)
    Q_PROPERTY(QJsonObject json READ json NOTIFY jsonChanged)
    Q_PROPERTY(QString name READ name NOTIFY jsonChanged)
    Q_PROPERTY(qint64 balance READ balance NOTIFY balanceChanged)
    Q_PROPERTY(QQmlListProperty<Balance> balances READ balances NOTIFY balancesChanged)
    QML_ELEMENT
public:
    explicit Account(Wallet* wallet);

    Wallet* wallet() const { return m_wallet; }
    int pointer() const { Q_ASSERT(m_pointer >= 0); return m_pointer; }
    bool isMainAccount() const;

    QString name() const;
    QJsonObject json() const;

    void update(const QJsonObject& json);

    void handleNotification(const QJsonObject& notification);

    qint64 balance() const;

    QQmlListProperty<Balance> balances();

    void updateBalance();
    Transaction *getOrCreateTransaction(const QJsonObject &data);
signals:
    void walletChanged();
    void jsonChanged();
    void balanceChanged();
    void balancesChanged();
    void notificationHandled(const QJsonObject& notification);
public slots:
    void reload();
private:
    Wallet* const m_wallet;
    int m_pointer{-1};
    QJsonObject m_json;
    QMap<QString, Transaction*> m_transactions_by_hash;
    QList<Balance*> m_balances;
    QMap<QString, Balance*> m_balance_by_id;
    friend class Wallet;
};

#endif // GREEN_ACCOUNT_H
