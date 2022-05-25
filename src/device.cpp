#include "command.h"
#include "device.h"
#include "device_p.h"
#include "ga.h"
#include "handler.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
#include "util.h"
#include "wallet.h"
#include "walletmanager.h"


#include <wally_core.h>
#include <wally_bip32.h>
#include <wally_elements.h>

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
    QMap<QByteArray, QMap<QVector<uint32_t>, QByteArray>> m_cache;
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
        auto device = m_activity->device();
        auto master_public_key = device->masterPublicKey(m_activity->network());
        auto path = m_activity->path();

        if (!master_public_key.isEmpty()) {
            if (m_cache.contains(master_public_key)) {
                const auto& public_key = m_cache[master_public_key][path];
                if (!public_key.isEmpty()) {
                    m_activity->setPublicKey(public_key);
                    m_activity->finish();
                    m_activity = nullptr;
                    next();
                    return;
                }
            }
        }

        QObject::connect(m_activity, &Activity::finished, [=]{
            auto device = m_activity->device();
            auto master_public_key = device->masterPublicKey(m_activity->network());
            auto path = m_activity->path();
            auto publick_key = m_activity->publicKey();

            if (master_public_key.isEmpty() && path.isEmpty()) {
                master_public_key = publick_key;
                device->setMasterPublicKey(m_activity->network(), publick_key);
            }
            if (!master_public_key.isEmpty()) {
                m_cache[master_public_key][path] = publick_key;
            }
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

QByteArray Device::masterPublicKey(Network* network) const
{
    return m_master_public_key[network];
}

void Device::setMasterPublicKey(Network* network, const QByteArray& master_public_key)
{
    Q_ASSERT(network);
    Q_ASSERT(!m_master_public_key.contains(network));
    m_master_public_key[network] = master_public_key;
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
