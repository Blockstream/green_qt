#include "httpmanager.h"

#include "activitymanager.h"
#include "httprequestactivity.h"
#include "networkmanager.h"
#include "session.h"
#include "settings.h"
#include "task.h"

static HttpManager* g_http_manager{nullptr};

HttpManager* HttpManager::instance()
{
    Q_ASSERT(g_http_manager);
    return g_http_manager;
}

HttpManager::HttpManager(QObject* parent)
    : QObject(parent)
    , m_dispatcher(new TaskDispatcher(this))
    , m_idle_timer(new QTimer(this))
{
    Q_ASSERT(!g_http_manager);
    g_http_manager = this;

    auto settings = Settings::instance();
    connect(settings, &Settings::useTorChanged, this, &HttpManager::dispatch);
    connect(settings, &Settings::useProxyChanged, this, &HttpManager::dispatch);
    connect(settings, &Settings::proxyHostChanged, this, &HttpManager::dispatch);
    connect(settings, &Settings::proxyPortChanged, this, &HttpManager::dispatch);

    m_idle_timer->setSingleShot(true);
    m_idle_timer->setInterval(60000);
    connect(m_idle_timer, &QTimer::timeout, this, [=] {
        if (m_running || !m_queue.isEmpty()) {
            qDebug() << "http: idle timeout, session busy";
        } else if (!m_session) {
            qDebug() << "http: idle timeout, session already destroyed";
        } else {
            qDebug() << "http: idle timeout, destroy session";
            delete m_session;
            m_session = nullptr;
            emit sessionChanged();
        }
    });
}

void HttpManager::exec(SessionActivity* activity)
{
    {
        QMutexLocker locker(&m_mutex);
        activity->moveToThread(thread());
        m_queue.enqueue(activity);
        connect(activity, &Activity::destroyed, this, [=] {
            {
                QMutexLocker locker(&m_mutex);
                m_queue.removeAll(activity);
            }
            if (m_running == activity) {
                m_running = nullptr;
                QMetaObject::invokeMethod(this, [=] { dispatch(); }, Qt::QueuedConnection);
            }
        });
    }
    QMetaObject::invokeMethod(this, [=] { dispatch(); }, Qt::QueuedConnection);
}

void HttpManager::dispatch()
{
    m_idle_timer->stop();

    if (m_session && !m_running) {
        auto settings = Settings::instance();
        if (m_session->useTor() != settings->useTor() ||
            m_session->proxy() != settings->proxy()) {
            qDebug() << "http: networking settings changed, destroy session";
            delete m_session;
            m_session = nullptr;
            emit sessionChanged();
        }
    }

    if (m_queue.isEmpty()) {
        qDebug() << "http: queue is empty, enable idle timeout";
        m_idle_timer->start();
        return;
    }

    if (m_running) return;

    if (!m_session) {
        qDebug() << "http: create session";
        auto network = NetworkManager::instance()->network("electrum-mainnet");
        m_session = new Session(network, this);
        m_session->setActive(true);
        connect(m_session, &Session::connectedChanged, this, &HttpManager::dispatch);
        emit sessionChanged();

        m_dispatcher->add(new ConnectTask(m_session));

        return;
    }

    if (!m_session->isConnected()) {
        return;
    }

    m_running = m_queue.dequeue();
    m_running->setSession(m_session);

    connect(m_running, &Activity::finished, this, [=] {
        m_running = nullptr;
        QMetaObject::invokeMethod(this, [=] { dispatch(); }, Qt::QueuedConnection);
    });

    connect(m_running, &Activity::failed, this, [=] {
        m_running = nullptr;
        QMetaObject::invokeMethod(this, [=] { dispatch(); }, Qt::QueuedConnection);
    });

    ActivityManager::instance()->exec(m_running);
}
