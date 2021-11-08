#include "handlers/connecthandler.h"
#include "json.h"
#include "network.h"
#include "session.h"
#include "settings.h"

#include <gdk.h>

Session::Session(QObject* parent)
    : Entity(parent)
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

    m_events.append(notification);

    if (event == "session") {
        auto data = value.toObject();
        emit sessionEvent(data);
        const bool connected = data.value("connected").toBool();
        setConnected(connected);
        return;
    }
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

void Session::setNetwork(Network* network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged(m_network);
    update();
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
    if (m_active && m_network && !m_session) {
        int rc = GA_create_session(&m_session);
        Q_ASSERT(rc == GA_OK);

        rc = GA_set_notification_handler(m_session, [](void* context, GA_json* details) {
            auto session = static_cast<Session*>(context);
            auto notification = Json::toObject(details);
            GA_destroy_json(details);
            QMetaObject::invokeMethod(session, [session, notification] {
                session->handleNotification(notification);
            }, Qt::QueuedConnection);
        }, this);
        Q_ASSERT(rc == GA_OK);

        const bool use_tor = !m_network->isElectrum() && Settings::instance()->useTor();
        if (use_tor) emit activityCreated(new SessionTorCircuitActivity(this));
        emit activityCreated(new SessionConnectActivity(this));
        m_connect_handler = new ConnectHandler(this, m_network, Settings::instance()->proxy(), use_tor);
        m_connect_handler.track(QObject::connect(m_connect_handler, &ConnectHandler::finished, [this] {
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

    if ((!m_active || !m_network) && m_session) {
        m_connect_handler.destroy();

        GA_set_notification_handler(m_session, nullptr, nullptr);

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

SessionActivity::SessionActivity(Session* session)
    : Activity(session)
    , m_session(session)
{
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
    m_connected_connection = connect(session, &Session::connectedChanged, this, [this](bool connected) {
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
    m_connection = connect(session, &Session::connectedChanged, this, [this, session] {
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
