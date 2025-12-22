#include "context.h"
#include "payment.h"

Payment::Payment(Context* context)
    : QObject(context)
    , m_context(context)
{
}

void Payment::update(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged();
    setUpdatedAt(QDateTime::fromString(m_data.value("updatedAt").toString(), Qt::ISODateWithMs));
    setStatus(m_data.value("status").toString());
}

void Payment::setUpdatedAt(const QDateTime &updated_at)
{
    if (m_updated_at == updated_at) return;
    m_updated_at = updated_at;
    emit updatedAtChanged();
}

void Payment::setStatus(const QString& status)
{
    if (m_status == status) return;
    m_status = status;
    emit statusChanged();
}
