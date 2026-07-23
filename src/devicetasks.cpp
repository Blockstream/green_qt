#include "devicetasks.h"

#include <QDataStream>
#include <QPointer>
#include <QQueue>

#include "device.h"
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

namespace {

// Serializes wallet public key requests across all devices, one at a time.
class DeviceGetWalletPublicKeyQueue
{
    QQueue<QPointer<DeviceGetWalletPublicKeyTask>> m_queue;
    DeviceGetWalletPublicKeyTask* m_task{nullptr};
public:
    void enqueue(DeviceGetWalletPublicKeyTask* task)
    {
        m_queue.enqueue(task);
        next();
    }
    void next()
    {
        if (m_task) return;
        while (!m_queue.isEmpty()) {
            const auto task = m_queue.dequeue().data();
            if (!task) continue;
            m_task = task;
            // A task can be destroyed before it settles, e.g. when its device is
            // unplugged mid-fetch, and must release the queue in that case too.
            const auto release = [=, this] {
                if (m_task != task) return;
                m_task = nullptr;
                next();
            };
            QObject::connect(task, &Task::finished, task, release);
            QObject::connect(task, &Task::failed, task, release);
            QObject::connect(task, &QObject::destroyed, release);
            task->fetch();
            return;
        }
    }
};

DeviceGetWalletPublicKeyQueue g_get_wallet_public_key_queue;

} // namespace

DeviceGetWalletPublicKeyTask::DeviceGetWalletPublicKeyTask(Network* network, const QVector<uint32_t>& path, Device* device)
    : Task(device)
    , m_device(device)
    , m_network(network)
    , m_path(path)
{
}

void DeviceGetWalletPublicKeyTask::setPublicKey(const QByteArray& public_key)
{
    m_public_key = public_key;
}

void DeviceGetWalletPublicKeyTask::update()
{
    if (m_status != Status::Ready) return;
    setStatus(Status::Active);
    g_get_wallet_public_key_queue.enqueue(this);
}

void DeviceSignLiquidTransactionTask::setMessage(const QJsonObject& message)
{
    if (m_message == message) return;
    m_message = message;
    emit messageChanged(m_message);
}
