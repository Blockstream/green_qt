#include "jadebluetoothmonitor.h"

#include <qbluetoothaddress.h>
#include <qbluetoothdevicediscoveryagent.h>
#include <qbluetoothlocaldevice.h>
#include <qbluetoothdeviceinfo.h>
#include <qbluetoothservicediscoveryagent.h>

#include <QSettings>
#include <QTimer>

#include "jadeapi.h"
#include "jadebleimpl.h"
#include "jadebluetoothpairing_linux.h"
#include "jadebluetoothpairing_win.h"

#include "jadedevice.h"
#include "devicemanager.h"
#include "util.h"

const QUuid JADE_SERVICE_UUID{"6e400001-b5a3-f393-e0a9-e50e24dcca9e"};

// CoreBluetooth does not tell whether a device is bonded, so the Jades that
// connected before are remembered by name.
static bool IsKnownJade(const QString& name)
{
    return QSettings(GetDataFile("app", "bluetooth.ini"), QSettings::IniFormat).value("known").toStringList().contains(name);
}

static void RememberJade(const QString& name)
{
    QSettings settings(GetDataFile("app", "bluetooth.ini"), QSettings::IniFormat);
    auto known = settings.value("known").toStringList();
    if (known.contains(name)) return;
    known.append(name);
    settings.setValue("known", known);
}

JadeBluetoothMonitor::JadeBluetoothMonitor(QObject* parent)
    : QObject(parent)
{
    m_clock.start();
    DeviceManager::instance()->checkBluetoothPermission();
    // The scan stops with an error while Bluetooth is off, so it is started
    // again once it is back on. Adverts seen before are stale by then.
    connect(DeviceManager::instance(), &DeviceManager::bluetoothStateChanged, this, [this] {
        if (!m_active && !m_watching) return;
        if (DeviceManager::instance()->isBluetoothEnabled()) return update();
        DeviceManager::instance()->setBluetoothScanning(false);
        // A bond in flight is aborted without a result, so forget it or no
        // other can be asked for.
        cancelPairing();
        dropListedDevices();
    });
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
    dropListedDevices();
    DeviceManager::instance()->setBluetoothScanning(false);
}

void JadeBluetoothMonitor::setActive(bool active)
{
    if (m_active == active) return;
    m_active = active;
    emit activeChanged();
    if (!m_active) {
        // The Jades in range were seen by the screen that is gone, so watching
        // does not announce them again.
        for (const auto& name : m_adverts.keys()) m_announced.insert(name);
        const auto seen = m_seen;
        // Devices already connected keep their backends, so leaving the screen
        // that looks for devices does not drop them. Connections still being
        // opened were for that screen, and go with it.
        for (auto it = m_backends.begin(); it != m_backends.end();) {
            if (m_devices.contains(it.value())) {
                ++it;
                continue;
            }
            delete it.value();
            it = m_backends.erase(it);
        }
        // A bond asked for while scanning should not open a connection once the
        // screen that wanted it is gone; the next scan asks again if needed.
        cancelPairing();
        dropListedDevices();
        // Kept to tell when an announced Jade stops advertising.
        m_seen = seen;
    }
    update();
}

void JadeBluetoothMonitor::setWatching(bool watching)
{
    if (m_watching == watching) return;
    m_watching = watching;
    emit watchingChanged();
    update();
}

