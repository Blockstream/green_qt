#ifndef GREEN_BALANCE_H
#define GREEN_BALANCE_H

#include <QObject>

class Account;
class Asset;

class Balance : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account CONSTANT)
    Q_PROPERTY(Asset* asset READ asset NOTIFY assetChanged)
    Q_PROPERTY(qint64 amount READ amount NOTIFY changed)
    Q_PROPERTY(QString displayAmount READ displayAmount NOTIFY changed)
    Q_PROPERTY(QString inputAmount READ inputAmount NOTIFY changed)

public:
    explicit Balance(Account* account);

    Account* account() const { return m_account; }

    Asset* asset() const { return m_asset; }
    void setAsset(Asset* asset);

    qint64 amount() const { return m_amount; }
    void setAmount(qint64 amount);

    QString displayAmount() const;
    QString inputAmount() const;

signals:
    void assetChanged(Asset* asset);
    void changed();

private:
    Account* const m_account;
    Asset* m_asset{nullptr};
    qint64 m_amount{0};
};

#endif // GREEN_BALANCE_H
