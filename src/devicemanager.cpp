#include "devicemanager.h"
#include "device.h"

DeviceManager::DeviceManager(QObject* parent)
    : QObject(parent)
{}

DeviceManager::~DeviceManager()
{}

DeviceManager* DeviceManager::instance()
{
    static DeviceManager instance;
    return &instance;
}

QSet<Device*> DeviceManager::devices() const
{
    return m_devices;
}

Device *DeviceManager::deviceWithId(const QString& id)
{
    for (auto device : m_devices) {
        if (device->uuid() == id) return device;
    }
    return nullptr;
}

void DeviceManager::addDevice(Device* device)
{
    Q_ASSERT(!m_devices.contains(device));
    m_devices.insert(device);
    emit deviceAdded(device);
}

void DeviceManager::removeDevice(Device* device)
{
    if (!m_devices.contains(device)) return;
    m_devices.remove(device);
    emit deviceRemoved(device);
}
