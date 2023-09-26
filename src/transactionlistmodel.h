#ifndef TRANSACTIONLISTMODEL_H
#define TRANSACTIONLISTMODEL_H

#include "green.h"

#include <QAbstractListModel>
#include <QModelIndex>
#include <QSortFilterProxyModel>
#include <QtQml>
#include <QVector>

class GetTransactionsTask;

class TransactionListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    QML_ELEMENT
public:
    TransactionListModel(QObject* parent = nullptr);

    Account* account() const { return m_account; }
    void setAccount(Account* account);

    QHash<int,QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
public slots:
    void reload();
signals:
    void accountChanged();
private:
    void handleBlockEvent(const QJsonObject& event);
    void handleTransactionEvent(const QJsonObject& event);
    void fetch(int offset, int count);
private:
    Account* m_account{nullptr};
    GetTransactionsTask* m_get_transactions{nullptr};
    QVector<Transaction*> m_transactions;
    bool m_has_unconfirmed{false};
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
    void modelChanged();
    void filterChanged();
    void maxRowCountChanged();
private:
    int m_max_row_count{-1};
};

#endif // TRANSACTIONLISTMODEL_H
