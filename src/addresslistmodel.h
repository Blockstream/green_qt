#ifndef GREEN_ADDRESSLISTMODEL_H
#define GREEN_ADDRESSLISTMODEL_H

#include "green.h"

#include <QSortFilterProxyModel>
#include <QStandardItemModel>
#include <QQmlEngine>

class AddressListModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    QML_ELEMENT
public:
    AddressListModel(QObject* parent = nullptr);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    QString filter() const { return m_filter; }
    void setFilter(const QString& filter);
    void fetchMore(const QModelIndex &parent) override;
    bool canFetchMore(const QModelIndex &parent) const override;
public slots:
    void update();
protected:
    void load(int last_pointer, bool head);
    bool lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const override;
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const override;
signals:
    void accountChanged();
    void filterChanged();
private:
    Account* m_account{nullptr};
    QStandardItemModel* m_model{nullptr};
    QMap<Address*, QStandardItem*> m_items;
    QString m_filter;
    int m_last_pointer{0};
    QSet<int> m_loaded;
};

#endif // GREEN_ADDRESSLISTMODEL_H
