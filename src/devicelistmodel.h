#ifndef GREEN_DEVICELISTMODEL_H
#define GREEN_DEVICELISTMODEL_H

#include <QtQml>
#include <QMap>
#include <QSortFilterProxyModel>
#include <QStandardItem>
#include <QStandardItemModel>

class Device;

class DeviceListModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(int rowCount READ rowCount NOTIFY rowCountChanged)
    QML_ELEMENT
public:
    DeviceListModel(QObject* parent = nullptr);
private slots:
    void addDevice(Device* device);
    void removeDevice(Device* device);
signals:
    void rowCountChanged();
private:
    QStandardItemModel m_source_model;
    QMap<Device*, QStandardItem*> m_items;
};

#endif // GREEN_DEVICELISTMODEL_H
