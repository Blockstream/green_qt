#ifndef GREEN_DEVICE_P_H
#define GREEN_DEVICE_P_H

#include "device.h"

class DevicePrivate
{
public:
    virtual ~DevicePrivate() {};
    virtual void exchange(DeviceCommand* command) = 0;
    Device* q{nullptr};
    Device::Type type;
    QString app_name;
    QQueue<DeviceCommand*> queue;
};

#endif // GREEN_DEVICE_P_H
