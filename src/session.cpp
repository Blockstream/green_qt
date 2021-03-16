#include "handlers/connecthandler.h"
#include "json.h"
#include "session.h"
#include "settings.h"

#include <gdk.h>

Session::Session(QObject* parent)
    : QObject(parent)
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

        rc = GA_set_notification_handler(m_session, [](void* context, const GA_json* details) {
            auto session = static_cast<Session*>(context);
            auto notification = Json::toObject(details);
            static_assert(std::is_same<decltype(details), const GA_json*>::value, "remove the following const_cast");
            GA_destroy_json(const_cast<GA_json*>(details));
            QMetaObject::invokeMethod(session, [session, notification] {
                session->handleNotification(notification);
            });
        }, this);
        Q_ASSERT(rc == GA_OK);

        m_thread = new QThread(this);
        m_context = new QObject;

        m_context->moveToThread(m_thread);
        m_thread->start();

        const bool use_tor = Settings::instance()->useTor();
        if (use_tor) emit activityCreated(new SessionTorCircuitActivity(this));
        emit activityCreated(new SessionConnectActivity(this));
        auto handler = new ConnectHandler(this, m_network, Settings::instance()->proxy(), use_tor);
        handler->exec();

        return;
    }

    if ((!m_active || !m_network) && m_session) {
        GA_set_notification_handler(m_session, nullptr, nullptr);

        m_context->deleteLater();
        m_thread->quit();
        m_thread->wait();

        int rc = GA_disconnect(m_session);
        Q_ASSERT(rc == GA_OK);

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
    m_tor_event_connection = connect(session, &Session::torEvent, [this](const QJsonObject& event) {
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
        }
    });
}

SessionConnectActivity::SessionConnectActivity(Session* session)
    : SessionActivity(session)
{
    auto slot = [this](const QJsonObject& event) {
        const bool connected = event.value("connected").toBool();
        if (connected) {
            finish();
            QObject::disconnect(m_network_event_connection);
            QObject::disconnect(m_session_event_connection);
        }
    };
    m_network_event_connection = connect(session, &Session::networkEvent, slot);
    m_session_event_connection = connect(session, &Session::sessionEvent, slot);
}
