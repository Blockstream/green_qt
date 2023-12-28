#ifndef GREEN_SIGNTRANSACTIONCONTROLLER_H
#define GREEN_SIGNTRANSACTIONCONTROLLER_H

#include "green.h"
#include "controller.h"

class SignTransactionController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(QJsonObject transaction READ transaction WRITE setTransaction NOTIFY transactionChanged)
    Q_PROPERTY(QString memo READ memo WRITE setMemo NOTIFY memoChanged)
    QML_ELEMENT
public:
    SignTransactionController(QObject* parent = nullptr);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    QJsonObject transaction() const { return m_transaction; }
    void setTransaction(const QJsonObject& transaction);
    QString memo() const { return m_memo; }
    void setMemo(const QString& memo);
public slots:
    void sign();
signals:
    void accountChanged();
    void transactionChanged();
    void memoChanged();
    void transactionCompleted(Transaction* transaction);
private:
    Account* m_account{nullptr};
    QJsonObject m_transaction;
    QString m_memo;
};

#endif // GREEN_SIGNTRANSACTIONCONTROLLER_H
