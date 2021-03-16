#include "json.h"
#include "session.h"

#include <gdk.h>

Session::Session(QObject* parent)
    : QObject(parent)
{
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
}

Session::~Session()
{
    GA_set_notification_handler(m_session, nullptr, nullptr);

    m_context->deleteLater();
    m_thread->quit();
    m_thread->wait();

    int rc = GA_disconnect(m_session);
    Q_ASSERT(rc == GA_OK);

    rc = GA_destroy_session(m_session);
    Q_ASSERT(rc == GA_OK);
}

void Session::handleNotification(const QJsonObject& notification)
{
    emit notificationHandled(notification);

    const auto event = notification.value("event").toString();
    Q_ASSERT(!event.isEmpty());
    const auto value = notification.value(event);

    if (event == "session") {
        auto data = value.toObject();
        const bool connected = data.take("connected").toBool();
        Q_ASSERT(data.empty());
        emit sessionEvent(connected);
        return;
    }
    if (event == "network") {
        auto data = value.toObject();
        const bool connected = data.take("connected").toBool();
        const bool heartbeat_timeout = data.take("heartbeat_timeout").toBool();
        const bool login_required = data.take("login_required").toBool();
        const int elapsed = data.take("elapsed").toInt();
        const int limit = data.take("limit").toInt();
        const int waiting = data.take("waiting").toInt();
        Q_UNUSED(elapsed);
        Q_UNUSED(limit);
        Q_UNUSED(waiting);
        Q_ASSERT(data.empty());
        emit networkEvent(connected, heartbeat_timeout, login_required);
        return;
    }
}

SessionActivity::SessionActivity(Session* session)
    : Activity(session)
    , m_session(session)
{
}
