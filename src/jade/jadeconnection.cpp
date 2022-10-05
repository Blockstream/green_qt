#include <QCborMap>
#include <QCborValue>
#include <QDebug>

#include "jadeconnection.h"

JadeConnection::JadeConnection(QObject *parent)
    : QObject(parent),
      m_unparsed()
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
        qWarning() << "JadeConnection::send() cannot send to disconnected device";
        return 0;
    }

    // Flatten map to cbor bytes
    const QByteArray bytes = msg.toCborValue().toCbor();

    // Pass to specific transport implementation
    return writeImpl(bytes);
}

void JadeConnection::onDataReceived(const QByteArray &data) {
    // qDebug() << "JadeConnection::onDataReceived() -" << data.length() << "bytes received";

    try {
        // Collect data
        m_unparsed.append(data);

        // Try to parse cbor objects from byte buffer until it has no more complete objects
        for (bool readNextObj = true; readNextObj; /*nothing - set in loop*/) {
            QCborParserError err;
            const QCborValue cbor = QCborValue::fromCbor(m_unparsed, &err);
            // qDebug() << "Read Type:" << cbor.type() << "and error: " << err.error;
            readNextObj = false;  // In most cases we don't read another object

            if (err.error == QCborError::NoError && cbor.isMap()) {
                const QCborMap msg = cbor.toMap();
                if (msg.contains(QCborValue("log"))) {
                    // Print Jade log line immediately
                    qDebug() << "JadeLog: " << QString(msg["log"].toByteArray());
                } else {
                    // Otherwise publish signal for new response message
                    emit onNewMessageReceived(msg);
                }

                // Remove read object from m_data buffer
                if (err.offset == m_unparsed.length()) {
                    m_unparsed.clear();
                } else {
                    // We successfully read an object and there are still bytes left in the buffer - this
                    // is the one case where we loop and read again - make sure to preserve the remaining bytes.
                    m_unparsed = m_unparsed.right(static_cast<int>(m_unparsed.length() - err.offset));
                    readNextObj = true;
                }
            } else if (err.error == QCborError::EndOfFile) {
                // partial object - stop trying to read objects for now, await more data
                if (m_unparsed.length() > 0) {
                    qDebug() << "CBOR incomplete (" << m_unparsed.length() << " bytes present ) - awaiting more data";
                }
            } else {
                // Unexpected parse error
                qWarning() << "Unexpected Type:" << cbor.type() << "and/or error: " << err.error;
                disconnectDevice();
            }
        }

    } catch (...) {
        qWarning() << "JadeConnection::onDataReceived() ERROR";
        disconnectDevice();
    }
}
