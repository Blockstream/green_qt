#ifndef GREEN_SESSION_H
#define GREEN_SESSION_H

#include <QObject>
#include <QtQml>

#include "green.h"

#include "activity.h"
#include "connectable.h"
#include "entity.h"

Q_MOC_INCLUDE("context.h")
Q_MOC_INCLUDE("network.h")

QT_FORWARD_DECLARE_STRUCT(GA_session)

class AuthHandlerTask;

class Session : public Entity
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context CONSTANT)
    Q_PROPERTY(Network* network READ network CONSTANT)
    Q_PROPERTY(bool useTor READ useTor CONSTANT)
    Q_PROPERTY(bool useProxy READ useProxy CONSTANT)
    Q_PROPERTY(QString proxy READ proxy CONSTANT)
    Q_PROPERTY(bool enableSPV READ enableSPV CONSTANT)
    Q_PROPERTY(bool usePersonalNode READ usePersonalNode CONSTANT)
    Q_PROPERTY(QString electrumUrl READ electrumUrl CONSTANT)
    Q_PROPERTY(bool active READ isActive WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)
    Q_PROPERTY(QJsonObject config READ config NOTIFY configChanged)
    Q_PROPERTY(QJsonObject events READ events NOTIFY eventsChanged)
    Q_PROPERTY(QJsonObject block READ block NOTIFY blockChanged)
    Q_PROPERTY(QJsonObject settings READ settings NOTIFY settingsChanged)
    Q_PROPERTY(QJsonObject currencies READ currencies NOTIFY currenciesChanged)
    Q_PROPERTY(QString unit READ unit NOTIFY unitChanged)
    Q_PROPERTY(QString displayUnit READ displayUnit NOTIFY unitChanged)
    Q_PROPERTY(QString username READ username NOTIFY usernameChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    Session(Network* network, QObject* parent);
    Session(Network* network, Context* context);
    virtual ~Session();
    Context* context() const { return m_context; }
    Network* network() const { return m_network; }
    bool useTor() const { return m_use_tor; }
    bool useProxy() const { return m_use_proxy; }
    QString proxy() const { return m_proxy; }
    bool enableSPV() const { return m_enable_spv; }
    bool usePersonalNode() const { return !m_electrum_url.isEmpty(); }
    QString electrumUrl() const { return m_electrum_url; }
    bool isActive() const { return m_active; }
    void setActive(bool active);
    bool isConnected() const { return m_connected; }
    void setConnected(bool connected);

    QJsonObject config() const { return m_config; }
    void setConfig(const QJsonObject& config);

    QJsonObject events() const { return m_events; }
    void setEvents(const QJsonObject& events);
    QJsonObject block() const { return m_block; }
    uint32_t blockHeight() const;
    void setBlock(const QJsonObject& block);
    QJsonObject settings() const { return m_settings; }
    void setSettings(const QJsonObject& settings);
    QJsonObject currencies() const { return m_currencies; }
    void setCurrencies(const QJsonObject& currencies);
    QString unit() const { return m_unit; }
    void setUnit(const QString& unit);
    QString displayUnit() const { return m_display_unit; }
    void setAltimeout(int altimeout);

    QString username() const { return m_username; }
    void setUsername(const QString& username);

    AuthHandlerTask* registerUser();
    AuthHandlerTask* login();

signals:
    void notificationHandled(const QJsonObject& notification);
    void eventHandled(Session* session, const QString& event, const QJsonObject& data);
    void activeChanged();
    void connectedChanged();
    void configChanged();
    void networkEvent(const QJsonObject& event);
    void twoFactorResetEvent(const QJsonObject& event);
    void torEvent(const QJsonObject& event);
    void blockEvent(const QJsonObject& event);
    void transactionEvent(const QJsonObject& event);
    void tickerEvent();
    void subaccountEvent(const QJsonObject& event);
    void activityCreated(Activity* activity);
    void eventsChanged();
    void blockChanged();
    void settingsChanged();
    void currenciesChanged();
    void unitChanged();
    void usernameChanged();

protected:
    bool eventFilter(QObject *object, QEvent *event) override;
    void timerEvent(QTimerEvent* event) override;

private:
    void update();
    void handleNotification(const QJsonObject& notification);
private:
    Context* const m_context;
    Network* const m_network;
    bool const m_use_tor;
    bool const m_use_proxy;
    QString const m_proxy;
    bool const m_enable_spv;
    QString const m_electrum_url;
    bool m_active{false};
    QJsonObject m_settings;
    QJsonObject m_currencies;
    QString m_unit;
    QString m_display_unit;
    int m_altimeout{0};
    int m_logout_timer{-1};
public:
    // TODO: make m_session private
    GA_session* m_session{nullptr};
    bool m_connected{false};
    bool m_ready{false};
    QJsonObject m_config;
    QJsonObject m_events;

    QJsonObject m_block;
    int64_t m_id{0};
    QString m_wallet_hash_id;
    QString m_username;
};

class SessionActivity : public Activity
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SessionActivity(QObject* parent);
    Session* session() const { return m_session; }
    void setSession(Session* session);
private:
    Session* m_session{nullptr};
};

#endif // GREEN_SESSION_H
