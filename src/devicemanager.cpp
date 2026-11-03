#include "devicemanager.h"
#include "device.h"
#include "networkmanager.h"

#include <QGuiApplication>
#include <QPermissions>

DeviceManager::DeviceManager(QObject* parent)
    : QObject(parent)
{
}

DeviceManager::~DeviceManager()
{}

DeviceManager* DeviceManager::instance()
{
    static DeviceManager instance;
    return &instance;
}

int DeviceManager::count() const
{
    return m_devices.count();
}

QSet<Device*> DeviceManager::devices() const
{
    return m_devices;
}


void DeviceManager::addDevice(Device* device)
{
    if (m_devices.contains(device)) return;
    m_devices.insert(device);
    emit deviceAdded(device);
    emit countChanged();

    connect(device, &Device::connectedChanged, this, [=, this] {
        if (device->isConnected()) {
            emit deviceConnected(device);
        }
    });
}

void DeviceManager::removeDevice(Device* device)
{
    if (!m_devices.contains(device)) return;
    m_devices.remove(device);
    emit deviceRemoved(device);
    emit countChanged();
}

void DeviceManager::addDiscoveryRequest(QObject* request)
{
    const bool requested = isDiscoveryRequested();
    m_discovery_requests.insert(request);
    if (requested) return;
    emit discoveryRequestedChanged();
    updateBluetoothPermission();
}

void DeviceManager::removeDiscoveryRequest(QObject* request)
{
    if (!m_discovery_requests.remove(request)) return;
    if (!isDiscoveryRequested()) emit discoveryRequestedChanged();
}

DeviceDiscoveryRequest::DeviceDiscoveryRequest(QObject* parent)
    : QObject(parent)
{
}

DeviceDiscoveryRequest::~DeviceDiscoveryRequest()
{
    DeviceManager::instance()->removeDiscoveryRequest(this);
}

// Registered once the active binding has been applied, so a request created
// inactive never asks for discovery, not even for a moment.
void DeviceDiscoveryRequest::componentComplete()
{
    m_complete = true;
    if (m_active) DeviceManager::instance()->addDiscoveryRequest(this);
}

void DeviceDiscoveryRequest::setActive(bool active)
{
    if (m_active == active) return;
    m_active = active;
    if (m_complete) {
        if (m_active) {
            DeviceManager::instance()->addDiscoveryRequest(this);
        } else {
            DeviceManager::instance()->removeDiscoveryRequest(this);
        }
    }
    emit activeChanged();
}

void DeviceManager::updateBluetoothPermission()
{
    if (!m_watching_application_state) {
        // Access can be granted in the system settings while the app is in the
        // background, so check again when it comes back.
        m_watching_application_state = true;
        connect(qApp, &QGuiApplication::applicationStateChanged, this, [this](Qt::ApplicationState state) {
            if (state == Qt::ApplicationActive && isDiscoveryRequested()) updateBluetoothPermission();
        });
    }

    const auto permission = qApp->checkPermission(QBluetoothPermission{});
    setBluetoothPermission(permission);

    // Only asked for once a screen needs to discover devices, as on mobile.
    if (permission == Qt::PermissionStatus::Undetermined) {
        qApp->requestPermission(QBluetoothPermission{}, this, [this](const QPermission& permission) {
            setBluetoothPermission(permission.status());
        });
    }
}

void DeviceManager::setBluetoothPermission(Qt::PermissionStatus permission)
{
    if (m_bluetooth_permission == permission) return;
    m_bluetooth_permission = permission;
    emit bluetoothPermissionChanged();
}

void DeviceManager::setBluetoothScanning(bool bluetooth_scanning)
{
    if (m_bluetooth_scanning == bluetooth_scanning) return;
    m_bluetooth_scanning = bluetooth_scanning;
    emit bluetoothScanningChanged();
}
