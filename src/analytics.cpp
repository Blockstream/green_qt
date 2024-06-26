#include "analytics.h"

#include <QCryptographicHash>
#include <QDebug>
#include <QFile>
#include <QGuiApplication>
#include <QRandomGenerator>
#include <QScreen>
#include <QSettings>
#include <QSysInfo>
#include <QTcpSocket>
#include <QThread>
#include <QUuid>

#include <map>
#include <memory>
#include <string>

#include <countly/countly.hpp>

#include <gdk.h>

#include "config.h"
#include "json.h"
#include "networkmanager.h"
#include "session.h"
#include "sessionmanager.h"
#include "settings.h"
#include "util.h"
#include "walletmanager.h"

class AnalyticsPrivate : public QObject
{
    Analytics* const q;
public:
    AnalyticsPrivate(Analytics* const q) : q(q) {}

    Session* session{nullptr};
    std::atomic_bool active{false};
    std::chrono::seconds timestamp_offset{0};
    struct View {
        std::string name;
        std::map<std::string, std::string> segmentation;
        std::string id;
    };
    std::map<std::string, View> views;
    QThread thread;
    std::atomic_int busy{0};

    void start();
    void stop(Qt::ConnectionType type = Qt::AutoConnection);
    void restart();
    void updateCustomUserDetails();
    void updateRemoteConfig();
};

static Analytics* g_analytics_instance{nullptr};

namespace {
inline constexpr char COUNTLY_HOST[] = "https://countly.blockstream.com";
inline constexpr char COUNTLY_TOR_ENDPOINT[] = "http://greciphd2z3eo6bpnvd6mctxgfs4sslx4hyvgoiew4suoxgoquzl72yd.onion";
inline constexpr char COUNTLY_APP_KEY_DEV[] = "cb8e449057253add71d2f9b65e5f66f73c073e63";
inline constexpr char COUNTLY_APP_KEY_REL[] = "351d316234a4a83169fecd7e760ef64bfd638d21";

std::map<std::string, std::string> QVariantMapToStdMap(const QVariantMap& in)
{
    std::map<std::string, std::string> out;
    for (auto i = in.begin(); i != in.end(); ++i) {
        out[i.key().toStdString()] = i.value().toString().toStdString();
    }
    return out;
}
}

Analytics::Analytics()
    : QObject(nullptr)
    , d(new AnalyticsPrivate(this))
{
    Q_ASSERT(!g_analytics_instance);
    g_analytics_instance = this;
}

