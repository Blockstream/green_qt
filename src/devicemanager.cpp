#include "devicemanager.h"
#include "device.h"

DeviceManager::DeviceManager(QObject* parent)
    : QObject(parent)
{}

DeviceManager::~DeviceManager()
{}

DeviceManager* DeviceManager::instance()
{
    return nullptr;
}

QList<Device*> DeviceManager::devices() const
{
    return {};
}
