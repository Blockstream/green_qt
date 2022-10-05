#include "jadebleimpl.h"

#include <QDebug>

#include <qbluetoothdeviceinfo.h>
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
    return m_service && m_service->state() == QLowEnergyService::ServiceDiscovered;
}

void JadeBleImpl::connectDeviceImpl()
{
    Q_ASSERT(m_controller);
    qDebug() << "JadeBleImpl::connectDeviceImpl()";

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
                qDebug() << "JadeBleImpl::connectDeviceImpl()::lambda - Service discovery complete.  Looking for Jade service...";
                for (const QBluetoothUuid& serviceId : m_controller->services())
                {
                    if (serviceId == IO_SERVICE_UUID)
                    {
                        // Jade service found - initiate discovering characteristics
                        m_service = m_controller->createServiceObject(serviceId, this);  // take ownership
                        if (m_service)
                        {
                            qDebug() << "JadeBleImpl::connectDeviceImpl()::lambda - Found Jade service, discovering service details";

                            // This could be received at any time
                            connect(m_service, QOverload<QLowEnergyService::ServiceError>::of(&QLowEnergyService::error),
                                    this, [this](const QLowEnergyService::ServiceError error)
                                    {
                                        qWarning() << "JadeBleImpl::lambda - error from the Jade service - disconnecting:" << error;
                                        disconnectDevice();
                                    });

                            // Connect slot for characteristic discovery and initiate that process
                            connect(m_service, &QLowEnergyService::stateChanged,
                                    this, &JadeBleImpl::onServiceStateChange);
                            m_service->discoverDetails();
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


    // These could be received at any time
    connect(m_controller, QOverload<QLowEnergyController::Error>::of(&QLowEnergyController::error),
            this, [this](const QLowEnergyController::Error error)
            {
                qWarning() << "JadeBleImpl::lambda - error from the controller - disconnecting:" << error;
                disconnectDevice();
            });

    connect(m_controller, &QLowEnergyController::disconnected,
            this, &JadeBleImpl::onDeviceDisconnection);

    // PublicAddress or RandomAddress ?
    m_controller->setRemoteAddressType(QLowEnergyController::RandomAddress);

    // Initiate connection process (see connected callback waterfall, above)
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

    if (newState != QLowEnergyService::ServiceDiscovered) {
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

    // Need to write the descriptor in order to enable notifications/indications from Jade
    const QLowEnergyDescriptor notification = m_rx.descriptor(QBluetoothUuid::ClientCharacteristicConfiguration);
    m_service->writeDescriptor(notification, QByteArray::fromHex("0100"));

    // Connect 'data received' slot
    connect(m_service, &QLowEnergyService::characteristicChanged,
            this, &JadeBleImpl::onBleDataReady);

    // emit 'onConnected' now we are fully connected and ready to go
    emit onConnected();
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

    qDebug() << "JadeBleImpl::write() sending" << data.length() << "bytes";

    Q_ASSERT(m_tx.isValid());
    m_service->writeCharacteristic(m_tx, data, QLowEnergyService::WriteWithResponse);

    qDebug() << "JadeBleImpl::write() sent" << data.length() << "bytes";
    return data.length();
}

// 'data received' slot function
void JadeBleImpl::onBleDataReady(const QLowEnergyCharacteristic &changed,
                                 const QByteArray &data)
{
    Q_ASSERT(m_controller);
    Q_ASSERT(m_service);

    qDebug() << "onBleDataReady() -" << data.length() << "bytes received";

    // Shouldn't happen, but doesn't hurt to double check and ignore
    if (changed != m_rx)
    {
        qWarning() << "onBleDataReady() received data for unexpected characteristic:" << changed.uuid();
        return;
    }

    // Pass to base class
    JadeConnection::onDataReceived(data);
}
