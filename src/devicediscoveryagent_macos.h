#ifndef GREEN_DEVICEDISCOVERYAGENT_MACOS_H
#define GREEN_DEVICEDISCOVERYAGENT_MACOS_H

#include <QtGlobal>

#ifdef Q_OS_MAC
#include "device_p.h"

#include <QMap>

#include <IOKit/hid/IOHIDDevice.h>
#include <IOKit/hid/IOHIDManager.h>

class DeviceDiscoveryAgent;

class DevicePrivateImpl : public DevicePrivate
{
public:
    IOHIDDeviceRef handle;
    //int32_t m_unique_id;
    void exchange(DeviceCommand *command) override;
    void inputReport(const QByteArray& data);
};

class DeviceDiscoveryAgentPrivate
{
public:
    DeviceDiscoveryAgentPrivate(DeviceDiscoveryAgent* q);
    ~DeviceDiscoveryAgentPrivate();
    IOHIDManagerRef m_manager;
    QMap<IOHIDDeviceRef, DevicePrivateImpl*> m_devices;
    DeviceDiscoveryAgent* const q;

    void deviceMaching(IOHIDDeviceRef handle);

    // Track current kIOHIDUniqueIDKey
    QSet<int32_t> m_device_unique_ids;
};

#endif // Q_OS_MAC

#endif // GREEN_DEVICEDISCOVERYAGENT_MACOS_H
