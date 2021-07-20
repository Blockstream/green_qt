#ifndef TRANSACTIONLISTMODEL_H
#define TRANSACTIONLISTMODEL_H

#include "account.h"

#include <QtQml>
#include <QAbstractListModel>
#include <QModelIndex>
#include <QSortFilterProxyModel>
#include <QVector>

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
    bool m_reached_end{false};
    Connectable<AccountGetTransactionsActivity> m_get_transactions_activity;
    QTimer* const m_reload_timer;
};

class TransactionFilterProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(TransactionListModel* model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(int maxRowCount READ maxRowCount WRITE setMaxRowCount NOTIFY maxRowCountChanged)
    QML_ELEMENT
    TransactionListModel* m_model{nullptr};
    QString m_filter;

public:
    TransactionFilterProxyModel(QObject* parent = nullptr);
    TransactionListModel* model() const { return m_model; }
    void setModel(TransactionListModel* model);
    QString filter() const { return m_filter; }
    void setFilter(const QString& filter);
    int maxRowCount() const;
    void setMaxRowCount(int max_row_count);
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
signals:
    void modelChanged(TransactionListModel* model);
    void filterChanged(const QString& filter);
    void maxRowCountChanged(int max_row_count);
private:
    int m_max_row_count = {-1};
};

#endif // TRANSACTIONLISTMODEL_H
