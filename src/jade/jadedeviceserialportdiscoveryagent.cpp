#include "jadedeviceserialportdiscoveryagent.h"

#include <QSerialPortInfo>
#include <QTimer>

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

    // don't filter if vid and pid are unknown, happens with flatpak
    if (info.vendorIdentifier() == 0 && info.productIdentifier() == 0) return false;

    return true;
}

} // namespace

JadeDeviceSerialPortDiscoveryAgent::JadeDeviceSerialPortDiscoveryAgent(QObject* parent)
    : QObject(parent)
{
    auto timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &JadeDeviceSerialPortDiscoveryAgent::scan);
    timer->start(2000);
    scan();
}

void JadeDeviceSerialPortDiscoveryAgent::scan()
{
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

    for (const auto &info : QSerialPortInfo::availablePorts()) {
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
                    connect(device, &JadeDevice::error, [=] {
                        if (m_devices.take(device->systemLocation())) {
                            DeviceManager::instance()->removeDevice(device);
                            device->deleteLater();
                        }
                    });
                });
            });
            connect(api, &JadeAPI::onOpenError, this, [this, device] {
                m_failed_locations.insert(device->systemLocation());
            });
            connect(api, &JadeAPI::onDisconnected, this, [this, device] {
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

    if (devices.empty()) return;

    while (!devices.empty()) {
        const auto system_location = devices.firstKey();
        auto device = devices.take(system_location);
        DeviceManager::instance()->removeDevice(device);
        device->api()->disconnectDevice();
        delete device;
    }
}
