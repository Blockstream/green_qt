#include "session.h"

#include <gdk.h>

#include <QMutex>
#include <QMutexLocker>
#include <QtConcurrentRun>

#include "context.h"
#include "green_settings.h"
#include "json.h"
#include "network.h"
#include "task.h"

namespace  {
QString ElectrumUrlForNetwork(Network* network)
{
    if (Settings::instance()->usePersonalNode()) {
        const auto mainnet = network->isMainnet();
        const auto liquid = network->isLiquid();
        if (network->isElectrum()) {
            if (mainnet && !liquid) return Settings::instance()->bitcoinElectrumUrl();
            if (mainnet && liquid) return Settings::instance()->liquidElectrumUrl();
            if (!mainnet && !liquid) return Settings::instance()->testnetElectrumUrl();
            if (!mainnet && liquid) return Settings::instance()->liquidTestnetElectrumUrl();
        }
    }
    return {};
}
}

Session::Session(Network* network, QObject* parent)
    : Entity(parent)
    , m_network(network)
    , m_use_tor(Settings::instance()->useTor())
    , m_use_proxy(Settings::instance()->useProxy())
    , m_proxy(Settings::instance()->proxy())
    , m_enable_electrum_tls(Settings::instance()->enableElectrumTls())
    , m_electrum_url(ElectrumUrlForNetwork(network))
{
    if (m_network->isElectrum()) {
        // emit ticker event each minute on singlesig session
        auto timer = new QTimer(this);
        connect(timer, &QTimer::timeout, this, [=] {
            emit tickerEvent();
        });
        timer->start(60 * 1000);
    }
}

Session::~Session()
{
    qDebug() << Q_FUNC_INFO;
    setActive(false);
}

void Session::setContext(Context* context)
{
    if (m_context == context) return;
    m_context = context;
    emit contextChanged();
}

void Session::handleNotification(const QJsonObject& notification)
{
    emit notificationHandled(notification);

    const auto event = notification.value("event").toString();
    Q_ASSERT(!event.isEmpty());
    const auto value = notification.value(event);

    m_events[event] = value;
    emit eventsChanged();

    if (event == "network") {
        auto data = value.toObject();
        const auto current_state = data.value("current_state").toString();
        setConnected(current_state == "connected");
        emit networkEvent(data);
    } else if (event == "tor") {
        emit torEvent(value.toObject());
    } else if (event == "settings") {
        setSettings(value.toObject());
    } else if (event == "twofactor_reset") {
        emit twoFactorResetEvent(value.toObject());
    } else if (event == "block") {
        const auto block = value.toObject();
        setBlock(block);
        emit blockEvent(block);
    } else if (event == "transaction") {
        emit transactionEvent(value.toObject());
    } else if (event == "ticker") {
        emit tickerEvent();
    } else if (event == "subaccount") {
        emit subaccountEvent(value.toObject());
    } else {
        Q_UNREACHABLE();
    }
}

void Session::setConnected(bool connected)
{
    if (m_connected == connected) return;
    m_connected = connected;
    emit connectedChanged();
}

void Session::setConfig(const QJsonObject& config)
{
    if (m_config == config) return;
    m_config = config;
    emit configChanged();
}

void Session::setActive(bool active)
{
    if (m_active == active) return;
    m_active = active;
    emit activeChanged();
    update();
}

void Session::setEvents(const QJsonObject& events)
{
    if (m_events == events) return;
    m_events = events;
    emit eventsChanged();
}

void Session::setSettings(const QJsonObject& settings)
{
    if (m_settings == settings) return;
    m_settings = settings;
    setUnit(m_settings.value("unit").toString());
    setAltimeout(m_settings.value("altimeout").toInt());
    emit settingsChanged();
}

void Session::setCurrencies(const QJsonObject& currencies)
{
    if (m_currencies == currencies) return;
    m_currencies = currencies;
    emit currenciesChanged();
}

QString ComputeDisplayUnit(Network* network, QString unit)
{
    if (network->isMainnet()) {
        if (unit == "btc") {
            unit = "BTC";
        }
    } else {
        if (unit == "BTC" || unit == "btc") {
            unit = "TEST";
        } else if (unit == "mBTC") {
            unit = "mTEST";
        } else if (unit == "\u00B5BTC") {
            unit = "\u00B5TEST";
        } else if (unit == "bits") {
            unit = "bTEST";
        } else if (unit == "sats") {
            unit = "sTEST";
        }
    }
    if (network->isLiquid()) unit.prepend("L");
    return unit;
}

