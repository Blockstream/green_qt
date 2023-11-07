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

QSet<Device*> DeviceManager::devices() const
{
    return m_devices;
}

Device *DeviceManager::deviceWithId(const QString& id)
{
    // track master xpubs by device id
    for (auto network : NetworkManager::instance()->networks()) {
        for (auto device : m_devices) {
            auto xpub = device->masterPublicKey(network);
            if (xpub.isEmpty()) continue;
            m_xpubs[id].insert(xpub);
        }
    }
    // return device if still available
    for (auto device : m_devices) {
        if (device->uuid() == id) {
            return device;
        }
    }
    // search device for tracked xpubs
    for (auto network : NetworkManager::instance()->networks()) {
        for (auto device : m_devices) {
            auto xpub = device->masterPublicKey(network);
            if (xpub.isEmpty()) continue;
            if (m_xpubs[id].contains(xpub)) return device;
        }
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
