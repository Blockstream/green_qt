#ifndef GREEN_DEVICEDISCOVERYAGENT_H
#define GREEN_DEVICEDISCOVERYAGENT_H

#include "devicemanager.h"

#include <QDataStream>
#include <QMap>
#include <QQueue>


class DeviceMacOs
{
public:
    QMap<int32_t, IOHIDDeviceRef> m_handles;
};

#endif // GREEN_DEVICEDISCOVERYAGENT_H