void Analytics::start()
{
    d->moveToThread(&d->thread);
    d->thread.start();

    auto os = QSysInfo::productType().toStdString();
    auto os_version = QSysInfo::productVersion().toStdString();
    auto device = GetHardwareModel().toStdString();
    auto screen_size = qGuiApp->primaryScreen()->size();
    auto resolution = QString("%1x%2").arg(screen_size.width()).arg(screen_size.height()).toStdString();
    auto& countly = cly::Countly::getInstance();
    countly.setLogger([](cly::LogLevel level, const std::string& message) {
        switch (level) {
        case cly::LogLevel::INFO:    qInfo() << qPrintable(QString::fromStdString(message)); break;
        case cly::LogLevel::WARNING: qWarning() << qPrintable(QString::fromStdString(message)); break;
        case cly::LogLevel::ERROR:   qFatal("%s\n", message.c_str()); break;
        case cly::LogLevel::FATAL:   qFatal("%s\n", message.c_str()); break;
        case cly::LogLevel::DEBUG:   break;
        default: break;
        }
    });

    countly.setSha256([](const std::string& salted_data) {
        QCryptographicHash hash(QCryptographicHash::Sha256);
        hash.addData(QByteArray::fromStdString(salted_data));
        return hash.result().toStdString();
    });

    countly.setRemoteConfigCallback([=](bool success) {
        QMetaObject::invokeMethod(this, [=] {
            if (success) {
                emit remoteConfigChanged();
            }
        });
    });

    countly.setHTTPClient([=](bool use_post, const std::string& path, const std::string& data) {
        incrBusy();
        cly::HTTPResponse res{false, {}};

        {
            if (!d->session) {
                const auto network = NetworkManager::instance()->network("mainnet");
                d->session = SessionManager::instance()->create(network);
                qDebug() << "analytics: create session";
                d->session->setActive(true);
            }
        }

        QJsonObject req;
        if (use_post) {
            QJsonArray urls;
            urls.append(QString::fromStdString(COUNTLY_HOST + path));
            urls.append(QString::fromStdString(COUNTLY_TOR_ENDPOINT + path));
            QJsonObject headers;
#define POST_APPLICATION_JSON 0
#if POST_APPLICATION_JSON
            headers.insert("content-type", "application/json");
            QUrlQuery q(QString::fromStdString(data));
            QJsonObject body;
            const auto query_items = q.queryItems();
            for (const auto& kv : query_items) {
                auto doc = QJsonDocument::fromJson(QUrl::fromPercentEncoding(kv.second.toUtf8()).toUtf8().replace("\\\"", "\""));
                if (doc.isNull()) {
                    body.insert(kv.first, kv.second);
                } else if (doc.isObject()) {
                    body.insert(kv.first, doc.object());
                } else if (doc.isArray()) {
                    body.insert(kv.first, doc.array());
                }
            }
#else
            headers.insert("content-type", "application/x-www-form-urlencoded");
            const auto body = QString::fromStdString(data);
#endif
            req.insert("method", "POST");
            req.insert("headers", headers);
            req.insert("urls", urls);
            req.insert("data", body);
        } else {
            QJsonArray urls;
            urls.append(QString::fromStdString(COUNTLY_HOST + path + "?" + data));
            urls.append(QString::fromStdString(COUNTLY_TOR_ENDPOINT + path + "?" + data));
            req.insert("method", "GET");
            req.insert("urls", urls);
        }

        GA_json* out = nullptr;
        const auto rc = GA_http_request(d->session->m_session, Json::fromObject(req).get(), &out);
        if (rc == GA_OK && out) {
            auto reply = Json::toObject(out);

            try {
                res.data = nlohmann::json::parse(reply.value("body").toString().toStdString());
                res.success = true;
            } catch (...) {
            }

            GA_destroy_json(out);
        }

        decrBusy();

        return res;
    });

    countly.SetMetrics(os, os_version, device, resolution, "N/A", QCoreApplication::applicationVersion().toStdString());
    countly.alwaysUsePost(true);

    connect(WalletManager::instance(), &WalletManager::changed, d, &AnalyticsPrivate::updateCustomUserDetails);
    auto settings = Settings::instance();
    connect(settings, &Settings::useTorChanged, d, &AnalyticsPrivate::restart);
    connect(settings, &Settings::useProxyChanged, d, &AnalyticsPrivate::restart);
    connect(settings, &Settings::proxyHostChanged, d, &AnalyticsPrivate::restart);
    connect(settings, &Settings::proxyPortChanged, d, &AnalyticsPrivate::restart);
    connect(settings, &Settings::analyticsChanged, d, &AnalyticsPrivate::restart);

    countly.enableRemoteConfig();

    d->start();
}

QJsonValue Analytics::getRemoteConfigValue(const QString &key) const
{
    auto& countly = cly::Countly::getInstance();
    const nlohmann::json value = countly.getRemoteConfigValue(key.toStdString());
    if (value.is_null()) {
        return {};
    } else if (value.is_array()) {
        return Json::toArray((const GA_json*) &value);
    } else {
        qDebug() << Q_FUNC_INFO << key << value.type_name();
        Q_UNIMPLEMENTED();
        return {};
    }
}

void AnalyticsPrivate::updateCustomUserDetails()
{
    std::map<std::string, std::string> user_details;
    user_details["total_wallets"] = std::to_string(WalletManager::instance()->size());
    cly::Countly::getInstance().setCustomUserDetails(user_details);
}

bool Analytics::isBusy() const
{
    return d->busy > 0;
}

void Analytics::incrBusy()
{
    d->busy ++;
    QMetaObject::invokeMethod(this, &Analytics::busyChanged, Qt::QueuedConnection);
}

void Analytics::decrBusy()
{
    d->busy --;
    QMetaObject::invokeMethod(this, &Analytics::busyChanged, Qt::QueuedConnection);
}

void AnalyticsPrivate::start()
{
    QString device_id;
    {
        QSettings analytics(GetDataFile("app", "analytics.ini"), QSettings::IniFormat);

        device_id = analytics.value("device_id").toString();
        if (device_id.isEmpty()) {
            device_id = QUuid::createUuid().toString(QUuid::WithoutBraces);
            analytics.setValue("device_id", device_id);
        }

        auto to = analytics.value("timestamp_offset").toInt();
        if (to == 0) {
            to = QRandomGenerator::global()->bounded(12 * 3600);
            analytics.setValue("timestamp_offset", to);
        }
        timestamp_offset = std::chrono::seconds(to);
    }

    q->incrBusy();
    QMetaObject::invokeMethod(this, [=] {
        const bool is_production = QStringLiteral("Production") == GREEN_ENV;
        auto& countly = cly::Countly::getInstance();
        countly.setDeviceID(device_id.toStdString(), false);
        countly.setTimestampOffset(timestamp_offset);
        static bool started = false;
        if (!started) {
            countly.start(is_production ? COUNTLY_APP_KEY_REL : COUNTLY_APP_KEY_DEV, COUNTLY_HOST, 443, true);
            started = true;
        }

        QMetaObject::invokeMethod(q, [=] {
            active = true;
            updateCustomUserDetails();
            q->decrBusy();
        });
    });
}

