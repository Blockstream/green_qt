#include "json.h"
#include "connecthandler.h"
#include "network.h"
#include "session.h"

#include <gdk.h>
#include <QFuture>
#include <QtConcurrentRun>

namespace {
    QJsonObject get_params(Session* session)
    {
        const auto network = session->network();
        const auto log_level = QString::fromLocal8Bit(qgetenv("GREEN_GDK_LOG_LEVEL"));
        const QString user_agent = QString("green_qt_%1").arg(QT_STRINGIFY(VERSION));
        QJsonObject params{
            { "name", network->id() },
            { "log_level", log_level.isEmpty() ? "info" : log_level },
            { "use_tor", network->isElectrum() ? false : session->useTor() },
            { "user_agent", user_agent },
            { "spv_enabled", session->enableSPV() }
        };
        if (!session->proxy().isEmpty()) params.insert("proxy", session->proxy());
        return params;
    }
} // namespace

ConnectHandler::ConnectHandler(Session* session)
    : QFutureWatcher<int>(session)
    , m_session(session)
{
}

ConnectHandler::~ConnectHandler()
{
    waitForFinished();
}

void ConnectHandler::exec()
{
    attempts ++;
    setFuture(QtConcurrent::run([this] {
        auto params = get_params(m_session);
        auto session = m_session->m_session;
        int err = GA_connect(session, Json::fromObject(params).get());
        if (err != GA_OK) {
            GA_disconnect(session);
            return err;
        }
        return err;
    }));
}
