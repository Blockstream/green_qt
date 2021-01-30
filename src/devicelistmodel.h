#ifndef GREEN_DEVICELISTMODEL_H
#define GREEN_DEVICELISTMODEL_H

#include <QtQml>
#include <QMap>
#include <QSortFilterProxyModel>
#include <QStandardItem>
#include <QStandardItemModel>

#include "device.h"

class DeviceListModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(Device::Vendor vendor READ vendor WRITE setVendor NOTIFY vendorChanged)
    Q_PROPERTY(Device::Type type READ type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(int rowCount READ rowCount NOTIFY rowCountChanged)
    QML_ELEMENT
public:
    DeviceListModel(QObject* parent = nullptr);
    Device::Vendor vendor() const { return m_vendor; }
    void setVendor(Device::Vendor vendor);
    Device::Type type() const { return m_type; }
    void setType(Device::Type type);
private slots:
    void addDevice(Device* device);
    void removeDevice(Device* device);
signals:
    void rowCountChanged();
    void vendorChanged(Device::Vendor vendor);
    void typeChanged(Device::Type type);
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const override;
private:
    QStandardItemModel m_source_model;
    QMap<Device*, QStandardItem*> m_items;
    Device::Vendor m_vendor{Device::NoVendor};
    Device::Type m_type{Device::NoType};
};

#endif // GREEN_DEVICELISTMODEL_H
