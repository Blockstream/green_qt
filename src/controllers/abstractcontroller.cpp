#include "abstractcontroller.h"

AbstractController::AbstractController(QObject* parent)
    : Entity(parent)
{
}

bool AbstractController::updateError(const QString &key, const QVariant &value, bool when)
{
    if (when) {
        setError(key, value);
        return true;
    } else {
        clearError(key);
        return false;
    }
}

void AbstractController::setError(const QString &key, const QVariant &value)
{
    Q_ASSERT(!value.isNull());
    if (m_errors.contains(key) && m_errors.value(key) == value) return;
    m_errors[key] = value;
    emit errorsChanged();
}

void AbstractController::clearError(const QString &key)
{
    if (!m_errors.contains(key)) return;
    m_errors.remove(key);
    emit errorsChanged();
}

void AbstractController::clearErrors()
{
    if (m_errors.empty()) return;
    m_errors.clear();
    emit errorsChanged();
}
