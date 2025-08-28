#include "applicationcontroller.h"
#include "config.h"
#include "util.h"

#include <QApplication>
#include <QDebug>
#include <QDir>
#include <QDirIterator>
#include <QEvent>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QNetworkAccessManager>
#include <QUrl>
#include <QQmlEngine>

ApplicationController::ApplicationController(QObject* parent)
    : QObject(parent)
{
    qApp->installEventFilter(this);
}

ApplicationController::~ApplicationController()
{
    qApp->removeEventFilter(this);
}

void ApplicationController::triggerQuit()
{
    qDebug() << Q_FUNC_INFO << m_quit_triggered;
    m_quit_triggered = true;
    emit quitTriggered();
}

void ApplicationController::quit()
{
    qDebug() << Q_FUNC_INFO << m_quit_triggered;
    qApp->removeEventFilter(this);
    qApp->quit();
}

void ApplicationController::triggerCrash()
{
    qDebug() << Q_FUNC_INFO;
    abort();
}

bool SentryPayloadFromMinidump(const QString& path, QByteArray& envelope);

void ApplicationController::reportCrashes()
{
#ifdef ENABLE_SENTRY
    qDebug() << Q_FUNC_INFO;

    auto engine = qmlEngine(this);
    if (!engine) {
        qDebug() << Q_FUNC_INFO << "engine not set";
        return;
    }
    auto net = engine->networkAccessManager();
    if (!net) {
        qDebug() << Q_FUNC_INFO << "network access manager not set";
        return;
    }

    QDir completed(GetDataDir("crashpad"));
    completed.mkdir("completed");
    completed.cd("completed");
    QDir pending(GetDataDir("crashpad"));
#if defined(Q_OS_WINDOWS)
    pending.cd("reports");
#else
    pending.cd("pending");
#endif
    while (true) {
        QDirIterator it(pending.absolutePath(), QDir::Files, QDirIterator::NoIteratorFlags);
        if (!it.hasNext()) break;
        QFileInfo info(it.next());
        const auto minidump_path = completed.absoluteFilePath(info.fileName());
        QFile::rename(info.absoluteFilePath(), minidump_path);
        qDebug() << Q_FUNC_INFO << minidump_path;
        QByteArray envelope;
        if (SentryPayloadFromMinidump(minidump_path, envelope)) {
            QUrl url("https://sentry.blockstream.io/api/2/envelope/");
            QNetworkRequest req(url);
            req.setRawHeader("Content-Type", "application/json");
            req.setRawHeader("X-Sentry-Auth", "Sentry sentry_key=" SENTRY_KEY);

            auto reply = net->post(req, envelope);

            connect(reply, &QNetworkReply::finished, this, [=] {
                qDebug() << Q_FUNC_INFO << reply->readAll();
                reply->deleteLater();
            });
        }
        QFile::remove(minidump_path);
    }
#endif
}

bool ApplicationController::eventFilter(QObject* obj, QEvent* event)
{
    if (event->type() == QEvent::Quit) {
        if (!m_quit_triggered) {
            emit quitRequested();
            return true;
        }
    }
    return QObject::eventFilter(obj, event);
}
