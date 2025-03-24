#ifndef GREEN_HTTPMANAGER_H
#define GREEN_HTTPMANAGER_H

#include "green.h"

#include <QMutex>
#include <QObject>
#include <QQueue>
#include <QTimer>

class SessionActivity;

class HttpManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Session* session READ session NOTIFY sessionChanged)
public:
    HttpManager(QObject* parent = nullptr);
    static HttpManager* instance();
    void exec(SessionActivity* activity);
    Session* session() const { return m_session; }
    void stop();
signals:
    void sessionChanged();
private slots:
    void dispatch();
    void drain();
private:
    TaskDispatcher* const m_dispatcher;
    QMutex m_mutex;
    Context* m_context{nullptr};
    Session* m_session{nullptr};
    QTimer* m_idle_timer{nullptr};
    QQueue<SessionActivity*> m_queue;
    SessionActivity* m_running{nullptr};
};

#endif // GREEN_HTTPMANAGER_H
