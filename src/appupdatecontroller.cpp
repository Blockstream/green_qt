#include "appupdatecontroller.h"
#include "httpmanager.h"
#include "task.h"
#include "util.h"

#include <QTimer>

extern QCommandLineParser g_args;

class CheckForUpdatesTask : public HttpRequestTask
{
public:
    CheckForUpdatesTask(QObject* parent)
        : HttpRequestTask(parent)
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
    if (IsRunningAsFlatpak()) {
        qInfo() << "in-app check for update disabled in flatpak";
        return;
    }

    connect(m_timer, &QTimer::timeout, this, &AppUpdateController::checkNow);

    const auto period = g_args.value("updatecheckperiod").toInt();
    if (period > 0) {
        m_timer->setInterval(period * 1000);
        m_timer->start();
        checkNow();
    }
}

void AppUpdateController::checkNow()
{
    auto task = new CheckForUpdatesTask(this);
    connect(task, &Task::finished, this, [=, this] {
        task->deleteLater();
        const auto version = task->body().toJsonObject().value("version");
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
    connect(task, &Task::failed, this, [=, this] {
        task->deleteLater();
        qInfo() << "failed to fetch new version";
    });
    HttpManager::instance()->exec(task);
}

UpdateNotification::UpdateNotification(const QString& version, QObject* parent)
    : Notification(parent)
    , m_version(version)
{
    setDismissable(true);
}
