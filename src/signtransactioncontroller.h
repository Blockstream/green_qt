#ifndef GREEN_SIGNTRANSACTIONCONTROLLER_H
#define GREEN_SIGNTRANSACTIONCONTROLLER_H

#include "green.h"
#include "controller.h"

class SignTransactionController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(QJsonObject transaction READ transaction WRITE setTransaction NOTIFY transactionChanged)
    QML_ELEMENT
public:
    SignTransactionController(QObject* parent = nullptr);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    QJsonObject transaction() const { return m_transaction; }
    void setTransaction(const QJsonObject& transaction);
public slots:
    void sign();
signals:
    void accountChanged();
    void transactionChanged();
    void transactionCompleted(Transaction* transaction);
private:
    Account* m_account{nullptr};
    QJsonObject m_transaction;
};

#endif // GREEN_SIGNTRANSACTIONCONTROLLER_H
