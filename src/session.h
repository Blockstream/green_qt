#ifndef GREEN_SESSION_H
#define GREEN_SESSION_H

#include <QObject>
#include <QtQml>

#include "activity.h"
#include "connectable.h"
#include "entity.h"

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
    Q_PROPERTY(bool enableSPV READ enableSPV CONSTANT)
    Q_PROPERTY(bool usePersonalNode READ usePersonalNode CONSTANT)
    Q_PROPERTY(QString electrumUrl READ electrumUrl CONSTANT)
    Q_PROPERTY(bool active READ isActive WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)
    Q_PROPERTY(bool connecting READ isConnecting NOTIFY connectingChanged)
    Q_PROPERTY(QJsonObject eventData READ eventData NOTIFY eventDataChanged)
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
    bool enableSPV() const { return m_enable_spv; }
    bool usePersonalNode() const { return !m_electrum_url.isEmpty(); }
    QString electrumUrl() const { return m_electrum_url; }
    bool isActive() const { return m_active; }
    void setActive(bool active);
    bool isConnected() const { return m_connected; }
    bool isConnecting() const { return m_connecting; }
    QList<QJsonObject> events() const { return m_events; }
    QJsonObject eventData() const { return m_event_data; }
signals:
    void notificationHandled(const QJsonObject& notification);
    void activeChanged(bool active);
    void connectedChanged(bool connected);
    void connectingChanged(bool connecting);
    void torEvent(const QJsonObject& event);
    void activityCreated(Activity* activity);
    void eventDataChanged();
private:
    void update();
    void handleNotification(const QJsonObject& notification);
    void setConnected(bool connected);
    void setConnecting(bool connecting);
private:
    Network* const m_network;
    bool const m_use_tor;
    bool const m_use_proxy;
    QString const m_proxy_host;
    int const m_proxy_port;
    QString const m_proxy;
    bool const m_enable_spv;
    QString const m_electrum_url;
    bool m_active{false};
public:
    // TODO: make m_session private
    GA_session* m_session{nullptr};
    bool m_connected{false};
    bool m_connecting{false};
    Connectable<ConnectHandler> m_connect_handler;
    QList<QJsonObject> m_events;
    QJsonObject m_event_data;
};

class SessionActivity : public Activity
{
    Q_OBJECT
    QML_ELEMENT
public:
    SessionActivity(QObject* parent);
    Session* session() const { return m_session; }
    void setSession(Session* session);
private:
    Session* m_session{nullptr};
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
