#include "devicediscoveryagent_win.h"

#ifdef Q_OS_WIN

#include <QDebug>
#include <QGuiApplication>
#include <QUuid>
#include <QWindow>

extern "C" {
#include <dbt.h>
#include <hidsdi.h>
#include <setupapi.h>
#include <usb100.h>
#include <usbioctl.h>
#include <usbiodef.h>
#include <windows.h>
#include <winusb.h>
}

#include <hidapi/hidapi.h>

#include "command.h"
#include "devicediscoveryagent.h"
#include "devicemanager.h"
#include "ledgerdevice.h"

DeviceDiscoveryAgentPrivate::DeviceDiscoveryAgentPrivate(DeviceDiscoveryAgent* q)
    : q(q)
{
    QCoreApplication::instance()->installNativeEventFilter(this);

    HWND wnd = (HWND) QGuiApplication::topLevelWindows().at(0)->winId();

    HidD_GetHidGuid(&hid_class_guid);
    searchDevices();

    DEV_BROADCAST_DEVICEINTERFACE notification_filter;
    ZeroMemory(&notification_filter, sizeof(notification_filter));
    notification_filter.dbcc_size = sizeof(DEV_BROADCAST_DEVICEINTERFACE);
    notification_filter.dbcc_devicetype = DBT_DEVTYP_DEVICEINTERFACE;
    m_dev_notify = RegisterDeviceNotification(wnd, &notification_filter, DEVICE_NOTIFY_WINDOW_HANDLE | DEVICE_NOTIFY_ALL_INTERFACE_CLASSES);
    Q_ASSERT(m_dev_notify);
}

bool DeviceDiscoveryAgentPrivate::nativeEventFilter(const QByteArray& eventType, void* message, long* /* result */)
{
    if (eventType != "windows_generic_MSG") return false;

    MSG* msg = static_cast<MSG*>(message);
    if (msg->message != WM_DEVICECHANGE) return false;

    if (msg->wParam == DBT_DEVICEARRIVAL) {
        PDEV_BROADCAST_HDR hdr = (PDEV_BROADCAST_HDR) msg->lParam;
        if (hdr->dbch_devicetype != DBT_DEVTYP_DEVICEINTERFACE) return false;
        PDEV_BROADCAST_DEVICEINTERFACE notification = (PDEV_BROADCAST_DEVICEINTERFACE) msg->lParam;
        if (QUuid(hid_class_guid) != QUuid(notification->dbcc_classguid)) return false;
        auto id = QString::fromWCharArray(notification->dbcc_name).toLower();
        addDevice(id);
    } else if (msg->wParam == DBT_DEVICEREMOVECOMPLETE) {
        PDEV_BROADCAST_HDR hdr = (PDEV_BROADCAST_HDR) msg->lParam;
        if (hdr->dbch_devicetype != DBT_DEVTYP_DEVICEINTERFACE) return false;
        PDEV_BROADCAST_DEVICEINTERFACE notification = (PDEV_BROADCAST_DEVICEINTERFACE) msg->lParam;
        auto id = QString::fromWCharArray(notification->dbcc_name).toLower();
        auto device = m_devices.take(id);
        if (!device) return false;
        DeviceManager::instance()->removeDevice(device->q);
        hid_close(device->dev);
        delete device->q;
    }
    return false;
}

void DeviceDiscoveryAgentPrivate::searchDevices()
{
    hid_device_info* info = hid_enumerate(0, 0);
    for (auto i = info; i; i = i->next) {
        addDevice(i);
    }
    hid_free_enumeration(info);
    return;
}

void DeviceDiscoveryAgentPrivate::addDevice(const QString& id)
{
    hid_device_info* info = hid_enumerate(0, 0);
    for (auto i = info; i; i = i->next) {
        if (QString::fromLocal8Bit(i->path) == id) {
            addDevice(i);
            break;
        }
    }
    hid_free_enumeration(info);
}

void DeviceDiscoveryAgentPrivate::addDevice(hid_device_info* info)
{
    auto type = Device::typefromVendorAndProduct(info->vendor_id, info->product_id);
    if (type == Device::NoType) return;

    hid_device* dev = hid_open_path(info->path);
    if (!dev) return;

    DevicePrivateImpl* impl = new DevicePrivateImpl;
    impl->id = QString::fromLocal8Bit(info->path);
    impl->dev = dev;
    impl->m_type = type;

    m_devices.insert(impl->id, impl);
    auto d = new LedgerDevice(impl, q);

    auto t = new QTimer(d);
    QObject::connect(t, &QTimer::timeout, [impl] {
        char buf[64];
        int ret = hid_read_timeout(impl->dev, (unsigned char*) buf, 64, 0);
        if (ret == 0) return;
        impl->inputReport(QByteArray::fromRawData(buf, 64));
    });
    t->start(10);

    DeviceManager::instance()->addDevice(d);
}

QList<QByteArray> transport(const QByteArray& data) {
    QList<QByteArray> packets;
    int offset = 0;
    while (offset < data.size()) {
        QByteArray result;
        auto d = data.mid(offset, 64 - (packets.empty() ? 7 : 5));
        offset += d.size();
        QDataStream stream(&result, QIODevice::WriteOnly);
        stream << uint16_t(0x0101) << uint8_t(0x05) << uint16_t(packets.size());
        if (packets.empty()) stream << uint16_t(data.length());
        result.append(d);
        Q_ASSERT(result.length() <= 64);
        result = result.leftJustified(64, 0x0);
        packets.append(result);
    }
    return packets;
}

void DevicePrivateImpl::exchange(DeviceCommand *command)
{
    const bool send = queue.empty();
    if (send) {
        const auto payload = command->payload();
        for (const auto& packet : transport(payload)) {
            QByteArray report;
            report.append(uint8_t(0));
            report.append(packet);
            hid_write(dev, (unsigned char*) report.constData(), report.size());
        }
    }
    queue.enqueue(command);
}

void DevicePrivateImpl::inputReport(const QByteArray& data)
{
    if (queue.empty()) {
        // qDebug() << "READ UNKNOWN REPORT" << data.toHex();
        return;
    }
    Q_ASSERT(!queue.empty());
    QDataStream stream(data);
    auto command = queue.head();
    int r = command->readHIDReport(q, stream);
    if (r == 2) return;
    if (r == 1) qWarning("command failed");
    queue.dequeue();
    // qDebug() << "input report done, queue size = " << queue.size();
    if (!queue.empty()) {
        //qDebug() << "sending next command";
        command = queue.head();
        const auto payload = command->payload();
        //qDebug() << "send " << payload.toHex();
        for (const auto& packet : transport(payload)) {
            qDebug() << "send packet " << packet.toHex();
            //auto res = IOHIDDeviceSetReport(handle, kIOHIDReportTypeOutput, 0, (const uint8_t*) packet.constData(), packet.size());
            QByteArray report;
            report.append(uint8_t(0));
            report.append(packet);
            hid_write(dev, (unsigned char*) report.constData(), report.size());
        }
        //qDebug() << "send done";
    }
}

#endif // Q_OS_WIN
