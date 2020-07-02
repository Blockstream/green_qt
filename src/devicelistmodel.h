#ifndef GREEN_DEVICELISTMODEL_H
#define GREEN_DEVICELISTMODEL_H

#include <QMap>
#include <QSortFilterProxyModel>
#include <QStandardItem>
#include <QStandardItemModel>

class Device;

class DeviceListModel : public QSortFilterProxyModel
{
public:
    DeviceListModel(QObject* parent = nullptr);
private slots:
    void addDevice(Device* device);
    void removeDevice(Device* device);
private:
    QStandardItemModel m_source_model;
    QMap<Device*, QStandardItem*> m_items;
};

#endif // GREEN_DEVICELISTMODEL_H
