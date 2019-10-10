#include "devicemanager.h"
#include "devices/device.h"

DeviceManager::DeviceManager(QObject *parent) : QObject(parent)
{

}

QQmlListProperty<Device> DeviceManager::devices()
{
    return QQmlListProperty<Device>(this, &m_devices,
        [](QQmlListProperty<Device>* property) { return static_cast<QVector<Device*>*>(property->data)->size(); },
        [](QQmlListProperty<Device>* property, int index) { return static_cast<QVector<Device*>*>(property->data)->at(index); });
}

Device *DeviceManager::findDevice(const QString &id) const {
    for (auto device : m_devices) {
        if (device->id() == id) return device;
    }
    return nullptr;
}
