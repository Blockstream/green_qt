#include "navigation.h"
#include <QUrl>
#include <QUrlQuery>

Navigation::Navigation(QObject *parent) : QObject(parent)
{
}

void Navigation::setLocation(const QString &location)
{
    if (m_location == location) return;
    if (!m_location.isEmpty()) {
        m_history.removeAll(location);
        m_history.removeAll(m_location);
        m_history.push(m_location);
    }
    updateLocation(location);
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
        if (i->type() == QVariant::StringList) {
            q.addQueryItem(i.key(), i.value().toStringList().join(','));
        } else {
            q.addQueryItem(i.key(), i.value().toString());
        }
    }
    u.setQuery(q);
    setLocation(u.toString());
}

void Navigation::pop()
{
    if (m_history.isEmpty()) return;
    updateLocation(m_history.pop());
}

void Navigation::updateLocation(const QString& location)
{
    m_location = location;
    emit locationChanged(m_location);
    QUrl url(m_location);
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

void Navigation::set(const QVariantMap& param)
{
    go(m_location, param);
}