void AnalyticsPrivate::stop(Qt::ConnectionType type)
{
    if (!active) return;
    active = false;
    if (!Settings::instance()->isAnalyticsEnabled()) {
        QFile::remove(GetDataFile("app", "analytics.ini"));
    }
    q->incrBusy();
    QMetaObject::invokeMethod(this, [=] {
        auto& countly = cly::Countly::getInstance();
        countly.stop();
        delete session;
        session = nullptr;
        QMetaObject::invokeMethod(q, [=] {
            q->decrBusy();
        });
    }, type);
}

void AnalyticsPrivate::restart()
{
    stop();
    start();
}

Analytics::~Analytics()
{
    d->stop(Qt::BlockingQueuedConnection);
    d->thread.quit();
    d->thread.wait();
    delete d;
    g_analytics_instance = nullptr;
}

Analytics* Analytics::instance()
{
    Q_ASSERT(g_analytics_instance);
    return g_analytics_instance;
}

bool Analytics::isActive() const { return d->active; }

void Analytics::recordEvent(const QString& name)
{
    recordEvent(name, {});
}

void Analytics::recordEvent(const QString& name, const QVariantMap& segmentation)
{
    if (Settings::instance()->isAnalyticsEnabled()) {
        auto& countly = cly::Countly::getInstance();
        countly.RecordEvent(name.toStdString(), QVariantMapToStdMap(segmentation), 1);
    }
}

QString Analytics::pushView(const QString& name, const QVariantMap& segmentation)
{
    auto& countly = cly::Countly::getInstance();
    AnalyticsPrivate::View view;
    view.name = name.toStdString();
    view.segmentation = QVariantMapToStdMap(segmentation);
    view.id = countly.views().openView(view.name, view.segmentation);
    d->views[view.id] = view;
    return QString::fromStdString(view.id);
}

void Analytics::popView(const QString& id)
{
    auto& countly = cly::Countly::getInstance();
    auto it = d->views.find(id.toStdString());
    if (it == d->views.end()) return;
    auto& view = it->second;
    countly.views().closeViewWithID(view.id);
    d->views.erase(it);
}

std::chrono::seconds Analytics::timestampOffset() const
{
    return d->timestamp_offset;
}

AnalyticsView::AnalyticsView(QObject* parent)
    : QObject(parent)
{
    connect(Settings::instance(), &Settings::analyticsChanged, this, &AnalyticsView::reset);
}

AnalyticsView::~AnalyticsView()
{
    close();
}

void AnalyticsView::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged();
    reset();
}

void AnalyticsView::setSegmentation(const QVariantMap& segmentation)
{
    if (m_segmentation == segmentation) return;
    m_segmentation = segmentation;
    emit segmentationChanged();
    reset();
}

void AnalyticsView::setActive(bool active)
{
    if (m_active == active) return;
    m_active = active;
    emit activeChanged();
    reset();
}

void AnalyticsView::reset()
{
    if (m_reset_timer > 0) killTimer(m_reset_timer);
    m_reset_timer = startTimer(1000);
}

void AnalyticsView::close()
{
    if (!m_id.isEmpty()) {
        Analytics::instance()->popView(m_id);
        m_id.clear();
    }
}

void AnalyticsView::open()
{
    if (Settings::instance()->isAnalyticsEnabled() && m_active && !m_name.isEmpty()) {
        m_id = Analytics::instance()->pushView(m_name, m_segmentation);
    }
}

void AnalyticsView::timerEvent(QTimerEvent* event)
{
    if (event->timerId() == m_reset_timer) {
        killTimer(m_reset_timer);
        m_reset_timer = 0;
        close();
        open();
    }
}

class AnalyticsEventPrivate {
public:
    QString name;
    QVariantMap segmentation;
    bool active{false};
    std::unique_ptr<cly::Event> event;
    int reset_timer{0};
};

AnalyticsEvent::AnalyticsEvent(QObject* parent)
    : QObject(parent)
    , d(new AnalyticsEventPrivate)
{
}

AnalyticsEvent::~AnalyticsEvent()
{
    stop();
}

QString AnalyticsEvent::name() const
{
    return d->name;
}

void AnalyticsEvent::setName(const QString& name)
{
    if (d->name == name) return;
    d->name = name;
    emit nameChanged();
    reset();
}

QVariantMap AnalyticsEvent::segmentation() const
{
    return d->segmentation;
}

void AnalyticsEvent::setSegmentation(const QVariantMap& segmentation)
{
    if (d->segmentation == segmentation) return;
    d->segmentation = segmentation;
    emit segmentationChanged();
}

bool AnalyticsEvent::active() const
{
    return d->active;
}

