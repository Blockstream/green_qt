#ifndef JADECONNECTIONIMPL_H
#define JADECONNECTIONIMPL_H

#include <QByteArray>
#include <QObject>

QT_FORWARD_DECLARE_CLASS(QCborMap);

class JadeConnection : public QObject
{
    Q_OBJECT
public:
    explicit JadeConnection(QObject *parent = nullptr);
    ~JadeConnection();

    // Manage connection
    bool isConnected();
    void connectDevice();
    void disconnectDevice();

    // Send cbor message to Jade
    int send(const QCborMap &msg);

protected:
    // Called by derived implmentation when new data arrived
    void onDataReceived(const QByteArray &data);

signals:
    // Signal emitted when new (complete) cbor message received
    void onNewMessageReceived(const QCborMap &msg);

    // Signals emitted when connection made, attempted, lost, disconnected etc.
    void onOpenError();
    void onConnected();
    void onDisconnected();

private:
    // Manage connection - derived implementations to provide
    virtual bool isConnectedImpl() = 0;
    virtual void connectDeviceImpl() = 0;
    virtual void disconnectDeviceImpl() = 0;

    // Method called to write bytes to underlying transport
    // Derived implmentations to provide.
    virtual int writeImpl(const QByteArray &data) = 0;

    // Unparsed bytes, received from underlying interface but not yet
    // parsed and published as a complete new cbor message received.
    QByteArray  m_unparsed;
};

#endif // JADECONNECTIONIMPL_H
