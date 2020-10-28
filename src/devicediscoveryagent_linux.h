#ifndef GREEN_DEVICEDISCOVERYAGENT_LINUX_H
#define GREEN_DEVICEDISCOVERYAGENT_LINUX_H

#include <QtGlobal>

#ifdef Q_OS_LINUX
#include "device_p.h"

#include <QSocketNotifier>
#include <libudev.h>

class DevicePrivateImpl : public DevicePrivate
{
public:
    udev_device* handle;
    int fd;
    void exchange(DeviceCommand* command) override;
    void inputReport(const QByteArray& data);
};

class DeviceDiscoveryAgentPrivate
{
public:
    DeviceDiscoveryAgentPrivate();
    ~DeviceDiscoveryAgentPrivate();

    void addDevice(udev_device* handle);
    void removeDevice(udev_device* handle);

private:
    udev* m_udev{nullptr};
    udev_monitor* m_monitor{nullptr};
    QSocketNotifier* m_notifier{nullptr};
    QMap<QString, DevicePrivateImpl*> m_devices;
};

#endif // Q_OS_LINUX

#endif // GREEN_DEVICEDISCOVERYAGENT_LINUX_H
