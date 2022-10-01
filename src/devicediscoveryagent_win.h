#ifndef GREEN_DEVICEDISCOVERYAGENT_WIN_H
#define GREEN_DEVICEDISCOVERYAGENT_WIN_H

#include <QtGlobal>

#ifdef Q_OS_WIN
#include <QAbstractNativeEventFilter>
#include <QMap>
#include <QString>

extern "C" {
#include <windows.h>
}

#include <hidapi/hidapi.h>

#include "device_p.h"

class DeviceDiscoveryAgent;
class DevicePrivateImpl : public DevicePrivate
{
public:
    hid_device* dev;
    QString id;
    void exchange(DeviceCommand *command) override;
    void inputReport(const QByteArray& data);
};

class DeviceDiscoveryAgentPrivate : public QAbstractNativeEventFilter
{
public:
    DeviceDiscoveryAgentPrivate(DeviceDiscoveryAgent* q);
    bool nativeEventFilter(const QByteArray& eventType, void* message, long* /* result */) override;
    bool filter(const QString& id);
    void searchDevices();
    void addDevice(const QString& id);
    void addDevice(hid_device_info* info);

private:
    DeviceDiscoveryAgent* const q;
    GUID hid_class_guid;
    HDEVNOTIFY m_dev_notify;
    QMap<QString, DevicePrivateImpl*> m_devices;
};

#endif // Q_OS_WIN

#endif // GREEN_DEVICEDISCOVERYAGENT_WIN_H
