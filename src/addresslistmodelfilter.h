#ifndef GREEN_ADDRESSLISTMODELFILTER_H
#define GREEN_ADDRESSLISTMODELFILTER_H

#include <QSortFilterProxyModel>
#include <QtQml>

QT_FORWARD_DECLARE_CLASS(Account)
QT_FORWARD_DECLARE_CLASS(AddressListModel)

class AddressListModelFilter : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(AddressListModel* model READ model WRITE setModel NOTIFY modelChanged)
    QML_ELEMENT
public:
    AddressListModelFilter(QObject* parent = nullptr);

    AddressListModel* model() const { return m_model; }
    void setModel(AddressListModel* model);

    Qt::SortOrder sortOrder();
    void setSortOrder(Qt::SortOrder sortOrder);

    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;

    Q_INVOKABLE void search(const QString &search);
    Q_INVOKABLE void clear();

signals:
    void modelChanged(AddressListModel* account);
private:
    AddressListModel* m_model{nullptr};
};

#endif // GREEN_ADDRESSLISTMODELFILTER_H
