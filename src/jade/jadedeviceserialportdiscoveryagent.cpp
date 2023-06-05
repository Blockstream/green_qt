#include "jadedeviceserialportdiscoveryagent.h"

#include <QSerialPortInfo>
#include <QTimer>
#include <QtConcurrentRun>

#include "devicemanager.h"
#include "jadeapi.h"
#include "jadedevice.h"

namespace {

bool FilterSerialPort(const QSerialPortInfo& info)
{
    // Silicon Laboratories USB to UART (0x10c4, 0xea60)
    if (info.vendorIdentifier() == 0x10c4 && info.productIdentifier() == 0xea60) return false;

    // WCH CH9102F (0x1a86, 0x55d4)
    if (info.vendorIdentifier() == 0x1a86 && info.productIdentifier() == 0x55d4) return false;

#ifdef Q_OS_LINUX
    // VMware Inc., happens in Debian VM
    if (info.vendorIdentifier() == 0x15ad) return false;

    // don't filter if vid and pid are unknown, happens with flatpak
    if (info.vendorIdentifier() == 0 && info.productIdentifier() == 0) return false;
#endif

    return true;
}

} // namespace

JadeDeviceSerialPortDiscoveryAgent::JadeDeviceSerialPortDiscoveryAgent(QObject* parent)
    : QObject(parent)
{
    scan();
}

void JadeDeviceSerialPortDiscoveryAgent::scan()
{
    using Watcher = QFutureWatcher<QList<QSerialPortInfo>>;
    const auto watcher = new Watcher(this);

    watcher->setFuture(QtConcurrent::run([=] {
        return QSerialPortInfo::availablePorts();
    }));

    connect(watcher, &Watcher::finished, this, [=] {
        auto devices = m_devices;
        m_devices.clear();

        if (m_reset_countdown == 0) {
            m_failed_locations.clear();
            m_reset_countdown = 0;
        } else {
            --m_reset_countdown;
        }

        auto failed_locations = m_failed_locations;
        m_failed_locations.clear();

        for (const auto &info : watcher->result()) {
            const auto system_location = info.systemLocation();
            if (failed_locations.contains(system_location)) {
                m_failed_locations.insert(system_location);
                continue;
            }

            if (FilterSerialPort(info)) continue;

            auto device = devices.take(system_location);
            if (!device) {
                bool relax_write = false;
#ifdef Q_OS_MACOS
                relax_write = system_location.contains("cu.usbmodem");
#endif
                auto api = new JadeAPI(info, relax_write);
                device = new JadeDevice(api, system_location, this);
                api->setParent(device);
                connect(api, &JadeAPI::onConnected, this, [this, device] {
                    device->api()->getVersionInfo([=](const QVariantMap& data) {
                        if (data.contains("error")) {
                            m_devices.remove(device->systemLocation());
                            m_failed_locations.insert(device->systemLocation());
                            device->deleteLater();
                            return;
                        }
                        const auto result = data.value("result").toMap();
                        device->setVersionInfo(result);
                        DeviceManager::instance()->addDevice(device);
                        connect(device, &JadeDevice::error, this, [=] {
                            if (m_devices.take(device->systemLocation())) {
                                DeviceManager::instance()->removeDevice(device);
                                device->deleteLater();
                            }
                        });
                    });
                });
                connect(api, &JadeAPI::onOpenError, this, [=] {
                    m_failed_locations.insert(device->systemLocation());
                });
                connect(api, &JadeAPI::onDisconnected, this, [=] {
                    if (m_devices.take(device->systemLocation())) {
                        DeviceManager::instance()->removeDevice(device);
                        delete device;
                    }
                });
                m_devices.insert(system_location, device);
                api->connectDevice();
            } else if (device->api()->isConnected()) {
                m_devices.insert(system_location, device);
            } else {
                devices.insert(system_location, device);
            }
        }

        while (!devices.empty()) {
            const auto system_location = devices.firstKey();
            auto device = devices.take(system_location);
            DeviceManager::instance()->removeDevice(device);
            device->api()->disconnectDevice();
            delete device;
        }

        QTimer::singleShot(2000, this, &JadeDeviceSerialPortDiscoveryAgent::scan);
    });
}
