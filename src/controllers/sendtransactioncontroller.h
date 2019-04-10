#ifndef GREEN_SENDTRANSACTIONCONTROLLER_H
#define GREEN_SENDTRANSACTIONCONTROLLER_H

#include "accountcontroller.h"

class SendTransactionController : public AccountController
{
    Q_OBJECT
    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY addressChanged)
    Q_PROPERTY(qint64 amount READ amount WRITE setAmount NOTIFY amountChanged)

public:
    explicit SendTransactionController(QObject* parent = nullptr);

    QString address() const;
    void setAddress(const QString& address);

    qint64 amount() const;
    void setAmount(qint64 amount);

public slots:
    void send();

signals:
    void addressChanged(const QString& address);
    void amountChanged(qint64 amount);

protected:
    QString m_address;
    qint64 m_amount;
};

#endif // GREEN_SENDTRANSACTIONCONTROLLER_H
