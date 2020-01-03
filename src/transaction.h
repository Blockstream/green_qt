#ifndef GREEN_TRANSACTION_H
#define GREEN_TRANSACTION_H

#include <QObject>
#include <QJsonObject>

class Account;

class Transaction : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account CONSTANT)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)

public:
    explicit Transaction(Account* account);
    virtual ~Transaction();

    bool isUnconfirmed() const;

    Account* account() const;

    QJsonObject data() const;

    void updateFromData(const QJsonObject& data);

public slots:
    void copyTxhashToClipboard() const;
    void openInExplorer() const;
    void updateMemo(const QString& memo);

signals:
    void dataChanged(const QJsonObject& data);

private:
    Account* const m_account;
    QJsonObject m_data;
};

#endif // GREEN_TRANSACTION_H
