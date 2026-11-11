#include "jadebleimpl.h"

#include <QBluetoothUuid>
#include <QDebug>
#include <QTimer>

#include <qbluetoothdeviceinfo.h>
#include <qlowenergyconnectionparameters.h>
#include <qlowenergycontroller.h>
#include <qlowenergyservice.h>

static const QUuid IO_SERVICE_UUID("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
static const QUuid IO_TX_CHAR_UUID("6e400002-b5a3-f393-e0a9-e50e24dcca9e");
static const QUuid IO_RX_CHAR_UUID("6e400003-b5a3-f393-e0a9-e50e24dcca9e");

JadeBleImpl::JadeBleImpl(const QBluetoothDeviceInfo &deviceInfo,
                         QObject *parent)
    : JadeConnection(parent),
      m_controller(QLowEnergyController::createCentral(deviceInfo, this)),  // take ownership
      m_service(nullptr),
      m_tx(),
      m_rx()
{
    Q_ASSERT(m_controller);
}

JadeBleImpl::~JadeBleImpl()
{
    qDebug() << "JadeBleImpl::~JadeBleImpl()";
    disconnectDevice();
}

// Manage connection
bool JadeBleImpl::isConnectedImpl() {
    Q_ASSERT(m_controller);
    return m_service && m_service->state() == QLowEnergyService::RemoteServiceDiscovered;
}

void JadeBleImpl::connectDeviceImpl()
{
    Q_ASSERT(m_controller);
    qDebug() << "JadeBleImpl::connectDeviceImpl()" << m_controller->remoteName() << m_controller->remoteAddress() << m_controller->remoteDeviceUuid();

    // Only try to connect if not already connected
    if (isConnected())
    {
        qWarning() << "JadeBleImpl::connectDeviceImpl() already connected - ignoring";
        return;
    }

    // 1. On connection, initiate service discovery
    connect(m_controller, &QLowEnergyController::connected,
            this, [this]()
            {
                qDebug() << "JadeBleImpl::connectDeviceImpl()::lambda - Underlying device connected, initiating service discovery";
                m_controller->discoverServices();
            });

    // 2. On completion of service discovery, look for Jade service and if located initiate discovering characteristics
    connect(m_controller, &QLowEnergyController::discoveryFinished,
            this, [this]()
            {
                qDebug() << "JadeBleImpl::connectDeviceImpl()::lambda - Service discovery complete.  Looking for Jade service..." << m_controller->services();
                for (const QBluetoothUuid& serviceId : m_controller->services())
                {
                    if (serviceId == QBluetoothUuid(IO_SERVICE_UUID))
                    {
                        // Jade service found - initiate discovering characteristics
                        m_service = m_controller->createServiceObject(serviceId, this);  // take ownership
                        if (m_service)
                        {
                            qDebug() << "JadeBleImpl::connectDeviceImpl()::lambda - Found Jade service, discovering service details";

                            // This could be received at any time
                            // TODO
                            connect(m_service, &QLowEnergyService::errorOccurred, this, [=, this](const QLowEnergyService::ServiceError error) {
                                // A write issued before the link is encrypted is
                                // refused: the platform reports "BTM_SetEncryption
                                // busy, enqueue request" and sets encryption up
                                // behind us. Dropping the connection here only
                                // restarts that race, so keep it: the request times
                                // out and its sender asks again over the now
                                // encrypted link.
                                if (error == QLowEnergyService::CharacteristicWriteError && !m_replied && m_write_retries < 5) {
                                    m_write_retries++;
                                    qWarning() << "JadeBleImpl::lambda - write refused before the first reply" << m_write_retries;
                                    return;
                                }
                                qWarning() << "JadeBleImpl::lambda - error from the Jade service - disconnecting:" << error << "replied" << m_replied << "retries" << m_write_retries;
                                disconnectDevice();
                            });

                            // Connect slot for characteristic discovery and initiate that process
                            connect(m_service, &QLowEnergyService::stateChanged,
                                    this, &JadeBleImpl::onServiceStateChange);
                            // Jade's characteristic values are never used, and reading them
                            // on Windows is aborted often enough to drop the connection.
                            // CoreBluetooth skips the descriptors too, which the
                            // subscription below needs.
#ifdef Q_OS_WIN
                            m_service->discoverDetails(QLowEnergyService::SkipValueDiscovery);
#else
                            m_service->discoverDetails();
#endif
                        }
                        else
                        {
                            qWarning() << "JadeBleImpl::connectDeviceImpl()::lambda - failed to create Jade service!";
                        }
                        break;
                    }
                }

                if (!m_service)
                {
                    // Not a Jade device ? Disconnect comlpetely.
                    qWarning() << "JadeBleImpl::connectDeviceImpl()::lambda - cannot find/create Jade service - not a Jade device ?";
                    disconnectDevice();
                }
            });


    connect(m_controller, &QLowEnergyController::errorOccurred,
            this, [this](const QLowEnergyController::Error error)
            {
                qWarning() << "JadeBleImpl::lambda - error from the controller - disconnecting:" << error;
                const auto state = m_controller->state();
                disconnectDevice();
                // The macOS backend drops the link on some errors without ever signalling disconnected
                if (state != QLowEnergyController::UnconnectedState && state != QLowEnergyController::ConnectingState) {
                    onDeviceDisconnection();
                }
            });

    connect(m_controller, &QLowEnergyController::disconnected,
            this, &JadeBleImpl::onDeviceDisconnection);

    connect(m_controller, &QLowEnergyController::stateChanged, this, [](QLowEnergyController::ControllerState state) {
        qDebug() << "JadeBleImpl::lambda - controller state" << state;
    });

    connect(m_controller, &QLowEnergyController::mtuChanged, this, [](int mtu) {
        qDebug() << "JadeBleImpl::lambda - mtu changed" << mtu;
    });

    connect(m_controller, &QLowEnergyController::connectionUpdated, this, [](const QLowEnergyConnectionParameters& parameters) {
        qDebug() << "JadeBleImpl::lambda - connection updated, interval" << parameters.minimumInterval() << parameters.maximumInterval()
                 << "latency" << parameters.latency() << "supervision timeout" << parameters.supervisionTimeout();
    });


    // PublicAddress or RandomAddress ?
    m_controller->setRemoteAddressType(QLowEnergyController::RandomAddress);

    // Initiate connection process (see connected callback waterfall, above)
    m_write_retries = 0;
    m_unconfirmed_writes = 0;
    m_replied = false;
    m_ready = false;
    m_service = nullptr;
    m_controller->connectToDevice();
}

// Slot function called during service detail discovery, on connection
void JadeBleImpl::onServiceStateChange(const QLowEnergyService::ServiceState newState)
{
    Q_ASSERT(m_controller);
    qDebug() << "JadeBleImpl::onServiceStateChange()" << newState;

    // Ignore invocations other than expected service discovered
    const QLowEnergyService *const source = qobject_cast<QLowEnergyService *>(sender());
    if (source != m_service) {
        qWarning() << "JadeBleImpl::onServiceStateChange() ignoring unexpected service:" << source->serviceUuid();
        return;
    }

    if (newState != QLowEnergyService::RemoteServiceDiscovered) {
        qDebug() << "JadeBleImpl::onServiceStateChange() ignoring state:" << newState;
        return;
    }

    // Get the expected Tx and Rx characteristics
    m_tx = m_service->characteristic(IO_TX_CHAR_UUID);
    m_rx = m_service->characteristic(IO_RX_CHAR_UUID);
    if (!m_tx.isValid() || !m_rx.isValid() || !m_rx.properties().testFlag(QLowEnergyCharacteristic::Indicate))
    {
        qWarning() << "JadeBleImpl::onServiceStateChange() charactersistics not as expected:"
                   << m_service->characteristics().length();
        disconnectDevice();
        return;
    }


    // Need to write the descriptor in order to enable notifications/indications from Jade.
    // The value must match the mode the characteristic actually supports: CoreBluetooth
    // ignores it and enables the right one itself, but the Windows backend writes it
    // verbatim and fails with DescriptorWriteError if we ask for notifications on an
    // indicate-only characteristic.
    const QLowEnergyDescriptor notification = m_rx.descriptor(QBluetoothUuid::DescriptorType::ClientCharacteristicConfiguration);
    if (!notification.isValid()) {
        qWarning() << "JadeBleImpl::onServiceStateChange() no client characteristic configuration descriptor";
        disconnectDevice();
        return;
    }

    // Connect 'data received' slot
    connect(m_service, &QLowEnergyService::characteristicChanged,
            this, &JadeBleImpl::onBleDataReady);
    connect(m_service, &QLowEnergyService::characteristicWritten, this, [this] {
        m_unconfirmed_writes--;
    });

    // Jade replies through the subscription this descriptor write sets up, and the
    // write is asynchronous. Prefer to report the connection as ready only once it
    // has been confirmed: otherwise the first request goes out before the
    // subscription exists and the reply is dropped, which on Android leaves the
    // connection silent until it times out.
    //
    // CoreBluetooth enables the subscription itself and need not report the
    // descriptor write at all, so waiting for it there would mean never reporting
    // the connection as ready. Report on whichever comes first, the confirmation
    // or a short timeout, and only once.
    //
    // Connected before the write so a fast confirmation cannot be missed.
    const auto ready = [this] {
        if (m_ready) return;
        m_ready = true;
        // Queued: whoever handles onConnected writes to Jade straight away, and the
        // platform carries one GATT operation at a time. Issuing that write from
        // inside the callback for the descriptor write is refused with
        // CharacteristicWriteError, so let this one finish first.
        QMetaObject::invokeMethod(this, [this] {
            emit onConnected();
        }, Qt::QueuedConnection);
    };

    connect(m_service, &QLowEnergyService::descriptorWritten, this,
            [this, notification, ready](const QLowEnergyDescriptor& descriptor, const QByteArray& value) {
                if (descriptor != notification) return;
                qDebug() << "JadeBleImpl::lambda - notification descriptor written" << value.toHex();
                ready();
            });

    QTimer::singleShot(1000, this, [this, ready] {
        if (m_ready || !isConnected()) return;
        qDebug() << "JadeBleImpl::lambda - notification descriptor write not confirmed, continuing";
        ready();
    });

    const bool indicate = m_rx.properties().testFlag(QLowEnergyCharacteristic::Indicate);
    m_service->writeDescriptor(notification, QByteArray::fromHex(indicate ? "0200" : "0100"));
}

void JadeBleImpl::disconnectDeviceImpl()
{
    Q_ASSERT(m_controller);

    // Always go through disconnection steps (in case of partially connected state)

    // Disconnect from service
    if (m_service)
    {
        qDebug() << "JadeBleImpl::disconnectDeviceImpl() - disconnecting underlying service";
        disconnect(m_service, nullptr, this, nullptr);
        m_service->deleteLater();
        m_service = nullptr;
    }

    // Disconnect from the controller
    m_controller->disconnectFromDevice();

    // If not fully connected the device won't signal disconnection
    // (as it was never connected) so we do so explicitly
    if (m_controller->state() == QLowEnergyController::UnconnectedState
     || m_controller->state() == QLowEnergyController::ConnectingState)
    {
        onDeviceDisconnection();
    }

    // By default, do not emit 'onDisconnected' here - it will be emitted
    // when the underlying device signals its disconnection
}

// Slot function called when the underlying ble controller signals disconnection
void JadeBleImpl::onDeviceDisconnection()
{
    if (m_service)
    {
        // Need to cleanup our state
        qWarning() << "JadeBleImpl::onDeviceDisconnection() - unexpected disconnection from the controller";
        disconnectDevice();
    }

    // Disconnect from controller device
    disconnect(m_controller, nullptr, this, nullptr);

    // In any case emit 'onDisconnected' signal
    emit onDisconnected();
}

// Write bytes over ble characteristics
int JadeBleImpl::writeImpl(const QByteArray &data)
{
    Q_ASSERT(m_controller);
    Q_ASSERT(m_service);
    Q_ASSERT(isConnected());
    Q_ASSERT(m_tx.isValid());


    // A characteristic write cannot exceed the negotiated ATT MTU less the three
    // byte ATT header; anything longer is rejected rather than split up. macOS
    // negotiates a large MTU on connect so a fixed chunk size is never reached
    // there, but Android stays at the 23 byte default unless the peer asks for
    // more, and a single oversized write is silently dropped. The service is a
    // byte stream, so chunking to whatever was negotiated is safe.
    const int mtu = m_controller->mtu();
    const int chunk = mtu > 3 ? mtu - 3 : 20;
    qDebug() << "JadeBleImpl::writeImpl()" << data.length() << "bytes, mtu" << mtu << "unconfirmed writes" << m_unconfirmed_writes;

    auto buffer = data;
    while (!buffer.isEmpty()) {
        auto n = qMin(chunk, buffer.length());
        m_unconfirmed_writes++;
        m_service->writeCharacteristic(m_tx, buffer.mid(0, n), QLowEnergyService::WriteWithResponse);
        buffer = buffer.mid(n);
    }

    return data.length();
}

// 'data received' slot function
void JadeBleImpl::onBleDataReady(const QLowEnergyCharacteristic &changed,
                                 const QByteArray &data)
{
    Q_ASSERT(m_controller);
    Q_ASSERT(m_service);

    // Shouldn't happen, but doesn't hurt to double check and ignore
    if (changed != m_rx)
    {
        qWarning() << "onBleDataReady() received data for unexpected characteristic:" << changed.uuid();
        return;
    }

    m_replied = true;

    // Pass to base class
    JadeConnection::onDataReceived(data);
}
