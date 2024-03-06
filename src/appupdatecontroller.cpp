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
        auto channel = g_args.value("channel");

        setMethod("GET");
        addUrl(QString("https://greenupdate.blockstream.com/desktop/%1.json").arg(channel));
        addUrl(QString("http://greenupjcyad2xow7xmrunreetczmqje2nz6bdez3a5xhddlockoqryd.onion/desktop/%1.json").arg(channel));
    }
    QString latestVersion() const
    {
        const QJsonObject latest = body().toJsonObject();
        return latest["version"].toString();
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
    qInfo() << "check for new version";
    auto activity = new CheckForUpdatesActivity(this);
    connect(activity, &CheckForUpdatesActivity::finished, this, [=] {
        activity->deleteLater();
        const auto app_version = QVersionNumber::fromString(qApp->applicationVersion());
        m_latest_version = activity->latestVersion();
        m_update_available = app_version < QVersionNumber::fromString(m_latest_version);
        if (m_update_available) m_timer->stop();
        emit latestVersionChanged();
        emit updateAvailableChanged();
    });

    HttpManager::instance()->exec(activity);
}
