#ifndef GREEN_BUMPFEECONTROLLER_H
#define GREEN_BUMPFEECONTROLLER_H

#include "accountcontroller.h"

#include <QtQml>
#include <QJsonObject>

class CreateTransactionHandler;
class Balance;
class Transaction;

class BumpFeeController : public AccountController
{
    Q_OBJECT
    Q_PROPERTY(int feeRate READ feeRate WRITE setFeeRate NOTIFY changed)
    Q_PROPERTY(QJsonObject tx READ tx NOTIFY txChanged)
    Q_PROPERTY(Transaction* transaction READ transaction WRITE setTransaction NOTIFY transactionChanged)
    Q_PROPERTY(Transaction* signedTransaction READ signedTransaction NOTIFY signedTransactionChanged)
    QML_ELEMENT
    QJsonObject m_tx;
    int m_fee_rate{0};
    int m_req{0};
    CreateTransactionHandler* m_create_handler{nullptr};
public:
    BumpFeeController(QObject* parent = nullptr);
    int feeRate() const { return m_fee_rate; }
    void setFeeRate(int feeRate);
    Transaction* transaction() const { return m_transaction; }
    void setTransaction(Transaction* transaction);
    Transaction* signedTransaction() const { return m_signed_transaction; };
    Q_INVOKABLE void bumpFee();
    QJsonObject tx() const { return m_tx; }
private slots:
    void create();
signals:
    void changed();
    void txChanged(const QJsonObject& tx);
    void signedTransactionChanged(Transaction* transaction);
    void transactionChanged(Transaction* transaction);
private:
    Transaction* m_transaction{nullptr};
    void setSignedTransaction(Transaction* signed_transaction);
    Transaction* m_signed_transaction{nullptr};
    QJsonValue m_utxos;
    Handler* m_get_unspent_outputs_handler{nullptr};
};

#endif // GREEN_BUMPFEECONTROLLER_H
