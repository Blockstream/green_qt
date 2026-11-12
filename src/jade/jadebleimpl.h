#ifndef JADEBLEIMPL_H
#define JADEBLEIMPL_H

#include <QQueue>
#include <qlowenergycharacteristic.h>
#include <qlowenergyservice.h>

#include "jadeconnection.h"

class QLowEnergyController;
class QBluetoothDeviceInfo;

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
    void writeNextChunk();

    // Underlying connection - lifetime managed by QObject hierarchy
    QLowEnergyController        *m_controller;
    QLowEnergyService           *m_service;
    QLowEnergyCharacteristic    m_tx;
    QLowEnergyCharacteristic    m_rx;
    // Writes refused while the platform is still setting up link encryption are
    // retried rather than dropping the connection, until Jade first replies.
    int                         m_write_retries{0};
    QQueue<QByteArray>          m_chunks;
    bool                        m_writing{false};
    bool                        m_replied{false};
    bool                        m_ready{false};
    int                         m_mtu{-1};
};

#endif // JADEBLEIMPL_H
