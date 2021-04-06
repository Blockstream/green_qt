#include "navigation.h"
#include <QUrl>
#include <QUrlQuery>

Navigation::Navigation(QObject *parent) : QObject(parent)
{

}

void Navigation::setLocation(const QString &location)
{
    if (m_location == location) return;
    m_location = location;
    emit locationChanged(m_location);
    QUrl url(location);
    setPath(url.path());
    QUrlQuery q(url);
    QVariantMap param;
    for (auto& pair : q.queryItems()) {
        if (pair.second == "true") {
            param.insert(pair.first, true);
        } else if (pair.second == "false") {
            param.insert(pair.first, false);
        } else {
            param.insert(pair.first, pair.second);
        }
    }
    setParam(param);
}

void Navigation::setPath(const QString& path)
{
    if (m_path == path) return;
    m_path = path;
    emit pathChanged(m_path);
}

void Navigation::setParam(const QVariantMap &param)
{
    if (m_param == param) return;
    m_param = param;
    emit paramChanged(m_param);
}

void Navigation::go(const QString &location, const QVariantMap &param)
{
    QUrl u(location);
    QUrlQuery q(u);
    for (auto i = param.constBegin(); i != param.constEnd(); ++i) {
        q.removeQueryItem(i.key());
        if (i.value() == QVariant::Invalid) continue;
        qDebug() << "SET PARMA" << i.key() << i.value() << i.value();
        if (i->type() == QVariant::StringList) {
            q.addQueryItem(i.key(), i.value().toStringList().join(','));
        } else {
            q.addQueryItem(i.key(), i.value().toString());
        }
    }
    u.setQuery(q);
    setLocation(u.toString());
}

void Navigation::set(const QVariantMap& param)
{
    go(m_location, param);
}

Route::Route(QObject *parent)
    : QObject(parent)
{

}

void Route::setLocation(const QString& location)
{
    if (m_location == location) return;
    setPrevious(m_location);
    m_location = location;
    emit locationChanged(m_location);
    update();
}

void Route::setPath(const QString& path)
{
    if (m_path == path) return;
    m_path = path;
    emit pathChanged(m_path);
    update();
}

void Route::update()
{
    QUrl u(m_location);
    setActive(!u.path().isEmpty() && !m_path.isEmpty() && u.path().indexOf(m_path) >= 0);
}

void Route::setPrevious(const QString& previous)
{
    if (m_active) return;
    if (m_previous == previous) return;
    m_previous = previous;
    emit previousChanged(m_previous);
}

void Route::setActive(bool active)
{
    if (m_active == active) return;
    m_active = active;
    emit activeChanged(m_active);
}
