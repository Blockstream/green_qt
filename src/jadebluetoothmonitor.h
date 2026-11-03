#ifndef GREEN_JADEBLUETOOTHMONITOR_H
#define GREEN_JADEBLUETOOTHMONITOR_H

#include <QBluetoothDeviceDiscoveryAgent>
#include <QBluetoothLocalDevice>
#include <QPointer>
#include <QtQml>

#include "jadeapi.h"

class JadeDevice;

class JadeBluetoothMonitor: public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    QML_ELEMENT
public:
    JadeBluetoothMonitor(QObject* parent = nullptr);
    ~JadeBluetoothMonitor();
    bool active() const { return m_active; }
    void setActive(bool active);

protected slots:
    void deviceScanFinished();
    void connectToDevice(const QBluetoothDeviceInfo& info);
    void update();
    void probe(QPointer<JadeAPI> backend);

signals:
    void activeChanged();

private:
    bool m_active{false};
    QBluetoothDeviceDiscoveryAgent* m_device_discovery_agent{nullptr};
    QBluetoothLocalDevice* m_local_device{nullptr};
    QMap<JadeAPI*, QPointer<JadeDevice>> m_devices;
    // Backends by device, so one that keeps advertising while it is already
    // connected is not connected to again. Keyed by name, not address: Jade
    // advertises a rotating random address.
    QMap<QString, JadeAPI*> m_backends;
    // Devices a bond has been asked for, by the address it was asked against,
    // until pairingFinished arrives for it.
    QMap<QString, QBluetoothDeviceInfo> m_pairing;
};

#endif // GREEN_JADEBLUETOOTHMONITOR_H
