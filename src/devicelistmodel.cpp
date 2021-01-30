#include "device.h"
#include "devicelistmodel.h"
#include "devicemanager.h"

DeviceListModel::DeviceListModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    connect(this, &QSortFilterProxyModel::rowsInserted, this, &DeviceListModel::rowCountChanged);
    connect(this, &QSortFilterProxyModel::rowsRemoved, this, &DeviceListModel::rowCountChanged);

    connect(DeviceManager::instance(), &DeviceManager::deviceAdded, this, &DeviceListModel::addDevice);
    connect(DeviceManager::instance(), &DeviceManager::deviceRemoved, this, &DeviceListModel::removeDevice);

    for (auto device : DeviceManager::instance()->devices()) {
        addDevice(device);
    }

    m_source_model.setItemRoleNames({{ Qt::UserRole, "device" }});
    setSourceModel(&m_source_model);
    setDynamicSortFilter(true);
    sort(0);
}

void DeviceListModel::setVendor(Device::Vendor vendor)
{
    if (m_vendor == vendor) return;
    m_vendor = vendor;
    emit vendorChanged(m_vendor);
    invalidateFilter();
}

void DeviceListModel::setType(Device::Type type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged(m_type);
    invalidateFilter();
}

void DeviceListModel::addDevice(Device* device)
{
    auto item = new QStandardItem;
    item->setData(QVariant::fromValue(device), Qt::UserRole);
    m_source_model.appendRow(item);
    m_items.insert(device, item);
}

void DeviceListModel::removeDevice(Device* device)
{
    auto item = m_items.take(device);
    m_source_model.takeRow(item->row());
    delete item;
}

bool DeviceListModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    auto device = m_source_model.index(source_row, 0, source_parent).data(Qt::UserRole).value<Device*>();
    if (m_vendor != Device::NoVendor && device->vendor() != m_vendor) return false;
    if (m_type != Device::NoType && device->type() != m_type) return false;
    return true;
}