void Session::setUnit(const QString &unit)
{
    if (m_unit == unit) return;
    m_unit = unit;
    m_display_unit = ComputeDisplayUnit(m_network, m_unit);
    qDebug() << Q_FUNC_INFO << m_network->id() << m_unit;
    emit unitChanged();
}

void Session::setAltimeout(int altimeout)
{
    if (m_altimeout == altimeout) return;
    m_altimeout = altimeout;
    if (m_logout_timer != -1) {
        killTimer(m_logout_timer);
        m_logout_timer = -1;
    }
    if (m_altimeout > 0) {
        m_logout_timer = startTimer(m_altimeout * 60 * 1000);
        qApp->installEventFilter(this);
    } else {
        qApp->removeEventFilter(this);
    }
}

void Session::setUsername(const QString& username)
{
    if (m_username == username) return;
    m_username = username;
    emit usernameChanged();
}

AuthHandlerTask* Session::registerUser()
{
    Q_ASSERT(m_context);
    if (m_context->device()) {
        return new RegisterUserTask({}, m_context->m_hw_device, this);
    } else {
        return new RegisterUserTask(m_context->credentials(), {}, this);
    }
}

AuthHandlerTask* Session::login()
{
    Q_ASSERT(m_context);
    if (m_context->device()) {
        return new LoginTask(QJsonObject{}, m_context->m_hw_device, this);
    } else {
        return new LoginTask(m_context->credentials(), {}, this);
    }
}

void Session::setWalletHashId(const QString& wallet_hash_id)
{
    if (m_wallet_hash_id == wallet_hash_id) return;
    m_wallet_hash_id = wallet_hash_id;
    emit walletHashIdChanged();
}

void Session::timerEvent(QTimerEvent* event)
{
    if (event->timerId() == m_logout_timer) {
        killTimer(m_logout_timer);
        m_logout_timer = -1;
        emit autoLogoutTriggered();
    }
}

uint32_t Session::blockHeight() const
{
    return m_block.value("block_height").toDouble();
}

void Session::setBlock(const QJsonObject& block)
{
    if (m_block == block) return;
    m_block = block;
    emit blockChanged();
}

static QMutex g_session_mutex;
static int64_t g_session_id{0};
static QMap<int64_t, QPointer<Session>> g_sessions;

void Session::update()
{
    if (m_active && !m_session) {
        int rc = GA_create_session(&m_session);
        Q_ASSERT(rc == GA_OK);

        {
            QMutexLocker locker(&g_session_mutex);
            m_id = ++g_session_id;
            g_sessions[m_id] = this;
        }

        rc = GA_set_notification_handler(m_session, [](void* context, GA_json* details) {
            QMutexLocker locker(&g_session_mutex);
            const auto id = (int64_t) context;

            if (!g_sessions.contains(id)) return;
            if (g_sessions.value(id).isNull()) return;

            auto session = g_sessions.value(id).get();
            auto notification = Json::toObject(details);

            GA_destroy_json(details);
            QMetaObject::invokeMethod(session, [session, notification] {
                session->handleNotification(notification);
            }, Qt::QueuedConnection);
        }, (void*) m_id);
        Q_ASSERT(rc == GA_OK);
        return;
    }

    if (!m_active && m_session) {
        {
            QMutexLocker locker(&g_session_mutex);
            g_sessions.remove(m_id);
            m_id = 0;
        }

        GA_set_notification_handler(m_session, nullptr, nullptr);
        int rc = GA_destroy_session(m_session);
        m_session = nullptr;
        return;
    }
}

SessionActivity::SessionActivity(QObject* parent)
    : Activity(parent)
{
}

void SessionActivity::setSession(Session* session)
{
    Q_ASSERT(!m_session);
    m_session = session;
}

bool Session::eventFilter(QObject *object, QEvent *event)
{
    switch (event->type()) {
    case QEvent::MouseButtonPress:
    case QEvent::MouseButtonRelease:
    case QEvent::MouseButtonDblClick:
    case QEvent::MouseMove:
    case QEvent::KeyPress:
    case QEvent::KeyRelease:
    case QEvent::Wheel:
    {
        if (m_logout_timer != -1) {
            killTimer(m_logout_timer);
            m_logout_timer = startTimer(m_altimeout * 60 * 1000);
        }
        break;
    }
    default:
        break;
    }
    return QObject::eventFilter(object, event);
}
