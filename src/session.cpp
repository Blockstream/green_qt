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
}

Session::~Session()
{
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
}
