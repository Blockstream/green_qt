#include "device.h"

#include <wally_wrapper.h>

#include "command.h"
#include "network.h"

QByteArray pathToData(const QVector<uint32_t>& path)
{
    Q_ASSERT(path.size() <= 10);
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::BigEndian);
    stream << uint8_t(path.size());
    for (int32_t p : path) stream << uint32_t(p);
    return data;
}

class GetWalletPublickKeyDispatcher
{
    QQueue<GetWalletPublicKeyActivity*> m_queue;
    GetWalletPublicKeyActivity* m_activity{nullptr};
public:
    void enqueue(GetWalletPublicKeyActivity* activity)
    {
        m_queue.enqueue(activity);
        next();
    }
    void next()
    {
        if (m_activity) return;
        if (m_queue.isEmpty()) return;
        m_activity = m_queue.dequeue();
        QObject::connect(m_activity, &Activity::finished, [=]{
            m_activity = nullptr;
            next();
        });
        QObject::connect(m_activity, &Activity::failed, [=]{
            m_activity = nullptr;
            next();
        });
        m_activity->fetch();
    }
};

static GetWalletPublickKeyDispatcher g_dispatcher;

GetWalletPublicKeyActivity::GetWalletPublicKeyActivity(Network* network, const QVector<uint32_t>& path, Device* device)
    : Activity(device)
    , m_device(device)
    , m_network(network)
    , m_path(path)
{}

void GetWalletPublicKeyActivity::setPublicKey(const QByteArray &public_key)
{
    m_public_key = public_key;
}

void GetWalletPublicKeyActivity::exec()
{
    g_dispatcher.enqueue(this);
}

Device::Device(QObject* parent)
    : QObject(parent)
    , m_uuid(QUuid::createUuid().toString(QUuid::WithoutBraces))
{
}

Device::Type Device::typefromVendorAndProduct(uint32_t vendor_id, uint32_t product_id)
{
    if (vendor_id == LEDGER_VENDOR_ID) {
        if (product_id == 0x0001 || product_id & 0x1000) {
            return Device::LedgerNanoS;
        }
        if (product_id == 0x0004 || product_id & 0x4000) {
            return Device::LedgerNanoX;
        }
    }
    return Device::NoType;
}

void Device::setConnected(bool connected)
{
    if (m_connected == connected) return;
    m_connected = connected;
    emit connectedChanged();
    if (!m_connected) clearSession();
}

void Device::createSession(const QString& xpub_hash_id)
{
    clearSession();
    setSession(new DeviceSession(xpub_hash_id, this));
}

void Device::clearSession()
{
    if (m_session) {
        m_session->deleteLater();
        setSession(nullptr);
    }
}

void Device::setSession(DeviceSession* session)
{
    if (m_session == session) return;
    m_session = session;
    emit sessionChanged();
}

bool DeviceCommand::readAPDUResponse(Device*, int length, QDataStream &stream)
{
    QByteArray response;
    if (length > 0) {
        response.resize(length - 2);
        stream.readRawData(response.data(), length - 2);
    }
    uint16_t sw;
    stream >> sw;
    if (sw != 0x9000) {
        emit error();
        return false;
    }
    bool result = parse(response);
    if (result) {
        m_response = response;
        emit finished();
    }
    return result;
}

Command::Command(CommandBatch* batch)
    : QObject(batch)
{
    if (batch) batch->add(this);
}

Command::~Command()
{
}

bool DeviceCommand::parse(const QByteArray& data)
{
    QDataStream stream(data);
    return parse(stream);
}

int DeviceCommand::readHIDReport(Device* device, QDataStream& stream)
{
    // General transport
    uint16_t channel_id;
    uint8_t command_tag;
    uint16_t index;
    stream >> channel_id >> command_tag >> index;

#define CHANNEL_DEFAULT_ID 0x0101
#define TAG_APDU 0x05
#define TAG_PING 0x02

    Q_ASSERT(channel_id == CHANNEL_DEFAULT_ID);
    if (command_tag == TAG_PING) Q_UNIMPLEMENTED();
    Q_ASSERT(command_tag == TAG_APDU);

    if (index == 0) {
        Q_ASSERT(buf.size() == 0);
        stream >> length;
        buf.resize(length);
        offset = 0;
    }

    int read = stream.readRawData(buf.data() + offset, length);
    length -= read;
    offset += read;

    if (length > 0) return 2;

    QDataStream s(buf);
    return readAPDUResponse(device, buf.size(), s) ? 0 : 1;
}

DeviceSession::DeviceSession(const QString& xpub_hash_id, Device* device)
    : QObject(device)
    , m_device(device)
    , m_xpub_hash_id(xpub_hash_id)
{
}
