#ifndef GREEN_OUTPUTLISTMODELFILTER_H
#define GREEN_OUTPUTLISTMODELFILTER_H

#include <QSortFilterProxyModel>
#include <QtQml>

class Output;
class OutputListModel;

class OutputListModelFilter : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(OutputListModel* model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    QML_ELEMENT
public:
    OutputListModelFilter(QObject* parent = nullptr);

    OutputListModel* model() const { return m_model; }
    void setModel(OutputListModel* model);

    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool lessThan(const QModelIndex & left, const QModelIndex & right) const override;

    QString filter();
    void setFilter(const QString &filter);

signals:
    void modelChanged(OutputListModel* account);
    void filterChanged(const QString &filter);

private:
    OutputListModel* m_model{nullptr};
    QString m_filter;
};

#endif // GREEN_OUTPUTLISTMODELFILTER_H
