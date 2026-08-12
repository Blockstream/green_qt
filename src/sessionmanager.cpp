#include "green_settings.h"
#include "networkmanager.h"
#include "session.h"
#include "sessionmanager.h"
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
    qDebug() << Q_FUNC_INFO;
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
        m_tor_session->m_is_tor = true;
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
    if (m_garbage.contains(session)) {
        qWarning() << Q_FUNC_INFO << "session already queued for deletion" << session;
        return;
    }

    qDebug() << Q_FUNC_INFO << "total sessions:" << m_sessions.count();
    m_sessions.removeOne(session);

    // Tear the GDK session down while the QObject is still fully alive.
    session->setActive(false);
    m_garbage.append(session);
}

void SessionManager::abandon(Session* session)
{
    Q_ASSERT(session);
    qWarning() << Q_FUNC_INFO << "leaking session still in use" << session;

    // Gives up ownership of a session that is still used by a thread we cannot
    // wait for. The gdk session is deliberately left alive and leaked, because
    // destroying it under an in flight call is what takes the process down.
    m_sessions.removeOne(session);
    m_garbage.removeOne(session);
    // Sessions are children of the manager, so clear the parent as well or
    // ~QObject destroys it anyway.
    session->setParent(nullptr);
}

void SessionManager::exit()
{
    while (!m_sessions.isEmpty()) {
        qWarning() << Q_FUNC_INFO << "unexpected active sessions:" << m_sessions.count();
        auto session = m_sessions.takeFirst();
        if (m_garbage.contains(session)) continue;
        session->setActive(false);
        m_garbage.append(session);
    }


    if (!m_garbage.isEmpty()) {
        qDebug() << Q_FUNC_INFO << "total garbage sessions:" << m_garbage.count();
        while (!m_garbage.isEmpty()) {
            delete m_garbage.takeFirst();
        }
    }

    if (m_tor_session) {
        m_tor_session->setActive(false);
        delete m_tor_session;
        m_tor_session = nullptr;
    }
}

void SessionManager::setTor(const QJsonObject& tor)
{
    if (m_tor == tor) return;
    m_tor = tor;
    emit torChanged();
}
