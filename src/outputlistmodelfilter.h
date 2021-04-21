#ifndef GREEN_OUTPUTLISTMODELFILTER_H
#define GREEN_OUTPUTLISTMODELFILTER_H

#include <QSortFilterProxyModel>
#include <QtQml>

QT_FORWARD_DECLARE_CLASS(Output)
QT_FORWARD_DECLARE_CLASS(OutputListModel)

class OutputListModelFilter : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(OutputListModel* model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QStringList tags READ tags CONSTANT)
    QML_ELEMENT
public:
    OutputListModelFilter(QObject* parent = nullptr);

    OutputListModel* model() const { return m_model; }
    void setModel(OutputListModel* model);

    Qt::SortOrder sortOrder();
    void setSortOrder(Qt::SortOrder sortOrder);

    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;
    bool lessThan(const QModelIndex & left, const QModelIndex & right) const;

    Q_INVOKABLE void filterBy(const QString &filter);
    Q_INVOKABLE void clear();

    QStringList tags();

signals:
    void modelChanged(OutputListModel* account);
private:
    OutputListModel* m_model{nullptr};
    QStringList m_tags;
    QString m_filter;
};

#endif // GREEN_OUTPUTLISTMODELFILTER_H
