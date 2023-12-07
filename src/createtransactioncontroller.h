#ifndef GREEN_CREATETRANSACTIONCONTROLLER_H
#define GREEN_CREATETRANSACTIONCONTROLLER_H

#include "green.h"
#include "controller.h"

class Recipient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Asset* asset READ asset WRITE setAsset NOTIFY assetChanged)
    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY addressChanged)
    Q_PROPERTY(QString amount READ amount WRITE setAmount NOTIFY amountChanged)
    Q_PROPERTY(bool greedy READ isGreedy WRITE setGreedy NOTIFY greedyChanged)
    QML_ELEMENT
public:
    Recipient(QObject* parent = nullptr);
    Asset* asset() const { return m_asset; }
    void setAsset(Asset* asset);
    QString address() const { return m_address; }
    void setAddress(const QString& address);
    QString amount() const { return m_amount; }
    void setAmount(const QString& amount);
    bool isGreedy() const { return m_greedy; }
    void setGreedy(bool greedy);
signals:
    void assetChanged();
    void addressChanged();
    void amountChanged();
    void greedyChanged();
private:
    Asset* m_asset{nullptr};
    QString m_address;
    QString m_amount;
    bool m_greedy{false};
};

class CreateTransactionController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(Asset* asset READ asset WRITE setAsset NOTIFY assetChanged)
    Q_PROPERTY(Recipient* recipient READ recipient CONSTANT)
    Q_PROPERTY(QJsonObject transaction READ transaction NOTIFY transactionChanged)
    QML_ELEMENT
public:
    CreateTransactionController(QObject* parent = nullptr);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    Asset* asset() const { return m_asset; }
    void setAsset(Asset* asset);
    Recipient* recipient() const { return m_recipient; }
    QJsonObject transaction() const { return m_transaction; }
    void setTransaction(const QJsonObject& transaction);
public slots:
    void invalidate();
signals:
    void accountChanged();
    void assetChanged();
    void transactionChanged();
protected:
    void update();
    void timerEvent(QTimerEvent* event) override;
private:
    int m_update_timer;
    Account* m_account{nullptr};
    Asset* m_asset{nullptr};
    Recipient* const m_recipient;
    QJsonValue m_utxos;
    QJsonObject m_transaction;
};

#endif // GREEN_CREATETRANSACTIONCONTROLLER_H
