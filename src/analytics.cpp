#include "analytics.h"
#include "httpmanager.h"
#include "httprequestactivity.h"
#include "settings.h"
#include "util.h"

#include <countly/countly.hpp>

#include <QCryptographicHash>
#include <QDebug>
#include <QGuiApplication>
#include <QScreen>
#include <QSysInfo>
#include <QThread>

static Analytics* g_analytics_instance{nullptr};

namespace {
const std::string COUNTLY_HOST = "https://countly.blockstream.com";
const std::string COUNTLY_APP_KEY = "cb8e449057253add71d2f9b65e5f66f73c073e63";

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
{
    Q_ASSERT(!g_analytics_instance);
    g_analytics_instance = this;

    auto os = QSysInfo::productType().toStdString();
    auto os_version = QSysInfo::productVersion().toStdString();
    auto device = GetHardwareModel().toStdString();
    auto screen_size = qGuiApp->primaryScreen()->size();
    auto resolution = QString("%1x%2").arg(screen_size.width()).arg(screen_size.height()).toStdString();
    auto device_id = QString::fromLocal8Bit(QSysInfo::machineUniqueId().toHex()).toStdString();

    auto& countly = cly::Countly::getInstance();
    countly.setLogger([](cly::Countly::LogLevel level, const std::string& message) {
        switch (level) {
        case cly::Countly::DEBUG:   qDebug() << QString::fromStdString(message); break;
        case cly::Countly::INFO:    qInfo() << QString::fromStdString(message); break;
        case cly::Countly::WARNING: qWarning() << QString::fromStdString(message); break;
        case cly::Countly::ERROR:   qCritical() << QString::fromStdString(message); break;
        case cly::Countly::FATAL:   qFatal("%s\n", message.c_str()); break;
        }
    });

    countly.setSha256([](const std::string& salted_data) {
        QCryptographicHash hash(QCryptographicHash::Sha256);
        hash.addData(QByteArray::fromStdString(salted_data));
        return hash.result().toStdString();
    });

    countly.setHTTPClient([](bool use_post, const std::string& path, const std::string& data) {
        cly::Countly::HTTPResponse res{false, {}};

        auto activity = new HttpRequestActivity;
        if (use_post) {
            activity->setMethod("POST");
            activity->addUrl(QString::fromStdString(COUNTLY_HOST + path));
            activity->setData(QString::fromStdString(data));
        } else {
            activity->setMethod("GET");
            activity->addUrl(QString::fromStdString(COUNTLY_HOST + path + "?" + data));
        }

        QEventLoop loop;
        QObject::connect(activity, &HttpRequestActivity::finished, &loop, &QEventLoop::quit);

        QTimer timer;
        timer.setInterval(100);
        timer.start();
        QObject::connect(&timer, &QTimer::timeout, &timer, [&] {
            if (!Analytics::instance()->isActive()) {
                timer.stop();
                loop.exit(1);
            }
        });

        HttpManager::instance()->exec(activity);

        if (!loop.exec()) {
            res.success = true;
            res.data = nlohmann::json::parse(activity->response().value("body").toString().toStdString());
        }

        return res;
    });

    countly.SetMetrics(os, os_version, device, resolution, "N/A", QCoreApplication::applicationVersion().toStdString());
    countly.setDeviceID(device_id, true);
    countly.SetMaxEventsPerMessage(40);
    countly.SetMinUpdatePeriod(10000);
    check();

    connect(Settings::instance(), &Settings::analyticsChanged, this, &Analytics::check);
}

void Analytics::check()
{
    if (Settings::instance()->isAnalyticsEnabled()) {
        start();
    } else {
        stop();
    }
}

void Analytics::start()
{
    auto& countly = cly::Countly::getInstance();
    countly.start(COUNTLY_APP_KEY, COUNTLY_HOST, 443, true);
    m_active = true;
}

void Analytics::stop()
{
    auto& countly = cly::Countly::getInstance();
    m_active = false;
    countly.stop();
}

Analytics::~Analytics()
{
    stop();
    g_analytics_instance = nullptr;
}

Analytics* Analytics::instance()
{
    Q_ASSERT(g_analytics_instance);
    return g_analytics_instance;
}

void Analytics::recordEvent(const QString& name, const QVariantMap& segmentation)
{
    if (Settings::instance()->isAnalyticsEnabled()) {
        auto& countly = cly::Countly::getInstance();
        countly.RecordEvent(name.toStdString(), QVariantMapToStdMap(segmentation), 1);
    }
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
    if (!m_id.empty()) {
        cly::Countly::getInstance().views().closeViewWithID(m_id);
        m_id.clear();
    }
}

void AnalyticsView::open()
{
    if (Settings::instance()->isAnalyticsEnabled() && m_active && !m_name.isEmpty()) {
        const auto name = m_name.toStdString();
        const auto segmentation = QVariantMapToStdMap(m_segmentation);
        auto& countly = cly::Countly::getInstance();
        m_id = countly.views().openView(name, segmentation);
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
