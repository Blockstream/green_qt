#ifndef GREEN_SENDTRANSACTIONCONTROLLER_H
#define GREEN_SENDTRANSACTIONCONTROLLER_H

#include "accountcontroller.h"

class SendTransactionController : public AccountController
{
    Q_OBJECT
    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY addressChanged)
    Q_PROPERTY(QString amount READ amount WRITE setAmount NOTIFY amountChanged)

public:
    explicit SendTransactionController(QObject* parent = nullptr);

    QString address() const;
    void setAddress(const QString& address);

    QString amount() const;
    void setAmount(const QString& amount);

public slots:
    void send();

signals:
    void addressChanged(const QString& address);
    void amountChanged(const QString& amount);

protected:
    QString m_address;
    QString m_amount;
};

#endif // GREEN_SENDTRANSACTIONCONTROLLER_H
