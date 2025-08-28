#include "deviceactivities.h"

#include <QQueue>
#include <QDataStream>

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
