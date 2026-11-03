#include "jadebluetoothmonitor.h"

#include <qbluetoothaddress.h>
#include <qbluetoothdevicediscoveryagent.h>
#include <qbluetoothlocaldevice.h>
#include <qbluetoothdeviceinfo.h>
#include <qbluetoothservicediscoveryagent.h>

#include <QTimer>

#include "jadeapi.h"
#include "jadebleimpl.h"

#include "jadedevice.h"
#include "devicemanager.h"

const QUuid JADE_SERVICE_UUID{"6e400001-b5a3-f393-e0a9-e50e24dcca9e"};

JadeBluetoothMonitor::JadeBluetoothMonitor(QObject* parent)
    : QObject(parent)
{
}

JadeBluetoothMonitor::~JadeBluetoothMonitor()
{
    for (auto it = m_devices.cbegin(); it != m_devices.cend(); ++it) {
        JadeDevice* const device = it.value();
        if (!device) continue;
        if (device->bluetoothApi() == it.key()) device->setBluetoothBackend(nullptr);
        if (device->parent() != this) continue;
        DeviceManager::instance()->removeDevice(device);
        delete device;
    }
    qDeleteAll(m_backends);
}

void JadeBluetoothMonitor::setActive(bool active)
{
    if (m_active == active) return;
    m_active = active;
    emit activeChanged();
    update();
}

