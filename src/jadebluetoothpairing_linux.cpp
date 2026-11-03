#include "jadebluetoothpairing_linux.h"

#ifdef Q_OS_LINUX

#include <QBluetoothLocalDevice>
#include <QDBusConnection>
#include <QDebug>

#include <utility>

static const QString AGENT_PATH = QStringLiteral("/io/blockstream/green/jade/pairing");

static QDBusMessage agentCall(const QString& method)
{
    auto message = QDBusMessage::createMethodCall(QStringLiteral("org.bluez"), QStringLiteral("/org/bluez"), QStringLiteral("org.bluez.AgentManager1"), method);
    message << QVariant::fromValue(QDBusObjectPath(AGENT_PATH));
    return message;
}

JadeBluetoothPairing::JadeBluetoothPairing(const QBluetoothAddress& address, QObject* parent)
    : QObject(parent)
    , m_address(address)
{
    auto bus = QDBusConnection::systemBus();
    if (!bus.registerObject(AGENT_PATH, this, QDBusConnection::ExportAllSlots)) {
        qWarning() << "JadeBluetoothPairing: agent object not registered";
    }
    // BlueZ uses the agent of whoever calls Pair(), looked up by connection,
    // and Qt pairs over this same system bus connection.
    auto message = agentCall(QStringLiteral("RegisterAgent"));
    message << QStringLiteral("DisplayYesNo");
    const auto reply = bus.call(message);
    if (reply.type() == QDBusMessage::ErrorMessage) {
        qWarning() << "JadeBluetoothPairing: agent not registered:" << reply.errorName() << reply.errorMessage();
    }
}

JadeBluetoothPairing::~JadeBluetoothPairing()
{
    release();
}

// The agent goes before finished is emitted, as the object itself is only
// deleted later and the next pairing registers the same path.
void JadeBluetoothPairing::release()
{
    if (std::exchange(m_released, true)) return;
    Cancel();
    auto bus = QDBusConnection::systemBus();
    bus.unregisterObject(AGENT_PATH);
    bus.send(agentCall(QStringLiteral("UnregisterAgent")));
}

void JadeBluetoothPairing::start()
{
    auto local_device = new QBluetoothLocalDevice(this);
    // Reported under the identity address learnt while bonding, which is the
    // one BlueZ knows the device by from then on.
    connect(local_device, &QBluetoothLocalDevice::pairingFinished, this, [this](const QBluetoothAddress& address, QBluetoothLocalDevice::Pairing pairing) {
        qDebug() << "JadeBluetoothPairing: finished" << address << pairing;
        if (m_released) return;
        release();
        emit finished(pairing != QBluetoothLocalDevice::Unpaired, address);
    });
    connect(local_device, &QBluetoothLocalDevice::errorOccurred, this, [this](QBluetoothLocalDevice::Error error) {
        qWarning() << "JadeBluetoothPairing: failed" << error;
        if (m_released) return;
        release();
        emit finished(false, m_address);
    });
    // ponytail: Qt's Pair() call times out at the D-Bus default of 25s, a
    // little under Jade's own 30s; call Device1.Pair() directly with a longer
    // timeout if that window turns out too short.
    local_device->requestPairing(m_address, QBluetoothLocalDevice::Paired);
}

void JadeBluetoothPairing::confirmPin(bool match)
{
    reply(match ? nullptr : "org.bluez.Error.Rejected");
}

void JadeBluetoothPairing::Cancel()
{
    reply("org.bluez.Error.Canceled");
}

void JadeBluetoothPairing::RequestConfirmation(const QDBusObjectPath& device, uint passkey, const QDBusMessage& message)
{
    qDebug() << "JadeBluetoothPairing: confirmation requested for" << device.path();
    message.setDelayedReply(true);
    m_request = message;
    emit pinRequested(QString::number(passkey).rightJustified(6, '0'));
}

void JadeBluetoothPairing::reply(const char* error)
{
    const auto request = std::exchange(m_request, {});
    if (request.type() == QDBusMessage::InvalidMessage) return;
    qDebug() << "JadeBluetoothPairing: code" << (error ? error : "confirmed");
    QDBusConnection::systemBus().send(error ? request.createErrorReply(QString::fromLatin1(error), {}) : request.createReply());
}

#endif // Q_OS_LINUX
