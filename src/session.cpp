#include "session.h"

#include <gdk.h>

#include <QMutex>
#include <QMutexLocker>
#include <QtConcurrentRun>

#include "json.h"
#include "network.h"
#include "settings.h"

namespace  {
QString ElectrumUrlForNetwork(Network* network)
{
    if (Settings::instance()->usePersonalNode()) {
        const auto mainnet = network->isMainnet();
        const auto liquid = network->isLiquid();
        if (network->isElectrum()) {
            if (mainnet && !liquid) return Settings::instance()->bitcoinElectrumUrl();
            if (mainnet && liquid) return Settings::instance()->liquidElectrumUrl();
            if (!mainnet && !liquid) return Settings::instance()->testnetElectrumUrl();
            if (!mainnet && liquid) return Settings::instance()->liquidTestnetElectrumUrl();
        }
    }
    return {};
}
}

Session::Session(Network* network, QObject* parent)
    : Entity(parent)
    , m_network(network)
    , m_use_tor(Settings::instance()->useTor())
    , m_use_proxy(Settings::instance()->useProxy())
    , m_proxy_host(Settings::instance()->proxyHost())
    , m_proxy_port(Settings::instance()->proxyPort())
    , m_proxy(m_use_proxy ? QString("%1:%2").arg(m_proxy_host).arg(m_proxy_port) : "")
    , m_enable_spv(network->isElectrum() && !network->isLiquid() ? Settings::instance()->enableSPV() : false)
    , m_electrum_url(ElectrumUrlForNetwork(network))
{
}

Session::~Session()
{
    setActive(false);
}

void Session::handleNotification(const QJsonObject& notification)
{
    emit notificationHandled(notification);

    const auto event = notification.value("event").toString();
    Q_ASSERT(!event.isEmpty());
    const auto value = notification.value(event);

    m_event_data[event] = value;
    emit eventDataChanged();

    m_events.append(notification);

    qDebug() << Q_FUNC_INFO << notification;

    if (event == "network") {
        auto data = value.toObject();
        const auto current_state = data.value("current_state").toString();
        const auto next_state = data.value("next_state").toString();
        setConnected(current_state == "connected");
        setConnecting(current_state == "disconnected" && next_state == "connected");
        emit networkEvent(data);
    } else if (event == "tor") {
        emit torEvent(value.toObject());
    } else if (event == "settings") {
        emit settingsEvent(value.toObject());
    } else if (event == "twofactor_reset") {
        emit twoFactorResetEvent(value.toObject());
    } else if (event == "block") {
        const auto block = value.toObject();
        setBlock(block);
        emit blockEvent(block);
    } else if (event == "transaction") {
        emit transactionEvent(value.toObject());
    } else if (event == "ticker") {
        emit tickerEvent(value.toObject());
    } else {
        qDebug() << Q_FUNC_INFO << notification;
        Q_UNREACHABLE();
    }
}

void Session::setConnected(bool connected)
{
    if (m_connected == connected) return;
    m_connected = connected;
    emit connectedChanged();
}

void Session::setConnecting(bool connecting)
{
    if (m_connecting == connecting) return;
    m_connecting = connecting;
    emit connectingChanged();
}

void Session::setActive(bool active)
{
    if (m_active == active) return;
    m_active = active;
    emit activeChanged();
    update();
}

uint32_t Session::blockHeight() const
{
    return m_block.value("block_height").toDouble();
}

void Session::setBlock(const QJsonObject& block)
{
    if (m_block == block) return;
    m_block = block;
    emit blockChanged();
}

static QMutex g_session_mutex;
static int64_t g_session_id{0};
static QMap<int64_t, QPointer<Session>> g_sessions;

void Session::update()
{
    if (m_active && !m_session) {
        int rc = GA_create_session(&m_session);
        Q_ASSERT(rc == GA_OK);

        {
            QMutexLocker locker(&g_session_mutex);
            m_id = ++g_session_id;
            g_sessions[m_id] = this;
        }

        rc = GA_set_notification_handler(m_session, [](void* context, GA_json* details) {
            QMutexLocker locker(&g_session_mutex);
            const auto id = (int64_t) context;

            if (!g_sessions.contains(id)) return;
            if (g_sessions.value(id).isNull()) return;

            auto session = g_sessions.value(id).get();
            auto notification = Json::toObject(details);

            GA_destroy_json(details);
            QMetaObject::invokeMethod(session, [session, notification] {
                session->handleNotification(notification);
            }, Qt::QueuedConnection);
        }, (void*) m_id);
        Q_ASSERT(rc == GA_OK);
        return;
    }

    if (!m_active && m_session) {
#if 1
        {
            QMutexLocker locker(&g_session_mutex);
            g_sessions.remove(m_id);
            m_id = 0;
        }

        int rc = GA_destroy_session(m_session);
        qDebug() << Q_FUNC_INFO << rc;
#else
        m_self->clear();
        const auto session = m_session;
        QTimer::singleShot(60 * 1000, qApp, [session] {
            GA_set_notification_handler(session, nullptr, nullptr);
            int rc = GA_destroy_session(session);
            qDebug() << Q_FUNC_INFO << "GA_destroy_session" << rc;
        });
#endif
        m_session = nullptr;
        return;
    }
}

SessionActivity::SessionActivity(QObject* parent)
    : Activity(parent)
{
}

void SessionActivity::setSession(Session* session)
{
    Q_ASSERT(!m_session);
    m_session = session;
}

