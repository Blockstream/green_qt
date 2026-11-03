#ifndef GREEN_DEVICEMANAGER_H
#define GREEN_DEVICEMANAGER_H

#include <QObject>
#include <QSet>
#include <QtQml>
#include <QVector>

class Device;

class DeviceManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool discoveryRequested READ isDiscoveryRequested NOTIFY discoveryRequestedChanged)
    Q_PROPERTY(Qt::PermissionStatus bluetoothPermission READ bluetoothPermission NOTIFY bluetoothPermissionChanged)
public:
    virtual ~DeviceManager();
    static DeviceManager* instance();
    int count() const;
    QSet<Device*> devices() const;
    Q_INVOKABLE Device* defaultDevice() const;
    bool isDiscoveryRequested() const { return !m_discovery_requests.isEmpty(); }
    void addDiscoveryRequest(QObject* request);
    void removeDiscoveryRequest(QObject* request);
    Qt::PermissionStatus bluetoothPermission() const { return m_bluetooth_permission; }
public slots:
    void addDevice(Device* device);
    void removeDevice(Device* device);
signals:
    void countChanged();
    void discoveryRequestedChanged();
    void bluetoothPermissionChanged();
    void deviceAdded(Device* device);
    void deviceRemoved(Device* device);
    void deviceConnected(Device* device);
private:
    explicit DeviceManager(QObject* parent = nullptr);
    void updateBluetoothPermission();
    void setBluetoothPermission(Qt::PermissionStatus permission);
    QSet<Device*> m_devices;
    QMap<QString, QSet<QByteArray>> m_xpubs;
    QSet<QObject*> m_discovery_requests;
    Qt::PermissionStatus m_bluetooth_permission{Qt::PermissionStatus::Undetermined};
    bool m_watching_application_state{false};
};

// Declared by the screens that look for devices, so discovery that has a cost
// (Bluetooth scanning) only runs while one of them is showing
class DeviceDiscoveryRequest : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    QML_ELEMENT
public:
    DeviceDiscoveryRequest(QObject* parent = nullptr);
    ~DeviceDiscoveryRequest();
    bool active() const { return m_active; }
    void setActive(bool active);
    void classBegin() override {}
    void componentComplete() override;
signals:
    void activeChanged();
private:
    bool m_active{true};
    bool m_complete{false};
};

#endif // GREEN_DEVICEMANAGER_H
