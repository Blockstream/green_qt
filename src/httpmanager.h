#ifndef GREEN_HTTPMANAGER_H
#define GREEN_HTTPMANAGER_H

#include <QObject>
#include <QQueue>
#include <QTimer>

QT_FORWARD_DECLARE_CLASS(Activity)
QT_FORWARD_DECLARE_CLASS(SessionActivity)
QT_FORWARD_DECLARE_CLASS(Session)

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
    Session* m_session{nullptr};
    QTimer* m_idle_timer{nullptr};
    QQueue<SessionActivity*> m_queue;
    SessionActivity* m_running{nullptr};
};

#endif // GREEN_HTTPMANAGER_H
