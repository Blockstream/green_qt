#ifndef GREEN_SESSION_H
#define GREEN_SESSION_H

#include "activity.h"
#include "connectable.h"
#include "entity.h"

#include <QtQml>
#include <QObject>

QT_FORWARD_DECLARE_CLASS(Connection);
QT_FORWARD_DECLARE_CLASS(ConnectHandler);
QT_FORWARD_DECLARE_CLASS(Network);

QT_FORWARD_DECLARE_STRUCT(GA_session)


class Session : public Entity
{
    Q_OBJECT
    Q_PROPERTY(Network* network READ network CONSTANT)
    Q_PROPERTY(bool useTor READ useTor CONSTANT)
    Q_PROPERTY(bool useProxy READ useProxy CONSTANT)
    Q_PROPERTY(QString proxyHost READ proxyHost CONSTANT)
    Q_PROPERTY(int proxyPort READ proxyPort CONSTANT)
    Q_PROPERTY(bool active READ isActive WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)
    QML_ELEMENT
public:
    Session(Network* network, QObject* parent = nullptr);
    virtual ~Session();
    Network* network() const { return m_network; }
    bool useTor() const { return m_use_tor; }
    bool useProxy() const { return m_use_proxy; }
    QString proxyHost() const { return m_proxy_host; }
    QString proxy() const { return m_proxy; }
    int proxyPort() const { return m_proxy_port; }
    bool isActive() const { return m_active; }
    void setActive(bool active);
    bool isConnected() const { return m_connected; }
    Connection* connection() const { return m_connection; };
    QList<QJsonObject> events() const { return m_events; }
signals:
    void notificationHandled(const QJsonObject& notification);
    void networkEvent(const QJsonObject& event);
    void sessionEvent(const QJsonObject& event);
    void activeChanged(bool active);
    void connectedChanged(bool connected);
    void torEvent(const QJsonObject& event);
    void activityCreated(Activity* activity);
private:
    void update();
    void handleNotification(const QJsonObject& notification);
    void setConnected(bool connected);
public:
    Network* const m_network;
    bool const m_use_tor;
    bool const m_use_proxy;
    QString const m_proxy_host;
    int const m_proxy_port;
    QString const m_proxy;
    bool m_active{false};
    // TODO: make m_session private
    GA_session* m_session{nullptr};
    bool m_connected{false};
    Connectable<ConnectHandler> m_connect_handler;
    Connection* m_connection{nullptr};
    QList<QJsonObject> m_events;
};

class Connection : public QObject
{
    Q_OBJECT
public:
    Connection(Session* session);
    virtual ~Connection();
private:
    Session* const m_session;
};

class SessionActivity : public Activity
{
    Q_OBJECT
    Q_PROPERTY(Session* session READ session CONSTANT)
    QML_ELEMENT
public:
    SessionActivity(Session* session);
    Session* session() const { return m_session; }
private:
    Session* const m_session;
};

class SessionTorCircuitActivity : public SessionActivity
{
    Q_OBJECT
    Q_PROPERTY(QStringList logs READ logs NOTIFY logsChanged)
    QML_ELEMENT
public:
    SessionTorCircuitActivity(Session* session);
    QStringList logs() const { return m_logs; }
private:
    void exec() {}
signals:
    void logsChanged(const QStringList& logs);
private:
    QMetaObject::Connection m_tor_event_connection;
    QMetaObject::Connection m_connected_connection;
    QStringList m_logs;
};

class SessionConnectActivity : public SessionActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    SessionConnectActivity(Session* session);
private:
    void exec() {}
private:
    QMetaObject::Connection m_connection;
};

#endif // GREEN_SESSION_H
