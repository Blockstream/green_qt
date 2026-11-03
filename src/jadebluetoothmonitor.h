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
    JadeDevice* listDevice(const QString& name);
    void pairDevice(const QString& name);
    void finishPairing(bool paired);
    void dropListedDevices();

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
    // The device a bond has been asked for, until pairingFinished or a pairing
    // error arrives. One at a time, since the error does not say which it is for.
    QBluetoothDeviceInfo m_pairing;
    // The WinRT pairing in progress, where that is used instead of the local device.
    QPointer<QObject> m_pairing_request;
    // Jades seen advertising while scanning, by name, listed before they are
    // connected so an unpaired one can be picked. The advert is the latest, as
    // the address rotates.
    QMap<QString, QBluetoothDeviceInfo> m_adverts;
    QMap<QString, QPointer<JadeDevice>> m_listed;
};

#endif // GREEN_JADEBLUETOOTHMONITOR_H
