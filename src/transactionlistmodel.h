#ifndef TRANSACTIONLISTMODEL_H
#define TRANSACTIONLISTMODEL_H

#include "account.h"

#include <QtQml>
#include <QAbstractListModel>
#include <QVector>
#include <QModelIndex>

QT_FORWARD_DECLARE_CLASS(Account)
QT_FORWARD_DECLARE_CLASS(Handler)
QT_FORWARD_DECLARE_CLASS(Transaction)

class TransactionListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(bool fetching READ fetching NOTIFY fetchingChanged)
    QML_ELEMENT
public:
    TransactionListModel(QObject* parent = nullptr);
    ~TransactionListModel();

    Account* account() const { return m_account; }
    void setAccount(Account* account);
    bool fetching() const { return m_get_transactions_activity; }

    QHash<int,QByteArray> roleNames() const override;
    void fetchMore(const QModelIndex &parent) override;
    bool canFetchMore(const QModelIndex &parent) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
public slots:
    void reload();
signals:
    void accountChanged(Account* account);
    void fetchingChanged();
private slots:
    void handleNotification(const QJsonObject& notification);
private:
    void fetch(bool reset, int offset, int count);
private:
    Account* m_account{nullptr};
    QVector<Transaction*> m_transactions;
    bool m_has_unconfirmed{false};
    Connectable<AccountGetTransactionsActivity> m_get_transactions_activity;
    QTimer* const m_reload_timer;
};

#endif // TRANSACTIONLISTMODEL_H
