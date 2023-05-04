#include "devicediscoveryagent_linux.h"

#ifdef Q_OS_LINUX

#include <fcntl.h>
#include <linux/hid.h>
#include <linux/hidraw.h>
#include <linux/ioctl.h>
#include <linux/types.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "command.h"
#include "devicemanager.h"
#include "ledgerdevice.h"

DeviceDiscoveryAgentPrivate::DeviceDiscoveryAgentPrivate(DeviceDiscoveryAgent *q)
    : q(q)
{
    m_udev = udev_new();
    Q_ASSERT(m_udev);
    m_monitor = udev_monitor_new_from_netlink(m_udev, "udev");
    Q_ASSERT(m_monitor);
    int res = udev_monitor_filter_add_match_subsystem_devtype(m_monitor, "hidraw", nullptr);
    Q_ASSERT(res >= 0);
    res = udev_monitor_enable_receiving(m_monitor);
    Q_ASSERT(res >= 0);

    m_notifier = new QSocketNotifier(udev_monitor_get_fd(m_monitor), QSocketNotifier::Read);
    m_notifier->setEnabled(true);
    QObject::connect(m_notifier, &QSocketNotifier::activated, [this](int) {
        udev_device* device = udev_monitor_receive_device(m_monitor);
        qDebug() << "monitor: " << udev_device_get_action(device) << udev_device_get_subsystem(device) << udev_device_get_driver(device);

        auto action = udev_device_get_action(device);
        if (action) {
            if (strcmp(action, "add") == 0) addDevice(device);
            if (strcmp(action, "remove") == 0) removeDevice(device);
        }
    });
    auto enumerate = udev_enumerate_new(m_udev);
    udev_enumerate_add_match_subsystem(enumerate, "hidraw");
    udev_enumerate_scan_devices(enumerate);
    auto entry = udev_enumerate_get_list_entry(enumerate);
    while (entry) {
        udev_device* device = udev_device_new_from_syspath(m_udev, udev_list_entry_get_name(entry));
        addDevice(device);
        entry = udev_list_entry_get_next(entry);
    }
    udev_enumerate_unref(enumerate);
}

DeviceDiscoveryAgentPrivate::~DeviceDiscoveryAgentPrivate()
{
    udev_monitor_unref(m_monitor);
    udev_unref(m_udev);
}

static void DumpDevice(udev_device* device)
{
    qDebug("Dump Device");
    while (device) {
        qDebug() << "*" << udev_device_get_subsystem(device) << "devtype=" << udev_device_get_devtype(device) << "driver=" << udev_device_get_driver(device) << udev_device_get_sysattr_value(device, "manufacturer") << udev_device_get_sysattr_value(device, "idVendor") << udev_device_get_sysattr_value(device, "idProduct");
        struct udev_list_entry *e;
        udev_list_entry_foreach(e, udev_device_get_devlinks_list_entry(device)) {
            qDebug() << " ### " << udev_list_entry_get_name(e) << udev_list_entry_get_value(e);
        }
        udev_list_entry_foreach(e, udev_device_get_properties_list_entry(device)) {
            qDebug() << " *** " << udev_list_entry_get_name(e) << udev_list_entry_get_value(e);
        }

        udev_list_entry_foreach(e, udev_device_get_sysattr_list_entry(device)) {
            qDebug() << " >>> " << udev_list_entry_get_name(e) << "=" << udev_list_entry_get_value(e);
        }
        udev_list_entry_foreach(e, udev_device_get_tags_list_entry(device)) {
            qDebug() << " --- " << udev_list_entry_get_name(e) << "=" << udev_list_entry_get_value(e);
        }
        device = udev_device_get_parent(device);
    }
}

static bool GetDevPath(udev_device* handle, QString& devpath)
{
    const char* value = udev_device_get_property_value(handle, "DEVPATH");
    if (!value) return false;
    devpath = QString::fromLocal8Bit(value);
    return true;
}

