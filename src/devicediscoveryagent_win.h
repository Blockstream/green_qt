#ifndef GREEN_DEVICEDISCOVERYAGENT_WIN_H
#define GREEN_DEVICEDISCOVERYAGENT_WIN_H

#include <QtGlobal>

#ifdef Q_OS_WIN
#include "device_p.h"

#include <QAbstractNativeEventFilter>
#include <QMap>
#include <QString>

extern "C" {
#include <windows.h>
}

class DevicePrivateImpl : public DevicePrivate
{
public:
    QString id;
    HANDLE handle;
    OVERLAPPED ol;
    bool reading{false};
    char buf[65];
    // udev_device* handle;
    // int fd;
    void exchange(Command* command) override;
    void inputReport(const QByteArray& data);
};

class DeviceDiscoveryAgentPrivate : public QAbstractNativeEventFilter
{
public:
    DeviceDiscoveryAgentPrivate();
    bool nativeEventFilter(const QByteArray& eventType, void* message, long* /* result */) override;
    bool filter(const QString& id);
    void searchDevices();
    void addDevice(const QString& id);
    void addDevice(const QString& id, HANDLE handle);

private:
    GUID hid_class_guid;
    HDEVNOTIFY m_dev_notify;
    QMap<QString, DevicePrivateImpl*> m_devices;
};

#endif // Q_OS_WIN

#endif // GREEN_DEVICEDISCOVERYAGENT_WIN_H
