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
        const QString user_agent = QString("green_qt_%1").arg(QT_STRINGIFY(VERSION));
        QJsonObject params{
            { "name", network->id() },
            { "use_tor", session->useTor() },
            { "user_agent", user_agent },
            { "spv_enabled", session->enableSPV() }
        };
        if (!session->proxy().isEmpty()) params.insert("proxy", session->proxy());
        if (session->usePersonalNode()) params.insert("electrum_url", session->electrumUrl());
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
    setFuture(QtConcurrent::run([this] {
        auto params = get_params(m_session);
        auto session = m_session->m_session;
        return GA_connect(session, Json::fromObject(params).get());
    }));
}
