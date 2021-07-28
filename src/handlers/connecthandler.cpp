#include "json.h"
#include "connecthandler.h"
#include "network.h"
#include "session.h"

#include <gdk.h>
#include <QFuture>
#include <QtConcurrentRun>

namespace {
    QJsonObject get_params(Network* network, const QString& proxy, bool use_tor)
    {
        const auto log_level = QString::fromLocal8Bit(qgetenv("GREEN_GDK_LOG_LEVEL"));
        QJsonObject params = {
            { "name", network->id() },
            { "log_level", log_level.isEmpty() ? "info" : log_level },
            { "use_tor", network->isElectrum() ? false : use_tor },
            { "user_agent", QString("green_qt_%1").arg(QT_STRINGIFY(VERSION)) }
        };
        if (!proxy.isEmpty()) params.insert("proxy", proxy);
        return params;
    }
} // namespace

ConnectHandler::ConnectHandler(Session* session, Network* network, const QString& proxy, bool use_tor)
    : QFutureWatcher<int>(session)
    , m_session(session)
    , m_network(network)
    , m_params(get_params(network, proxy, use_tor))
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
        auto session = m_session->m_session;
        auto params = Json::fromObject(m_params);
        int err = GA_connect(session, params.get());
        if (err != GA_OK) {
            GA_disconnect(session);
            return err;
        }
        return err;
    }));
}
