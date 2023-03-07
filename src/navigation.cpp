#include "navigation.h"

Navigation::Navigation(QObject *parent) : QObject(parent)
{
}

QString Navigation::description() const
{
    QStringList parts;
    for (auto i = m_param.begin(); i != m_param.end(); ++i) {
        parts.append(i.key() + "=" + i.value().toString());
    }
    return parts.join(" ");
}

void Navigation::push(const QVariantMap &param)
{
    if (param == m_param) return;
    m_history.removeAll(param);
    m_history.removeAll(m_param);
    m_history.push(m_param);
    m_param = param;
//    qDebug() << Q_FUNC_INFO << description();
    emit paramChanged();
}

void Navigation::pop()
{
    if (m_history.isEmpty()) return;
    m_param = m_history.pop();
    emit paramChanged();
}

void Navigation::set(const QVariantMap& param)
{
    auto new_param = m_param;
    for (auto i = param.begin(); i != param.end(); ++i) {
        if (i.value().isNull()) {
            new_param.remove(i.key());
        } else {
            new_param[i.key()] = i.value();
        }
    }
    push(new_param);
}

