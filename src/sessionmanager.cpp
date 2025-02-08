#include "networkmanager.h"
#include "sessionmanager.h"
#include "session.h"
#include "green_settings.h"
#include "task.h"

static SessionManager* g_session_manager{nullptr};

SessionManager::SessionManager()
    : m_dispatcher(new TaskDispatcher(this))
{
    Q_ASSERT(!g_session_manager);
    g_session_manager = this;
}

SessionManager::~SessionManager()
{
    g_session_manager = nullptr;
}

SessionManager *SessionManager::instance()
{
    Q_ASSERT(g_session_manager);
    return g_session_manager;
}

Session* SessionManager::create(Network* network)
{
    const auto settings = Settings::instance();
    if (settings->useTor() && !settings->useProxy() && !m_tor_session) {
        qDebug() << Q_FUNC_INFO << "created tor session";
        m_tor_session = new Session(NetworkManager::instance()->network("electrum-mainnet"), this);
        m_tor_session->setActive(true);
        m_dispatcher->add(new ConnectTask(m_tor_session));
        connect(m_tor_session, &Session::torEvent, this, &SessionManager::setTor);
    }
    auto session = new Session(network, this);
    m_sessions.append(session);
    qDebug() << Q_FUNC_INFO << "total sessions:" << m_sessions.count();
    return session;
}

void SessionManager::release(Session* session)
{
    Q_ASSERT(session);
    m_sessions.removeOne(session);
    qDebug() << Q_FUNC_INFO << "total sessions:" << m_sessions.count();
    session->setActive(false);
    // TODO: session->deleteLater();
}

void SessionManager::setTor(const QJsonObject& tor)
{
    if (m_tor == tor) return;
    m_tor = tor;
    emit torChanged();
}
