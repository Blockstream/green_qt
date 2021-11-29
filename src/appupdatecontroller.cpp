#include "activitymanager.h"
#include "appupdatecontroller.h"
#include "network.h"
#include "networkmanager.h"
#include "semver.h"

AppUpdateController::AppUpdateController(QObject *parent)
    : QObject(parent)
{
}

void AppUpdateController::checkForUpdates()
{
    if (!m_session) {
        auto network = NetworkManager::instance()->network("mainnet");
        m_session = new Session(network, this);
        m_session->setActive(true);
        m_session.track(connect(m_session, &Session::connectedChanged, this, [this] {
            if (!m_session->isConnected()) return;
            qDebug("session connected, now check for updates");
            checkForUpdates();
        }));
        return;
    }

    auto activity = new CheckForUpdatesActivity(m_session);
    connect(activity, &CheckForUpdatesActivity::finished, this, [=] {
        activity->deleteLater();
        m_latest_version = activity->latestVersion();
        m_update_available = SemVer::parse(qApp->applicationVersion()) < SemVer::parse(m_latest_version);
        emit latestVersionChanged(m_latest_version);
        emit updateAvailableChanged(m_update_available);
        m_session.destroy();
    });
    ActivityManager::instance()->exec(activity);
}

extern QCommandLineParser g_args;

CheckForUpdatesActivity::CheckForUpdatesActivity(Session* session)
    : HttpRequestActivity(session)
{
    auto channel = g_args.value("channel");

    setMethod("GET");
    addUrl(QString("https://greenupdate.blockstream.com/desktop/%1.json").arg(channel));
    addUrl(QString("http://greenupjcyad2xow7xmrunreetczmqje2nz6bdez3a5xhddlockoqryd.onion/desktop/%1.json").arg(channel));
}

QString CheckForUpdatesActivity::latestVersion() const
{
    const auto body = response().value("body").toString();
    QJsonObject latest = QJsonDocument::fromJson(body.toUtf8()).object();
    qDebug() << latest;
    return latest["version"].toString();
}
