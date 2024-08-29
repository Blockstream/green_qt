#include <QCborMap>
#include <QCborValue>
#include <QDebug>

#include "jadeconnection.h"

JadeConnection::JadeConnection(QObject *parent)
    : QObject(parent)
{
}

JadeConnection::~JadeConnection()
{
}

// Manage connection
bool JadeConnection::isConnected()
{
    return isConnectedImpl();
}

void JadeConnection::connectDevice()
{
    connectDeviceImpl();
}

void JadeConnection::disconnectDevice()
{
    disconnectDeviceImpl();
}

// Send cbor message to Jade
int JadeConnection::send(const QCborMap &msg)
{
    // qDebug() << "JadeConnection::send() called for cbor object of" << msg.size() << "fields";

    if (!isConnected()) {
        // qWarning() << "JadeConnection::send() cannot send to disconnected device";
        return 0;
    }

    // Flatten map to cbor bytes
    const QByteArray bytes = msg.toCborValue().toCbor();

    // Pass to specific transport implementation
    return writeImpl(bytes);
}

void JadeConnection::onDataReceived(const QByteArray &data) {
    m_unparsed.append(data);

    // Try to parse cbor objects from byte buffer until it has no more complete objects
    while (!m_unparsed.isEmpty()) {
        QCborParserError err;
        const QCborValue cbor = QCborValue::fromCbor(m_unparsed, &err);
        // qDebug() << "Read Type:" << cbor.type() << "and error: " << err.error;

        if (err.error == QCborError::EndOfFile) {
            // qDebug() << "CBOR incomplete (" << m_unparsed.length() << " bytes present ) - awaiting more data";
            break;
        } else if (err.error != QCborError::NoError) {
            qWarning() << "Unexpected Error:" << err.error;
            disconnectDevice();
            break;
        }

        // drop parsed data from buffer
        m_unparsed = m_unparsed.mid(err.offset);

        if (cbor.isMap()) {
            const QCborMap msg = cbor.toMap();
            if (msg.contains(QCborValue("log"))) {
                // Print Jade log line immediately
                qDebug() << "JadeLog: " << QString(msg["log"].toByteArray());
            } else {
                // Otherwise publish signal for new response message
                emit onNewMessageReceived(msg);
            }
        } else {
            // Unexpected parse error
            qWarning() << "Unexpected Type:" << cbor.type();
            disconnectDevice();
            break;
        }
    }
}
