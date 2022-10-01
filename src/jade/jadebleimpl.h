#ifndef JADEBLEIMPL_H
#define JADEBLEIMPL_H

#include <qlowenergycharacteristic.h>
#include <qlowenergyservice.h>

#include "jadeconnection.h"

QT_FORWARD_DECLARE_CLASS(QLowEnergyController);
QT_FORWARD_DECLARE_CLASS(QBluetoothDeviceInfo);

class JadeBleImpl : public JadeConnection
{
    Q_OBJECT
public:
    explicit JadeBleImpl(const QBluetoothDeviceInfo &deviceInfo,
                         QObject *parent = nullptr);
    ~JadeBleImpl();

private slots:
    // Private slots used during connection/disconnection
    void onServiceStateChange(const QLowEnergyService::ServiceState newState);
    void onDeviceDisconnection();

    // Invoked when new ble data arrived
    void onBleDataReady(const QLowEnergyCharacteristic &info,
                        const QByteArray &data);

private:
    // Manage connection
    bool isConnectedImpl();
    void connectDeviceImpl();
    void disconnectDeviceImpl();

    // Called by derived implmentation to write bytes to underlying transport
    int writeImpl(const QByteArray& data);

    // Underlying connection - lifetime managed by QObject hierarchy
    QLowEnergyController        *m_controller;
    QLowEnergyService           *m_service;
    QLowEnergyCharacteristic    m_tx;
    QLowEnergyCharacteristic    m_rx;
};

#endif // JADEBLEIMPL_H
