#ifndef GREEN_ADDRESSLISTMODELFILTER_H
#define GREEN_ADDRESSLISTMODELFILTER_H

#include <QSortFilterProxyModel>
#include <QtQml>

class Account;
class AddressListModel;

class AddressListModelFilter : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(AddressListModel* model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    QML_ELEMENT
public:
    AddressListModelFilter(QObject* parent = nullptr);

    AddressListModel* model() const { return m_model; }
    void setModel(AddressListModel* model);

    Qt::SortOrder sortOrder();
    void setSortOrder(Qt::SortOrder sortOrder);

    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;

    QString filter() const { return m_filter; }
    void setFilter(const QString& filter);

signals:
    void modelChanged(AddressListModel* account);
    void filterChanged(const QString& filter);
private:
    AddressListModel* m_model{nullptr};
    QString m_filter;
};

#endif // GREEN_ADDRESSLISTMODELFILTER_H
