#include "devicemanager.h"
#include "device.h"
#include "networkmanager.h"

DeviceManager::DeviceManager(QObject* parent)
    : QObject(parent)
{
}

DeviceManager::~DeviceManager()
{}

DeviceManager* DeviceManager::instance()
{
    static DeviceManager instance;
    return &instance;
}

int DeviceManager::count() const
{
    return m_devices.count();
}

QSet<Device*> DeviceManager::devices() const
{
    return m_devices;
}


Device* DeviceManager::defaultDevice() const
{
    if (m_devices.size() == 1) {
        return m_devices.values().first();
    } else {
        return nullptr;
    }
}

void DeviceManager::addDevice(Device* device)
{
    if (m_devices.contains(device)) return;
    m_devices.insert(device);
    emit deviceAdded(device);
    emit countChanged();

    connect(device, &Device::connectedChanged, this, [=] {
        if (device->isConnected()) {
            emit deviceConnected(device);
        }
    });
}

void DeviceManager::removeDevice(Device* device)
{
    if (!m_devices.contains(device)) return;
    m_devices.remove(device);
    emit deviceRemoved(device);
    emit countChanged();
}