// ponytail: watching scans nonstop on the home screen; duty cycle it in
// deviceScanFinished if the battery cost shows.
void JadeBluetoothMonitor::update()
{
    if (m_active || m_watching) {
        // An invalid local device stays invalid once an adapter is back.
        if (m_local_device && !m_local_device->isValid()) {
            delete std::exchange(m_device_discovery_agent, nullptr);
            delete std::exchange(m_local_device, nullptr);
        }
        if (!m_device_discovery_agent) {
            m_device_discovery_agent = new QBluetoothDeviceDiscoveryAgent(this);
            m_local_device = new QBluetoothLocalDevice(this);

            m_device_discovery_agent->setLowEnergyDiscoveryTimeout(5000);

            connect(m_device_discovery_agent, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered, this, [=, this](const QBluetoothDeviceInfo& info) {
                if (!info.serviceUuids().contains({JADE_SERVICE_UUID})) return;
                // Windows also reports bonded devices from its cache, with no RSSI,
                // whether or not they are in range. Only an advert proves it is.
                if (info.rssi() == 0) return;
                // Keyed by the name, which the first advert may not carry yet.
                if (info.name().isEmpty()) return;

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
                const auto key = info.name();
                if (m_backends.contains(key)) return;

                // Jade's characteristics need an encrypted link, so the platform
                // starts bonding by itself the first time one is used. Doing that
                // in the middle of service discovery leaves the security exchange
                // racing the GATT traffic and it fails: the bond goes BONDING and
                // straight back to NONE, and nothing is ever received. Ask for the
                // bond up front instead and only open the connection once it is in
                // place.
                // Only where the platform identifies devices by address. CoreBluetooth
                // reports a null address and pairs by itself on the first encrypted
                // access, so connecting to an unknown Jade there would prompt the
                // user to pair it unasked.
                const auto address = info.address().toString();
                const auto pairing = !info.address().isNull() ? m_local_device->pairingStatus(info.address())
                    : IsKnownJade(key) ? QBluetoothLocalDevice::Paired : QBluetoothLocalDevice::Unpaired;
                qDebug() << Q_FUNC_INFO << "discovered" << info.name() << address << info.deviceUuid() << "rssi" << info.rssi() << pairing;
                m_adverts.insert(key, info);
                m_seen.insert(key, m_clock.elapsed());
                // Only listed for a screen to open, without connecting: Jade takes a
                // single connection, which may be another host's.
                if (!m_active) {
                    if (pairing == QBluetoothLocalDevice::Unpaired || m_announced.contains(key)) return;
                    m_announced.insert(key);
                    listDevice(key)->setBluetoothState(JadeDevice::BluetoothPaired);
                    return;
                }
                JadeDevice* const device = listDevice(key);
                if (pairing == QBluetoothLocalDevice::Unpaired) {
                    // Listed for the user to pair. Asking by itself on every advert
                    // bonded every Jade in range, and under each rotating address.
                    if (device->bluetoothState() == JadeDevice::BluetoothNone) {
                        device->setBluetoothState(JadeDevice::BluetoothUnpaired);
                    }
                    return;
                }

                device->setBluetoothState(JadeDevice::BluetoothPaired);
                connectToDevice(info);
            });
            connect(m_device_discovery_agent, &QBluetoothDeviceDiscoveryAgent::finished, this, &JadeBluetoothMonitor::deviceScanFinished);
            connect(m_device_discovery_agent, &QBluetoothDeviceDiscoveryAgent::errorOccurred, this, [=, this](QBluetoothDeviceDiscoveryAgent::Error error) {
                qWarning() << Q_FUNC_INFO << "discovery error" << error << m_device_discovery_agent->errorString();
                DeviceManager::instance()->setBluetoothScanning(false);
            });

            connect(m_local_device, &QBluetoothLocalDevice::pairingFinished, this, [=, this](QBluetoothAddress address, QBluetoothLocalDevice::Pairing pairing) {
                qDebug() << Q_FUNC_INFO << "pairing finished for" << m_pairing.name() << address << pairing;
                if (!m_pairing.isValid() || m_pairing.address() != address) return;
                finishPairing(pairing != QBluetoothLocalDevice::Unpaired);
            });
            // A failed bond is reported here rather than through pairingFinished,
            // and without the address it was for. Forget the pending request so
            // it can be asked again instead of waiting forever.
            connect(m_local_device, &QBluetoothLocalDevice::errorOccurred, this, [=, this](QBluetoothLocalDevice::Error error) {
                qWarning() << Q_FUNC_INFO << "local device error" << error << "pending pairing" << m_pairing.name() << m_pairing.address();
                if (m_pairing.isValid()) finishPairing(false);
            });
        }
        // DeviceManager asks for the permission when a screen needs discovery.
        const auto permission = qApp->checkPermission(QBluetoothPermission{});
        if (permission == Qt::PermissionStatus::Granted && !m_device_discovery_agent->isActive()) {
            m_device_discovery_agent->start(QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
        }
        DeviceManager::instance()->setBluetoothScanning(m_device_discovery_agent->isActive());
    } else if (m_device_discovery_agent) {
        DeviceManager::instance()->setBluetoothScanning(false);
        m_device_discovery_agent->stop();
        dropListedDevices();
        m_announced.clear();
    }
}

// The entry for a Jade seen advertising, shared with the serial discovery
// through the name, which both derive from the EFUSEMAC.
JadeDevice* JadeBluetoothMonitor::listDevice(const QString& name)
{
    JadeDevice* device = m_listed.value(name);
    if (device) return device;
    for (auto a_device : DeviceManager::instance()->devices()) {
        auto jade_device = qobject_cast<JadeDevice*>(a_device);
        if (!jade_device || jade_device->name() != name) continue;
        device = jade_device;
        break;
    }
    if (!device) {
        qDebug() << Q_FUNC_INFO << "listing" << name;
        device = new JadeDevice(this);
        device->setName(name);
        DeviceManager::instance()->addDevice(device);
    }
    m_listed.insert(name, device);
    connect(device, &JadeDevice::bluetoothPairRequested, this, [=, this] {
        pairDevice(name);
    });
    connect(device, &JadeDevice::bluetoothPairCancelled, this, [=, this] {
        if (m_pairing.name() == name) cancelPairing();
    });
    return device;
}

void JadeBluetoothMonitor::pairDevice(const QString& name)
{
    qDebug() << Q_FUNC_INFO << name;

    // Jade advertises under a new address every few seconds, so asking per
    // address would start several bonds for the same device.
    if (m_pairing.isValid()) return;
    const auto info = m_adverts.value(name);
    JadeDevice* const device = m_listed.value(name);
    if (!info.isValid() || !device) return;
    device->setBluetoothState(JadeDevice::BluetoothPairing);
    qDebug() << Q_FUNC_INFO << "requesting pairing for" << info.name() << info.address().toString();
    // CoreBluetooth asks the user to pair once the connection is used.
    if (info.address().isNull()) return connectToDevice(info);
    m_pairing = info;
#if defined(Q_OS_WIN) || defined(Q_OS_LINUX)
    const QPointer<JadeDevice> listed(device);
    auto pairing = new JadeBluetoothPairing(info.address(), this);
    m_pairing_request = pairing;
    connect(pairing, &JadeBluetoothPairing::finished, pairing, &QObject::deleteLater);
    connect(pairing, &JadeBluetoothPairing::pinRequested, this, [=, this](const QString& pin) {
        if (!listed || m_pairing.address() != info.address()) return;
        listed->setBluetoothPin(pin);
        listed->setBluetoothState(JadeDevice::BluetoothConfirmingPin);
    });
    connect(device, &JadeDevice::bluetoothPinConfirmed, pairing, &JadeBluetoothPairing::confirmPin);
    connect(pairing, &JadeBluetoothPairing::finished, this, [=, this](bool paired, const QBluetoothAddress& address) {
        if (listed) listed->setBluetoothPin({});
        if (m_pairing.address() != info.address()) return;
        // BlueZ resolves the advert address to the identity one while bonding
        // and only knows the device by that afterwards.
        if (paired && address != info.address()) {
            m_pairing = QBluetoothDeviceInfo(address, info.name(), 0);
            m_pairing.setCoreConfigurations(info.coreConfigurations());
        }
        finishPairing(paired);
    });
    pairing->start();
#else
    m_local_device->requestPairing(info.address(), QBluetoothLocalDevice::Paired);
#endif
}

void JadeBluetoothMonitor::finishPairing(bool paired)
{
    const auto info = std::exchange(m_pairing, {});
    JadeDevice* const device = m_listed.value(info.name());
    if (!paired) {
        // Left for the user to ask again rather than retrying straight away,
        // which would loop the system dialog.
        qWarning() << Q_FUNC_INFO << "pairing failed for" << info.name();
        if (device) device->setBluetoothState(JadeDevice::BluetoothUnpaired);
        return;
    }
    qDebug() << Q_FUNC_INFO << "paired" << info.name() << info.address().toString() << "status" << m_local_device->pairingStatus(info.address());
    if (device) device->setBluetoothState(JadeDevice::BluetoothPaired);
    connectToDevice(info);
}

// Abandoned without a result, which would otherwise block pairing another Jade.
// ponytail: on Linux a bond still before its code keeps going in BlueZ; call
// Device1.CancelPairing if that turns out to matter.
void JadeBluetoothMonitor::cancelPairing()
{
    const auto info = std::exchange(m_pairing, {});
    delete m_pairing_request;
    JadeDevice* const device = m_listed.value(info.name());
    if (!device) return;
    device->setBluetoothPin({});
    device->setBluetoothState(JadeDevice::BluetoothUnpaired);
}

// Once the scan stops the adverts are stale, so the entries that exist only
// because of them go, and the rest no longer claim to be in range.
void JadeBluetoothMonitor::dropListedDevices()
{
    for (const auto& name : m_listed.keys()) dropListedDevice(name);
    m_adverts.clear();
    m_seen.clear();
}

void JadeBluetoothMonitor::dropListedDevice(const QString& name)
{
    m_adverts.remove(name);
    m_seen.remove(name);
    JadeDevice* const device = m_listed.take(name);
    if (!device) return;
    disconnect(device, nullptr, this, nullptr);
    device->setBluetoothState(JadeDevice::BluetoothNone);
    if (device->isConnected() || device->api() || device->parent() != this) return;
    qDebug() << Q_FUNC_INFO << "dropping" << name;
    DeviceManager::instance()->removeDevice(device);
    device->deleteLater();
}

void JadeBluetoothMonitor::connectToDevice(const QBluetoothDeviceInfo& info)
{
    const auto key = info.name();
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
        // The connection asked for on CoreBluetooth did not get as far as a probe.
        JadeDevice* const listed = m_listed.value(key);
        if (listed && listed->bluetoothState() == JadeDevice::BluetoothPairing) {
            listed->setBluetoothState(JadeDevice::BluetoothUnpaired);
        }
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
    // A Jade that is switched off just stops advertising. BlueZ keeps reporting
    // it from its cache for a while, so on Linux this only starts after that.
    const qint64 stale_ms = 10000;
    for (const auto& name : m_listed.keys()) {
        if (m_backends.contains(name) || m_pairing.name() == name) continue;
        if (m_clock.elapsed() - m_seen.value(name) > stale_ms) dropListedDevice(name);
    }
    for (auto it = m_announced.begin(); it != m_announced.end();) {
        if (m_clock.elapsed() - m_seen.value(*it) > stale_ms) it = m_announced.erase(it);
        else ++it;
    }

    // The agent stops itself after lowEnergyDiscoveryTimeout, so without starting
    // it again a Jade that is powered on later never reaches deviceDiscovered and
    // goes unnoticed until something else calls update(). Restarting keeps the
    // scan window open; discovery itself stays event driven, this does not poll
    // any device.
    if ((m_active || m_watching) && m_device_discovery_agent && !m_device_discovery_agent->isActive()) {
        m_device_discovery_agent->start(QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
    }
    DeviceManager::instance()->setBluetoothScanning(m_device_discovery_agent->isActive());
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
                device = listDevice(JadeDevice::nameForEfusemac(efusemac));
                m_devices.insert(backend, device);
                RememberJade(device->name());
                if (device->bluetoothState() == JadeDevice::BluetoothPairing) {
                    device->setBluetoothState(JadeDevice::BluetoothPaired);
                }
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
