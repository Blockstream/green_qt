#ifndef GREEN_ACCOUNTLISTMODEL_H
#define GREEN_ACCOUNTLISTMODEL_H

#include "green.h"

#include <QQmlEngine>
#include <QSet>
#include <QSortFilterProxyModel>
#include <QStandardItemModel>

class AccountListModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context WRITE setContext NOTIFY contextChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    QML_ELEMENT
public:
    explicit AccountListModel(QObject* parent = nullptr);

    Context* context() const { return m_context; }
    void setContext(Context* context);
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    QString filter() const { return m_filter; }
    void setFilter(const QString& filter);
    int count() const { return rowCount(); }

private:
    void update();
signals:
    void contextChanged();
    void filterChanged();
    void countChanged();

private slots:
    void invalidateFilterAndCount();

private:
    Context* m_context{nullptr};
    QStandardItemModel* m_model{nullptr};
    QMap<Account*, QStandardItem*> m_items;
    QString m_filter;
};

#endif // GREEN_ACCOUNTLISTMODEL_H
