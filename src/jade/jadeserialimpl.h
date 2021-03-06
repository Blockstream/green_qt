#ifndef JADESERIALIMPL_H
#define JADESERIALIMPL_H

#include "jadeconnection.h"

QT_FORWARD_DECLARE_CLASS(QSerialPortInfo);
QT_FORWARD_DECLARE_CLASS(QSerialPort);

class JadeSerialImpl : public JadeConnection
{
    Q_OBJECT
public:
    explicit JadeSerialImpl(const QSerialPortInfo& deviceInfo,
                            QObject *parent = nullptr);
    ~JadeSerialImpl();

private slots:
    // Invoked when new serial data arrived
    void onSerialDataReady();

private:
    // Manage connection
    bool isConnectedImpl();
    void connectDeviceImpl();
    void disconnectDeviceImpl();

    // Called by derived implmentation to write bytes to underlying transport
    int writeImpl(const QByteArray& data);

    // Underlying connection - lifetime managed by QObject hierarchy
    QSerialPort *m_serial;
};

#endif // JADESERIALIMPL_H