void AnalyticsEvent::setActive(bool active)
{
    if (d->active == active) return;
    d->active = active;
    emit activeChanged();
    reset();
}

void AnalyticsEvent::reset()
{
    if (d->reset_timer > 0) killTimer(d->reset_timer);
    d->reset_timer = startTimer(0);
}

void AnalyticsEvent::stop()
{
    if (d->event) {
        d->event.reset();
    }
}

void AnalyticsEvent::start()
{
    if (Settings::instance()->isAnalyticsEnabled() && d->active && !d->name.isEmpty()) {
        Q_ASSERT(!d->event);
        auto event = new cly::Event(d->name.toStdString());
        event->setTimestampOffset(Analytics::instance()->timestampOffset());
        event->startTimer();
        d->event.reset(event);
    }
}

void AnalyticsEvent::timerEvent(QTimerEvent* event)
{
    if (event->timerId() == d->reset_timer) {
        killTimer(d->reset_timer);
        d->reset_timer = 0;
        stop();
        start();
    }
}

void AnalyticsEvent::track()
{
    if (d->event) {
        d->event->stopTimer();
    } else {
        auto event = new cly::Event(d->name.toStdString());
        event->stamp(cly::Countly::getInstance().getTimestamp());
        d->event.reset(event);
    }
    std::map<std::string, std::string> out;
    for (auto i = d->segmentation.begin(); i != d->segmentation.end(); ++i) {
        d->event->addSegmentation(i.key().toStdString(), i.value().toString().toStdString());
    }
    cly::Countly::getInstance().addEvent(*d->event);
    stop();
    start();
}

AnalyticsAlert::AnalyticsAlert(QObject* parent)
    : QObject(parent)
{
    connect(Analytics::instance(), &Analytics::remoteConfigChanged, this, &AnalyticsAlert::update);
}

void AnalyticsAlert::setScreen(const QString& screen)
{
    if (m_screen == screen) return;
    m_screen = screen;
    emit screenChanged();
    update();
}

void AnalyticsAlert::setNetwork(const QString& network)
{
    if (m_network == network.toLower()) return;
    m_network = network.toLower();
    emit networkChanged();
    update();
}

QString AnalyticsAlert::title() const
{
    return m_data.value("title").toString();
}

QString AnalyticsAlert::message() const
{
    return m_data.value("message").toString();
}

QString AnalyticsAlert::link() const
{
    return m_data.value("link").toString();
}

bool AnalyticsAlert::isDismissable() const
{
    return m_data.value("dismissable").toBool();
}

void AnalyticsAlert::setNotification(AnalyticsAlertNotification* notification)
{
    if (m_notification == notification) return;
    if (m_notification) {
        m_notification->deleteLater();
        m_notification = nullptr;
        emit notificationChanged();
    }
    if (notification) {
        m_notification = notification;
        emit notificationChanged();
    }
}

void AnalyticsAlert::update()
{
    const auto banners = Analytics::instance()->getRemoteConfigValue("banners");
    if (!banners.isArray()) return;

    const auto alerts = banners.toArray();

    for (const QJsonValue &a : alerts) {
        QJsonObject alert = a.toObject();

        bool matches_screen = false;

        for (const QJsonValue &s : alert["screens"].toArray()) {
            if (s.toString() == m_screen) {
                matches_screen = true;
                break;
            }
        }

        if (!matches_screen) continue;

        const auto networks = alert["networks"].toArray();
        bool matches_network = networks.size() == 0;

        for (const QJsonValue &s : alert["networks"].toArray()) {
            if (s.toString() == m_network) {
                matches_network = true;
                break;
            }
        }

        if (!matches_network) continue;

        if (m_data != alert) {
            m_data = alert;
            emit dataChanged();

            if (m_data.isEmpty()) {
                setNotification(nullptr);
            } else {
                setNotification(new AnalyticsAlertNotification(this));
            }
        }

        return;
    }
}

AnalyticsRemoteConfig::AnalyticsRemoteConfig(QObject* parent)
    : QObject(parent)
{
    connect(Analytics::instance(), &Analytics::remoteConfigChanged, this, &AnalyticsRemoteConfig::update);
}

void AnalyticsRemoteConfig::setKey(const QString& key)
{
    if (m_key == key) return;
    m_key = key;
    emit keyChanged();
    update();
}

void AnalyticsRemoteConfig::setValue(const QJsonValue& value)
{
    if (m_value == value) return;
    m_value = value;
    emit valueChanged();
}

void AnalyticsRemoteConfig::update()
{
    const auto value = Analytics::instance()->getRemoteConfigValue(m_key);
    setValue(value);
}

AnalyticsAlertNotification::AnalyticsAlertNotification(AnalyticsAlert* alert)
    : Notification(alert)
    , m_alert(alert)
{
    setDismissable(alert->isDismissable());
}
