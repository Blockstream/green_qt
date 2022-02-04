#include "handlers/connecthandler.h"
#include "json.h"
#include "network.h"
#include "session.h"
#include "settings.h"

#include <QMutex>
#include <QMutexLocker>

#include <gdk.h>

namespace  {
qint64 m_session_context_id{0};
QMap<qint64, Session*> m_session_by_id;
QMutex m_session_mutex;

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

    m_event[event] = value;
    emit eventChanged(m_event);

    m_events.append(notification);

    if (event == "network") {
        auto data = value.toObject();
        emit networkEvent(data);
        const bool connected = data.value("connected").toBool();
        setConnected(connected);
        return;
    }
    if (event == "tor") {
        emit torEvent(value.toObject());
        return;
    }
}

void Session::setConnected(bool connected)
{
    if (m_connected == connected) return;
    m_connected = connected;

    if (m_connected && !m_connection) {
        m_connection = new Connection(this);
    } else if (!m_connected && m_connection) {
        delete m_connection;
        m_connection = nullptr;
    }

    emit connectedChanged(m_connected);
}

void Session::setActive(bool active)
{
    if (m_active == active) return;
    m_active = active;
    emit activeChanged(m_active);
    update();
}

void Session::update()
{
    if (m_active && !m_session) {
        int rc = GA_create_session(&m_session);
        Q_ASSERT(rc == GA_OK);

        {
            QMutexLocker lock(&m_session_mutex);
            m_id = ++m_session_context_id;
            m_session_by_id[m_id] = this;
        }

        rc = GA_set_notification_handler(m_session, [](void* context, GA_json* details) {
            auto notification = Json::toObject(details);
            QMutexLocker lock(&m_session_mutex);

            auto id = reinterpret_cast<qint64>(context);
            auto session = m_session_by_id.value(id);

            qDebug() << "session: handle notification" << id << session << notification;

            if (!session) return;

            GA_destroy_json(details);
            QMetaObject::invokeMethod(session, [session, notification] {
                session->handleNotification(notification);
            }, Qt::QueuedConnection);
        }, reinterpret_cast<void*>(m_id));
        Q_ASSERT(rc == GA_OK);

        if (!m_network->isElectrum() && m_use_tor) emit activityCreated(new SessionTorCircuitActivity(this));
        emit activityCreated(new SessionConnectActivity(this));
        m_connect_handler = new ConnectHandler(this);
        m_connect_handler.track(QObject::connect(m_connect_handler, &ConnectHandler::finished, this, [=] {
            if (m_connect_handler->resultAt(0) == GA_OK) {
                m_connect_handler->deleteLater();
                setConnected(true);
            } else if (m_connect_handler->attempts < 3) {
                QTimer::singleShot(1000, this, [this] {
                    m_connect_handler->exec();
                });
            } else {
                m_connect_handler->deleteLater();
                setConnected(false);
            }
        }));
        m_connect_handler->exec();

        return;
    }

    if (!m_active && m_session) {
        {
            QMutexLocker lock(&m_session_mutex);
            m_session_by_id.take(m_id);
            m_id = 0;
        }

        m_connect_handler.destroy();

        if (m_connection) {
            delete m_connection;
            m_connection = nullptr;
        }

        int rc = GA_disconnect(m_session);
        if (rc != GA_OK) qDebug() << "disconnect failed" << rc;

        rc = GA_destroy_session(m_session);
        Q_ASSERT(rc == GA_OK);

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

SessionTorCircuitActivity::SessionTorCircuitActivity(Session* session)
    : SessionActivity(session)
{
    m_tor_event_connection = connect(session, &Session::torEvent, this, [this](const QJsonObject& event) {
        const int progress_value = event.value("progress").toInt();
        if (progress_value > 0) {
            progress()->setIndeterminate(false);
            progress()->setTo(100);
            progress()->setValue(progress_value);
        }

        const auto summary = event.value("summary").toString();
        if (!summary.isEmpty()) {
            m_logs.prepend(summary);
            emit logsChanged(m_logs);
        }

        // TODO: handle errors

        const auto tag = event.value("tag").toString();
        if (tag == "done") {
            finish();
            QObject::disconnect(m_tor_event_connection);
            QObject::disconnect(m_connected_connection);
        }
    });
    m_connected_connection = connect(session, &Session::connectedChanged, this, [=](bool connected) {
        if (connected) {
            finish();
            QObject::disconnect(m_tor_event_connection);
            QObject::disconnect(m_connected_connection);
        }
    });
}

SessionConnectActivity::SessionConnectActivity(Session* session)
    : SessionActivity(session)
{
    m_connection = connect(session, &Session::connectedChanged, this, [=] {
        if (session->isConnected()) {
            finish();
            QObject::disconnect(m_connection);
        }
    });
}

Connection::Connection(Session* session)
    : QObject(session)
    , m_session(session)
{
}

Connection::~Connection()
{
}
