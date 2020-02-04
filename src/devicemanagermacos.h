#ifndef GREEN_DEVICEMANAGERMACOS_H
#define GREEN_DEVICEMANAGERMACOS_H

#include "devicemanager.h"

#include <QMap>

#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/hid/IOHIDDevice.h>
#include <IOKit/hid/IOHIDManager.h>

class DeviceMacOs
{
public:
    QMap<int32_t, IOHIDDeviceRef> m_handles;
};


class DeviceManagerMacos : public DeviceManager
{
    Q_OBJECT

public:
    explicit DeviceManagerMacos();

    DeviceMacOs* deviceWithHandle(int32_t usage_page, IOHIDDeviceRef handle) const;

    void addDevice(Device* device);
    void removeDevice(Device* device);

private:
    IOHIDManagerRef m_manager;
};

#endif // GREEN_DEVICEMANAGERMACOS_H
