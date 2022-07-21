#include "appupdatecontroller.h"
#include "httpmanager.h"
#include "semver.h"

AppUpdateController::AppUpdateController(QObject *parent)
    : QObject(parent)
{
}

void AppUpdateController::checkForUpdates()
{
    auto activity = new CheckForUpdatesActivity(this);
    connect(activity, &CheckForUpdatesActivity::finished, this, [=] {
        activity->deleteLater();
        m_latest_version = activity->latestVersion();
        m_update_available = SemVer::parse(qApp->applicationVersion()) < SemVer::parse(m_latest_version);
        emit latestVersionChanged(m_latest_version);
        emit updateAvailableChanged(m_update_available);
    });

    HttpManager::instance()->exec(activity);
}

extern QCommandLineParser g_args;

CheckForUpdatesActivity::CheckForUpdatesActivity(QObject* parent)
    : HttpRequestActivity(parent)
{
    auto channel = g_args.value("channel");

    setMethod("GET");
    addUrl(QString("https://greenupdate.blockstream.com/desktop/%1.json").arg(channel));
    addUrl(QString("http://greenupjcyad2xow7xmrunreetczmqje2nz6bdez3a5xhddlockoqryd.onion/desktop/%1.json").arg(channel));
}

QString CheckForUpdatesActivity::latestVersion() const
{
    QJsonObject latest = QJsonDocument::fromJson(body().toUtf8()).object();
    qDebug() << latest;
    return latest["version"].toString();
}
