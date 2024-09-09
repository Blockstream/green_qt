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
    connect(m_timer, &QTimer::timeout, this, &AppUpdateController::checkNow);

    const auto period = g_args.value("updatecheckperiod").toInt();
    if (period > 0) {
        m_timer->setInterval(period * 1000);
        m_timer->start();
    }
}

void AppUpdateController::checkNow()
{
    auto activity = new CheckForUpdatesActivity(this);
    connect(activity, &CheckForUpdatesActivity::finished, this, [=] {
        activity->deleteLater();
        const auto version = activity->body().toJsonObject().value("version");
        if (version.isString()) {
            const auto app_version = QVersionNumber::fromString(qApp->applicationVersion());
            const bool update_available = app_version < QVersionNumber::fromString(version.toString());
            if (update_available) {
                if (m_notification) {
                    if (m_notification->version() == version.toString()) return;
                    m_notification->deleteLater();
                }
                qInfo() << "new version" << version.toString();
                m_notification = new UpdateNotification(version.toString(), this);
                emit notificationChanged();
            }
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

UpdateNotification::UpdateNotification(const QString& version, QObject* parent)
    : Notification(parent)
    , m_version(version)
{
}
