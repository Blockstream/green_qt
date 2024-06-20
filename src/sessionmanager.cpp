#include "sessionmanager.h"
#include "session.h"

static SessionManager* g_session_manager{nullptr};

SessionManager::SessionManager()
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
    auto session = new Session(network, this);
    connect(session, &Session::torEvent, this, &SessionManager::setTor);
    return session;
}

void SessionManager::setTor(const QJsonObject& tor)
{
    if (m_tor == tor) return;
    m_tor = tor;
    emit torChanged();
}
