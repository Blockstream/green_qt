#ifndef DEVICEMANAGERMACOS_H
#define DEVICEMANAGERMACOS_H

#include "devicemanager.h"

#if defined(Q_OS_MAC)

#include <QMap>

#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/hid/IOHIDDevice.h>
#include <IOKit/hid/IOHIDManager.h>

class DeviceMacOs : public Device
{
    Q_OBJECT
public:
    QMap<int32_t, IOHIDDeviceRef> m_handles;
};


class DeviceManagerMacos : public DeviceManager
{
    Q_OBJECT

public:
    explicit DeviceManagerMacos(QObject *parent = nullptr);

    DeviceMacOs* deviceWithHandle(int32_t usage_page, IOHIDDeviceRef handle) const;

    void addDevice(Device* device);
    void removeDevice(Device* device);

private:
    IOHIDManagerRef m_manager;
};

#endif // defined(Q_OS_MAC)

#endif // DEVICEMANAGERMACOS_H
