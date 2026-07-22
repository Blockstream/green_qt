#ifndef GREEN_CREATETRANSACTIONCONTROLLER_H
#define GREEN_CREATETRANSACTIONCONTROLLER_H

#include "controller.h"
#include "green.h"
#include "recipient.h"

class CreateTransactionController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(Asset* asset READ asset WRITE setAsset NOTIFY assetChanged)
    Q_PROPERTY(AccountTransaction* previousTransaction READ previousTransaction WRITE setPreviousTransaction NOTIFY previousTransactionChanged)
    Q_PROPERTY(QJsonValue utxos READ utxos NOTIFY utxosChanged)
    Q_PROPERTY(Recipient* recipient READ recipient CONSTANT)
    Q_PROPERTY(QVariantList coins READ coins WRITE setCoins NOTIFY coinsChanged)
    Q_PROPERTY(int feeRate READ feeRate WRITE setFeeRate NOTIFY feeRateChanged)
    Q_PROPERTY(QJsonObject transaction READ transaction NOTIFY transactionChanged)
    QML_ELEMENT
public:
    CreateTransactionController(QObject* parent = nullptr);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    Asset* asset() const { return m_asset; }
    void setAsset(Asset* asset);
    AccountTransaction* previousTransaction() const { return m_previous_transaction; }
    void setPreviousTransaction(AccountTransaction* previous_transaction);
    QJsonValue utxos() const { return m_utxos; }
    Recipient* recipient() const { return m_recipient; }
    QVariantList coins() const { return m_coins; }
    void setCoins(const QVariantList& coins);
    int feeRate() const { return m_fee_rate; }
    void setFeeRate(int fee_rate);
    QJsonObject transaction() const { return m_transaction; }
    void setTransaction(const QJsonObject& transaction);
public slots:
    void invalidate();
signals:
    void accountChanged();
    void assetChanged();
    void previousTransactionChanged();
    void utxosChanged();
    void coinsChanged();
    void feeRateChanged();
    void transactionChanged();
protected:
    void update();
    void timerEvent(QTimerEvent* event) override;
private:
    int m_update_timer{-1};
    quint64 m_seq{0};
    Account* m_account{nullptr};
    Asset* m_asset{nullptr};
    AccountTransaction* m_previous_transaction{nullptr};
    Recipient* const m_recipient;
    QVariantList m_coins;
    int m_fee_rate{0};
    QJsonValue m_utxos;
    QJsonObject m_transaction;
};

#endif // GREEN_CREATETRANSACTIONCONTROLLER_H
