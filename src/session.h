#ifndef GREEN_SESSION_H
#define GREEN_SESSION_H

#include <QObject>
#include <QtQml>

#include "activity.h"
#include "connectable.h"
#include "entity.h"

class Network;

Q_MOC_INCLUDE("network.h")

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
    Q_PROPERTY(QJsonObject block READ block NOTIFY blockChanged)
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
    void setConnected(bool connected);
    bool isConnecting() const { return m_connecting; }
    void setConnecting(bool connecting);
    QList<QJsonObject> events() const { return m_events; }
    QJsonObject eventData() const { return m_event_data; }
    QJsonObject block() const { return m_block; }
    uint32_t blockHeight() const;
    void setBlock(const QJsonObject& block);
signals:
    void notificationHandled(const QJsonObject& notification);
    void eventHandled(Session* session, const QString& event, const QJsonObject& data);
    void activeChanged();
    void connectedChanged();
    void connectingChanged();
    void networkEvent(const QJsonObject& settings);
    void settingsEvent(const QJsonObject& settings);
    void twoFactorResetEvent(const QJsonObject& settings);
    void torEvent(const QJsonObject& event);
    void blockEvent(const QJsonObject& event);
    void transactionEvent(const QJsonObject& event);
    void tickerEvent(const QJsonObject& event);
    void activityCreated(Activity* activity);
    void eventDataChanged();
    void blockChanged();
private:
    void update();
    void handleNotification(const QJsonObject& notification);
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
    bool m_ready{false};
    QList<QJsonObject> m_events;
    QJsonObject m_event_data;
    QJsonObject m_block;
    int64_t m_id{0};
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

#endif // GREEN_SESSION_H
