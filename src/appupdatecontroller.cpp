#include "appupdatecontroller.h"
#include "httpmanager.h"
#include "httprequestactivity.h"

#include <QTimer>

extern QCommandLineParser g_args;

class CheckForUpdatesActivity : public HttpRequestActivity
{
public:
    CheckForUpdatesActivity(QObject* parent)
        : HttpRequestActivity(parent)
    {
        setMethod("GET");
        const auto channel = g_args.value("channel");
        if (channel == "latest") {
            const auto path = QString("/greenupdate/desktop/latest.json");
            addUrl(QString("https://blockstream.com") + path);
            addUrl(QString("http://blkstrmccjufnkm3otpwjso67apg3f4e53dxzz7nbvr5zg6kiicq2jqd.onion") + path);
        } else {
            const auto path = QString("/desktop/%1.json").arg(channel);
            addUrl(QString("https://greenupdate.blockstream.com") + path);
            addUrl(QString("http://greenupjcyad2xow7xmrunreetczmqje2nz6bdez3a5xhddlockoqryd.onion") + path);
        }
    }
};

AppUpdateController::AppUpdateController(QObject *parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
{
    m_timer->setInterval(12 * 60 * 60 * 1000);
    connect(m_timer, &QTimer::timeout, this, &AppUpdateController::checkNow);
    checkForUpdates();
}

void AppUpdateController::checkForUpdates()
{
    m_timer->start();
    checkNow();
}

void AppUpdateController::checkNow()
{
    auto activity = new CheckForUpdatesActivity(this);
    connect(activity, &CheckForUpdatesActivity::finished, this, [=] {
        activity->deleteLater();
        const auto version = activity->body().toJsonObject().value("version");
        if (version.isString()) {
            const auto app_version = QVersionNumber::fromString(qApp->applicationVersion());
            m_latest_version = version.toString();
            m_update_available = app_version < QVersionNumber::fromString(m_latest_version);
            if (m_update_available) m_timer->stop();
            emit latestVersionChanged();
            emit updateAvailableChanged();
            qInfo() << "new version" << m_latest_version;
        } else {
            qInfo() << "failed to check new version";
        }
    });
    connect(activity, &CheckForUpdatesActivity::failed, this, [=] {
        activity->deleteLater();
        qInfo() << "failed to fetch new version";
    });
    HttpManager::instance()->exec(activity);
}
