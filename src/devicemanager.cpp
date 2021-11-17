#include "devicemanager.h"
#include "device.h"

DeviceManager::DeviceManager(QObject* parent)
    : QObject(parent)
{
    auto timer = new QTimer(this);
    connect(timer, &QTimer::timeout, [this] {
        for (auto device : m_devices) {
            device->ping();
        }
    });
    timer->start(5000);
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
    for (auto device : m_devices) {
        if (device->uuid() == id) {
            auto xpub = device->masterPublicKey();
            Q_ASSERT(!xpub.isEmpty());
            m_xpubs[id] = xpub;
            return device;
        }
    }
    auto xpub = m_xpubs[id];
    for (auto device : m_devices) {
        if (device->masterPublicKey() == xpub) {
            m_xpubs[id] = xpub;
            return device;
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