void JadeBluetoothMonitor::update()
{
    if (m_active) {
        if (!m_device_discovery_agent) {
            m_device_discovery_agent = new QBluetoothDeviceDiscoveryAgent(this);
            m_local_device = new QBluetoothLocalDevice(this);

            m_device_discovery_agent->setLowEnergyDiscoveryTimeout(5000);

            connect(m_device_discovery_agent, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered, this, [=, this](const QBluetoothDeviceInfo& info) {
                if (!info.serviceUuids().contains({JADE_SERVICE_UUID})) return;

                // A device advertises continuously, so this fires repeatedly for
                // one Jade. Connecting again each time leaves several GATT
                // connections competing for the same device, which the platform
                // resolves by dropping them, so the device never gets as far as
                // answering. Keep one backend per device.
                //
                // Keyed by name rather than address: Jade advertises a rotating
                // random address, so the same device arrives here under a new
                // address every rotation and would not match itself. The name
                // carries the last bytes of its EFUSEMAC and is stable.
                const auto key = info.name().isEmpty() ? info.address().toString() : info.name();
                if (m_backends.contains(key)) return;


                // Jade's characteristics need an encrypted link, so the platform
                // starts bonding by itself the first time one is used. Doing that
                // in the middle of service discovery leaves the security exchange
                // racing the GATT traffic and it fails: the bond goes BONDING and
                // straight back to NONE, and nothing is ever received. Ask for the
                // bond up front instead and only open the connection once it is in
                // place.
                // Only where the platform identifies devices by address. CoreBluetooth
                // reports a null address and identifies peripherals by uuid, and it
                // handles pairing itself, so asking for a bond there would request one
                // for 00:00:00:00:00:00 and wait for a result that never arrives.
                const auto address = info.address().toString();
                if (!info.address().isNull()
                    && m_local_device->pairingStatus(info.address()) == QBluetoothLocalDevice::Unpaired) {
                    if (m_pairing.contains(address)) return;
                    m_pairing.insert(address, info);
                    m_local_device->requestPairing(info.address(), QBluetoothLocalDevice::Paired);
                    return;
                }

                connectToDevice(info);
            });
            connect(m_device_discovery_agent, &QBluetoothDeviceDiscoveryAgent::finished, this, &JadeBluetoothMonitor::deviceScanFinished);

            connect(m_local_device, &QBluetoothLocalDevice::pairingFinished, this, [=, this](QBluetoothAddress address, QBluetoothLocalDevice::Pairing pairing) {
                const auto info = m_pairing.take(address.toString());
                if (!info.isValid()) return;
                if (pairing == QBluetoothLocalDevice::Unpaired) {
                    // Left for the next advertisement to retry rather than asking
                    // again straight away, which would loop the system dialog.
                    qWarning() << Q_FUNC_INFO << "pairing failed for" << info.name();
                    return;
                }
                connectToDevice(info);
            });
        }
        // DeviceManager asks for the permission when a screen needs discovery.
        const auto permission = qApp->checkPermission(QBluetoothPermission{});
        if (permission == Qt::PermissionStatus::Granted && !m_device_discovery_agent->isActive()) {
            m_device_discovery_agent->start(QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
        }
    } else if (m_device_discovery_agent) {
        // Only the scan stops. Devices already connected keep their backends, so
        // leaving the screen that looks for devices does not drop them.
        m_device_discovery_agent->stop();
        // A bond asked for while scanning should not open a connection once the
        // screen that wanted it is gone; the next scan asks again if needed.
        m_pairing.clear();
    }
}

void JadeBluetoothMonitor::connectToDevice(const QBluetoothDeviceInfo& info)
{
    const auto key = info.name().isEmpty() ? info.address().toString() : info.name();
    if (m_backends.contains(key)) return;

    auto backend = new JadeAPI(info, this);
    m_backends.insert(key, backend);
    backend->connectDevice();

    connect(backend, &JadeAPI::onConnected, this, [=, this] {
        probe(backend);
    });

    connect(backend, &JadeAPI::onDisconnected, this, [=, this] {
        // Drop the entry so the device can be picked up again the next time it is
        // advertised.
        m_backends.remove(key);
        JadeDevice* const device = m_devices.take(backend);
        if (device && device->bluetoothApi() == backend) {
            device->setBluetoothBackend(nullptr);
            device->setConnected(device->api());
            if (!device->api() && device->parent() == this) {
                DeviceManager::instance()->removeDevice(device);
                device->deleteLater();
            }
        }
        backend->deleteLater();
    });
}

void JadeBluetoothMonitor::deviceScanFinished()
{
    // The agent stops itself after lowEnergyDiscoveryTimeout, so without starting
    // it again a Jade that is powered on later never reaches deviceDiscovered and
    // goes unnoticed until something else calls update(). Restarting keeps the
    // scan window open; discovery itself stays event driven, this does not poll
    // any device.
    if (m_active && m_device_discovery_agent && !m_device_discovery_agent->isActive()) {
        m_device_discovery_agent->start(QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
    }
}

void JadeBluetoothMonitor::probe(QPointer<JadeAPI> backend)
{
    // The retry timers outlive the backend, which onDisconnected destroys.
    if (!backend) return;

    if (backend->m_locked) {
        QTimer::singleShot(2000, this, [=, this] { probe(backend); });
        return;
    }

    // Leave the device alone while it is used over USB.
    JadeDevice* const known = m_devices.value(backend);
    if (known && known->api() != backend) {
        QTimer::singleShot(1000, this, [=, this] { probe(backend); });
        return;
    }

    backend->getVersionInfo(true, this, [=, this](const QVariantMap& data) {
        if (data.contains("result")) {
            const auto version_info = data.value("result").toMap();
            const auto efusemac = version_info.value("EFUSEMAC").toString();

            JadeDevice* device = m_devices.value(backend);
            if (!device) {
                for (auto a_device : DeviceManager::instance()->devices()) {
                    auto jade_device = qobject_cast<JadeDevice*>(a_device);
                    if (!jade_device) continue;
                    if (efusemac != jade_device->versionInfo().value("EFUSEMAC").toString()) continue;
                    device = jade_device;
                    break;
                }
                if (!device) device = new JadeDevice(this);
                m_devices.insert(backend, device);
                DeviceManager::instance()->addDevice(device);
            }
            device->setBluetoothBackend(backend);
            if (device->api() == backend) {
                device->setVersionInfo(version_info);
                device->setConnected(true);
            }
        }
        // Kept going through errors too: a request that timed out, as the first
        // one does when its write was refused, is simply sent again.
        QTimer::singleShot(1000, this, [=, this] { probe(backend); });
    });
}
