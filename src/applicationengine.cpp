#include "applicationengine.h"

#include <QDir>
#include <QFileInfo>
#include <QQmlContext>
#include <QUrl>

ApplicationEngine::ApplicationEngine(QObject* parent)
    : QQmlApplicationEngine(parent)
{
#ifdef QT_DEBUG
    setBaseUrl(QUrl::fromLocalFile(QDir(__PWD__).absoluteFilePath("src/")));
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
