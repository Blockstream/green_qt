#ifndef GREEN_DEVICE_P_H
#define GREEN_DEVICE_P_H

#include "device.h"

class DevicePrivate
{
public:
    virtual ~DevicePrivate() {};
    virtual void exchange(DeviceCommand* command) = 0;
    Device* q{nullptr};
    Device::Transport m_transport;
    Device::Type m_type;
    int32_t m_unique_id;
    QString app_name;
    QQueue<DeviceCommand*> queue;
};

#endif // GREEN_DEVICE_P_H
