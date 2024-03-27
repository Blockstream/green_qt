#ifndef GREEN_DEVICE_P_H
#define GREEN_DEVICE_P_H

#include "device.h"

class LedgerDevice;

class DevicePrivate
{
public:
    virtual ~DevicePrivate() {};
    virtual void exchange(DeviceCommand* command) = 0;
    static DevicePrivate* get(LedgerDevice* device);
    LedgerDevice* q{nullptr};
    Device::Transport m_transport;
    Device::Type m_type;
    int32_t m_unique_id;
    QQueue<DeviceCommand*> queue;
};

#endif // GREEN_DEVICE_P_H
