#ifndef GREEN_DEVICEDISCOVERYAGENT_MACOS_H
#define GREEN_DEVICEDISCOVERYAGENT_MACOS_H

#include <QtGlobal>

#ifdef Q_OS_MAC
#include "device_p.h"

#include <QMap>

#include <IOKit/hid/IOHIDDevice.h>
#include <IOKit/hid/IOHIDManager.h>

class DevicePrivateImpl : public DevicePrivate
{
public:
    IOHIDDeviceRef handle;
    void exchange(Command* command) override;
    void inputReport(const QByteArray& data);
};

class DeviceDiscoveryAgentPrivate
{
public:
    DeviceDiscoveryAgentPrivate();
    ~DeviceDiscoveryAgentPrivate();
    IOHIDManagerRef m_manager;
    QMap<IOHIDDeviceRef, DevicePrivateImpl*> m_devices;
};

#endif // Q_OS_MAC

#endif // GREEN_DEVICEDISCOVERYAGENT_MACOS_H
