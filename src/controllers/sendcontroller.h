#ifndef GREEN_SENDCONTROLLER_H
#define GREEN_SENDCONTROLLER_H

#include "green.h"

#include "accountcontroller.h"

class CreateTransactionTask;
class GetUnspentOutputsTask;

class SendController : public AccountController
{
    Q_OBJECT
    Q_PROPERTY(Asset* asset READ asset WRITE setAsset NOTIFY assetChanged)
    Q_PROPERTY(bool valid READ isValid NOTIFY changed)
    Q_PROPERTY(Balance* balance READ balance WRITE setBalance NOTIFY changed)
    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY changed)
    Q_PROPERTY(bool sendAll READ sendAll WRITE setSendAll NOTIFY changed)
    Q_PROPERTY(QString amount READ amount WRITE setAmount NOTIFY changed)
    Q_PROPERTY(QString effectiveAmount READ effectiveAmount NOTIFY changed)
    Q_PROPERTY(QString fiatAmount READ fiatAmount WRITE setFiatAmount NOTIFY changed)
    Q_PROPERTY(QString effectiveFiatAmount READ effectiveFiatAmount NOTIFY changed)
    Q_PROPERTY(QString memo READ memo WRITE setMemo NOTIFY changed)
    Q_PROPERTY(int feeRate READ feeRate WRITE setFeeRate NOTIFY changed)
    Q_PROPERTY(bool manualCoinSelection READ manualCoinSelection WRITE setManualCoinSelection NOTIFY changed)
    Q_PROPERTY(QJsonObject utxos READ utxos WRITE setUtxos NOTIFY utxosChanged)
    Q_PROPERTY(bool hasFiatRate READ hasFiatRate NOTIFY changed)
    Q_PROPERTY(QJsonObject transaction READ transaction NOTIFY transactionChanged)
    Q_PROPERTY(Transaction* signedTransaction READ signedTransaction NOTIFY signedTransactionChanged)
    QML_ELEMENT
public:
    explicit SendController(QObject* parent = nullptr);
    ~SendController();

    Asset* asset() const { return m_asset; }
    void setAsset(Asset* asset);

    bool isValid() const;

    Balance* balance() const;
    void setBalance(Balance* balance);

    QString address() const;
    void setAddress(const QString& address);

    bool sendAll() const;
    void setSendAll(bool send_all);

    QString amount() const { return m_amount; }
    void setAmount(const QString& amount);

    QString effectiveAmount() const { return m_effective_amount; }

    QString fiatAmount() const { return m_fiat_amount; }
    void setFiatAmount(const QString& fiatAmount);

    QString effectiveFiatAmount() const { return m_effective_fiat_amount; }

    QString memo() const;
    void setMemo(const QString& memo);

    qint64 feeRate() const;
    void setFeeRate(qint64 fee_rate);

    bool hasFiatRate() const;

    QJsonObject transaction() const;

    Transaction* signedTransaction() const { return m_signed_transaction; }

    QJsonObject utxos() const { return m_utxos; }
    void setUtxos(const QJsonObject& utxos);

    bool manualCoinSelection() const { return m_manual_coin_selection; }
    void setManualCoinSelection(bool manual_coin_selection);

public slots:
    void parseAndUpdate(const QString& text);
    void signAndSend();

signals:
    void assetChanged();
    void changed();
    void transactionChanged();
    void signedTransactionChanged();

    void utxosChanged(QJsonObject utxos);

private:
    void update();
    void create();
    void setSignedTransaction(Transaction* signed_transaction);

    QJsonObject m_utxos;
    GetUnspentOutputsTask* m_get_unspent_outputs{nullptr};

    bool m_manual_coin_selection;

protected:
    Asset* m_asset{nullptr};
    bool m_valid{false};
    quint64 m_count{0};
    Balance* m_balance{nullptr};
    QString m_address;
    bool m_send_all{false};
    QString m_amount, m_effective_amount;
    QString m_fiat_amount, m_effective_fiat_amount;
    QString m_memo;
    qint64 m_fee_rate{0};
    QJsonObject m_transaction;
    void setValid(bool valid);
    CreateTransactionTask* m_create_task{nullptr};
    Transaction* m_signed_transaction{nullptr};
    QJsonObject m_all_utxos;
};

#endif // GREEN_SENDCONTROLLER_H
