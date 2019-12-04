#include "applicationengine.h"

#include <QDir>
#include <QFileInfo>
#include <QQmlContext>
#include <QUrl>
#include <QFileSystemWatcher>

ApplicationEngine::ApplicationEngine(QObject* parent)
    : QQmlApplicationEngine(parent)
{
#ifdef QT_DEBUG
    setBaseUrl(QUrl::fromLocalFile(QDir(__PWD__).absoluteFilePath("src/")));
    QFileSystemWatcher* watcher = new QFileSystemWatcher(this);
    watcher->addPath(QDir(__PWD__).absoluteFilePath("src/"));
    connect(watcher, &QFileSystemWatcher::directoryChanged, this, &ApplicationEngine::sourceChanged);
    connect(watcher, &QFileSystemWatcher::fileChanged, this, &ApplicationEngine::sourceChanged);
#else
    setBaseUrl(QUrl("qrc:/"));
#endif
    rootContext()->setContextProperty("engine", this);
}

bool ApplicationEngine::isDebug() const
{
#ifdef QT_DEBUG
    return true;
#else
    return false;
#endif
}

void ApplicationEngine::clearCache()
{
#ifdef QT_DEBUG
    clearComponentCache();
#endif
}
