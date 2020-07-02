#include "device.h"
#include "devicelistmodel.h"
#include "devicemanager.h"

DeviceListModel::DeviceListModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
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
