#ifndef GREEN_SESSION_H
#define GREEN_SESSION_H

#include <QtQml>
#include <QObject>

QT_FORWARD_DECLARE_STRUCT(GA_session)

class Session : public QObject
{
    Q_OBJECT
    QML_UNCREATABLE("...")
public:
    Session(QObject* parent = nullptr);
    virtual ~Session();
signals:
    void notificationHandled(const QJsonObject& notification);
    void networkEvent(bool connected, bool heartbeat_timeout, bool login_required);
    void sessionEvent(bool connected);
private:
    void handleNotification(const QJsonObject& notification);
public:
    QThread* m_thread{nullptr};
    QObject* m_context{nullptr};
    // TODO: make m_session private
    GA_session* m_session{nullptr};    
};

#endif // GREEN_SESSION_H
