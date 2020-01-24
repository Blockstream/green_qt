#ifndef GREEN_SENDTRANSACTIONCONTROLLER_H
#define GREEN_SENDTRANSACTIONCONTROLLER_H

#include "accountcontroller.h"

#include <QJsonObject>

class Asset;

class SendTransactionController : public AccountController
{
    Q_OBJECT
    Q_PROPERTY(bool valid READ isValid NOTIFY validChanged)
    Q_PROPERTY(Asset* asset READ asset WRITE setAsset NOTIFY assetChanged)
    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY addressChanged)
    Q_PROPERTY(bool sendAll READ sendAll WRITE setSendAll NOTIFY sendAllChanged)
    Q_PROPERTY(QString amount READ amount WRITE setAmount NOTIFY amountChanged)
    Q_PROPERTY(int feeRate READ feeRate WRITE setFeeRate NOTIFY feeRateChanged)
    Q_PROPERTY(QJsonObject transaction READ transaction NOTIFY transactionChanged)

public:
    explicit SendTransactionController(QObject* parent = nullptr);

    bool isValid() const;

    Asset* asset() const;
    void setAsset(Asset* asset);

    QString address() const;
    void setAddress(const QString& address);

    bool sendAll() const;
    void setSendAll(bool send_all);

    QString amount() const;
    void setAmount(const QString& amount);

    qint64 feeRate() const;
    void setFeeRate(qint64 fee_rate);

    QJsonObject transaction() const;

public slots:
    void send();

signals:
    void validChanged(bool valid);
    void assetChanged(Asset* asset);
    void addressChanged(const QString& address);
    void sendAllChanged(bool send_all);
    void amountChanged(QString amount);
    void feeRateChanged(qint64 fee_rate);
    void transactionChanged();

private:
    void create();

protected:
    bool m_valid{false};
    quint64 m_count{0};
    Asset* m_asset{nullptr};
    QString m_address;
    bool m_send_all{false};
    QString m_amount;
    qint64 m_fee_rate{0};
    QJsonObject m_transaction;

    void setValid(bool valid);
    bool update(const QJsonObject& result) override;
};

#endif // GREEN_SENDTRANSACTIONCONTROLLER_H
