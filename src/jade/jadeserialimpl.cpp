#include <QDebug>
#include <QSerialPort>
#include <QTimer>

#include "jadeserialimpl.h"

JadeSerialImpl::JadeSerialImpl(const QSerialPortInfo &deviceInfo,
                               QObject *parent)
    : JadeConnection(parent),
      m_serial(new QSerialPort(deviceInfo, this)) // take ownership
{
    Q_ASSERT(m_serial);

    // Set expected connection parameters
    m_serial->setBaudRate(QSerialPort::Baud115200);
    m_serial->setDataBits(QSerialPort::Data8);
    m_serial->setParity(QSerialPort::NoParity);
    m_serial->setStopBits(QSerialPort::OneStop);
}

JadeSerialImpl::~JadeSerialImpl()
{
    disconnectDevice();
}

// Manage connection
bool JadeSerialImpl::isConnectedImpl()
{
    Q_ASSERT(m_serial);
    return m_serial->isOpen();
}

void JadeSerialImpl::connectDeviceImpl()
{
    Q_ASSERT(m_serial);
    // qDebug() << "JadeSerialImpl::connectDeviceImpl()";

    // Only try to connect if not already connected
    if (isConnected())
    {
        // qWarning() << "JadeSerialImpl::connectDeviceImpl() already connected - ignoring";
        return;
    }

    // Open the serial port
    if (m_serial->open(QIODevice::ReadWrite))
    {
        // Connect 'data received' slot
        connect(m_serial, &QSerialPort::readyRead,
                this, &JadeSerialImpl::onSerialDataReady);

        // Emit 'onConnected' 1 second later
        QTimer::singleShot(1000, this, [this] {
            emit onConnected();
        });
    }
    else
    {
        // qWarning() << "JadeSerialImpl::connectDeviceImpl() error opening " << m_serial->portName();
        disconnectDevice();
    }
}

void JadeSerialImpl::disconnectDeviceImpl()
{
    Q_ASSERT(m_serial);

    // Always go through disconnection steps (in case of partially connected state)

    // Disconnect from serial device
    disconnect(m_serial, nullptr, this, nullptr);

    // Close port
    if (m_serial->isOpen())
    {
        // qDebug() << "JadeSerialImpl::disconnectDeviceImpl() - closing underlying serial port";
        m_serial->close();
    }

    // Emit 'onDisconnected' immediately
    emit onDisconnected();
}

// Write bytes over serial
int JadeSerialImpl::writeImpl(const QByteArray &data)
{
    Q_ASSERT(m_serial);
    Q_ASSERT(isConnected());

    // qDebug() << "JadeSerialImpl::writeImpl() sending" << data.length() << "bytes";

    int written = 0;
    while (written != data.length()) {
        const qint64 wrote = m_serial->write(data.data() + written, data.length() - written);
        if (wrote == -1) {
            disconnectDevice();
            return written;
        }
        else {
            written += wrote;
        }
    }

    // qDebug() << "JadeSerialImpl::writeImpl() sent" << written << "bytes";
    return written;
}

// 'data received' slot function
void JadeSerialImpl::onSerialDataReady()
{
    Q_ASSERT(m_serial);

    // Fetch all available data from the serial port
    const QByteArray data = m_serial->readAll();
    // qDebug() << "JadeSerialImpl::onSerialDataReady() -" << data.length() << "bytes received";

     // Pass to base class
    JadeConnection::onDataReceived(data);
}