void DeviceDiscoveryAgentPrivate::addDevice(udev_device* handle)
{
    auto hid_dev = udev_device_get_parent_with_subsystem_devtype(handle, "usb", "usb_device");
    if (!hid_dev) return;


    uint32_t vendor_id = QString::fromLocal8Bit(udev_device_get_sysattr_value(hid_dev, "idVendor")).toUInt(nullptr, 16);
    uint32_t product_id = QString::fromLocal8Bit(udev_device_get_sysattr_value(hid_dev, "idProduct")).toUInt(nullptr, 16);

    Device::Type device_type = Device::typefromVendorAndProduct(vendor_id, product_id);
    if (device_type == Device::NoType) return;

    int fd = open(udev_device_get_devnode(handle), O_RDWR); //|O_NONBLOCK);
    if (fd < 0) return;

#if 1
    /* Get the report descriptor */
    int res, desc_size = 0;
    /* Get Report Descriptor Size */
    res = ioctl(fd, HIDIOCGRDESCSIZE, &desc_size);
    if (res < 0) {
        perror("HIDIOCGRDESCSIZE");
     }

    struct hidraw_report_descriptor rpt_desc;

    memset(&rpt_desc, 0x0, sizeof(rpt_desc));
    /* Get Report Descriptor */
    rpt_desc.size = desc_size;
    res = ioctl(fd, HIDIOCGRDESC, &rpt_desc);
    if (res < 0) {
        perror("HIDIOCGRDESC");
    } else {
        auto bb = QByteArray::fromRawData((const char*) rpt_desc.value, rpt_desc.size);
        qDebug() << "B1=" << uint8_t(bb.at(1)) << "B2=" << uint8_t(bb.at(2)) << uint8_t(0xfa) << uint8_t(0xff);
        if (uint8_t(bb.at(1)) != uint8_t(0xa0) || uint8_t(bb.at(2)) != uint8_t(0xff)) return;

        qDebug() << "REPORT DESCRIPTOR = " << bb.toHex();
        /* Determine if this device uses numbered reports. */
//                dev->uses_numbered_reports =
//                    uses_numbered_reports(rpt_desc.value,
//                                          rpt_desc.size);
    }

#endif
    QString devpath;
    if (!GetDevPath(handle, devpath)) return;

    auto impl = new DevicePrivateImpl;
    impl->handle = handle;
    impl->fd = fd;
    impl->m_type = device_type;
    auto device = new LedgerDevice(impl);

    m_devices.insert(devpath, impl);
    DeviceManager::instance()->addDevice(device);

    auto notifier = new QSocketNotifier(fd, QSocketNotifier::Read);
    notifier->setEnabled(true);
    QObject::connect(notifier, &QSocketNotifier::activated, [impl, fd, notifier] {
        char b[64];
        auto x = read(fd, (void*) b, 64);
        if (x == 64) impl->inputReport(QByteArray::fromRawData(b, 64));
        else notifier->deleteLater();
    });
    // udev_device_unref(handle);
}

void DeviceDiscoveryAgentPrivate::removeDevice(udev_device* handle)
{
    QString devpath;
    if (!GetDevPath(handle, devpath)) return;
    DevicePrivateImpl* impl = m_devices.take(devpath);
    if (!impl) return;
    DeviceManager::instance()->removeDevice(impl->q);
    delete impl->q;
}

QList<QByteArray> transport(const QByteArray& data) {
    QList<QByteArray> packets;
    int offset = 0;
    //qDebug() << "wrapping" << data.toHex();
    while (offset < data.size()) {
        QByteArray result;
        auto d = data.mid(offset, 64 - (packets.empty() ? 7 : 5));
        offset += d.size();
        QDataStream stream(&result, QIODevice::WriteOnly);
        stream << uint16_t(0x0101) << uint8_t(0x05) << uint16_t(packets.size());
        if (packets.empty()) stream << uint16_t(data.length());
        result.append(d);
        //qDebug() << "  packet " << result.toHex() << result.size();
        Q_ASSERT(result.length() <= 64);
        result = result.leftJustified(64, 0x0);
        packets.append(result);
    }
    return packets;
}

void DevicePrivateImpl::exchange(DeviceCommand* command)
{
    const bool send = queue.empty();
    if (send) {
        const auto payload = command->payload();
        for (const auto& packet : transport(payload)) {
            QByteArray report;
            report.append(uint8_t(0));
            report.append(packet);
            int res = write(fd, report.constData(), report.size());
            Q_ASSERT(res == report.size());
        }
    }
    queue.enqueue(command);
}

void DevicePrivateImpl::inputReport(const QByteArray& data)
{
    if (queue.empty()) {
        qDebug() << "READ UNKNOWN REPORT" << data.toHex();
        return;
    }
    Q_ASSERT(!queue.empty());
    QDataStream stream(data);
    auto command = queue.head();
    int r = command->readHIDReport(q, stream);
    if (r == 2) return;
    if (r == 1) qWarning("command failed");
    queue.dequeue();
    if (!queue.empty()) {
        command = queue.head();
        const auto payload = command->payload();
        for (const auto& packet : transport(payload)) {
            QByteArray report;
            report.append(uint8_t(0));
            report.append(packet);
            int res = write(fd, report.constData(), report.size());
            if (res < 0) {
                qDebug() << "FAILED";
                delete command;
                return;
            }
        }
    }
}

#endif // Q_OS_LINUX
