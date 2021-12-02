#include "jadedeviceserialportdiscoveryagent.h"

#include <QTimer>
#include <QSerialPortInfo>

#include "jadeapi.h"
#include "jadedevice.h"

#include "devicemanager.h"

JadeDeviceSerialPortDiscoveryAgent::JadeDeviceSerialPortDiscoveryAgent(QObject* parent)
    : QObject(parent)
{
    auto timer = new QTimer(this);
    connect(timer, &QTimer::timeout, [this] {
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

            // filter for Silicon Laboratories USB to UART
            if (info.vendorIdentifier() != 0x10c4) continue;
            if (info.productIdentifier() != 0xea60) continue;

            auto device = devices.take(system_location);
            if (!device) {
                auto api = new JadeAPI(info);
                device = new JadeDevice(api, system_location, this);
                api->setParent(device);
                connect(api, &JadeAPI::onConnected, this, [this, device] {
                    device->api()->getVersionInfo([=](const QVariantMap& data) {
                        if (data.contains("error")) {
                            m_devices.remove(device->systemLocation());
                            m_failed_locations.insert(device->systemLocation());
                            delete device;
                            return;
                        }
                        const auto result = data.value("result").toMap();
                        device->setVersionInfo(result);
                        DeviceManager::instance()->addDevice(device);
                        connect(device, &JadeDevice::error, [=] {
                            if (m_devices.take(device->systemLocation())) {
                                DeviceManager::instance()->removeDevice(device);
                                delete device;
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
    });
    timer->start(2000);
}
