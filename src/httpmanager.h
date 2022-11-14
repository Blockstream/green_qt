#ifndef GREEN_HTTPMANAGER_H
#define GREEN_HTTPMANAGER_H

#include <QMutex>
#include <QObject>
#include <QQueue>
#include <QTimer>

class Activity;
class SessionActivity;
class Session;

class HttpManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Session* session READ session NOTIFY sessionChanged)
public:
    HttpManager(QObject* parent = nullptr);
    static HttpManager* instance();
    void exec(SessionActivity* activity);
    Session* session() const { return m_session; }
signals:
    void sessionChanged(Session* session);
private slots:
    void dispatch();
private:
    QMutex m_mutex;
    Session* m_session{nullptr};
    QTimer* m_idle_timer{nullptr};
    QQueue<SessionActivity*> m_queue;
    SessionActivity* m_running{nullptr};
};

#endif // GREEN_HTTPMANAGER_H
