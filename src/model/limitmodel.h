#ifndef BLOCKSTREAM_LIMITMODEL_H
#define BLOCKSTREAM_LIMITMODEL_H

#include <QQmlEngine>
#include <QSortFilterProxyModel>

class LimitModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QAbstractItemModel* source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(int limit READ limit WRITE setLimit NOTIFY limitChanged)
    QML_ELEMENT
public:
    LimitModel(QObject* parent = nullptr);
    QAbstractItemModel* source() const { return m_source; }
    void setSource(QAbstractItemModel* source);
    int limit() const { return m_limit; }
    void setLimit(int limit);
signals:
    void sourceChanged();
    void limitChanged();
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const;
private:
    QAbstractItemModel* m_source{nullptr};
    int m_limit{-1};
};

#endif // BLOCKSTREAM_LIMITMODEL_H
