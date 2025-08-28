#include "activity.h"

Activity::Activity(QObject* parent)
    : QObject(parent)
{
}

QString Activity::type() const
{
    return metaObject()->className();
}

Activity::Status Activity::status() const
{
    return m_status;
}

void Activity::finish()
{
    Q_ASSERT(m_status == Status::Pending);
    m_status = Status::Finished;
    emit statusChanged(m_status);
    emit finished();
    m_progress.setValue(m_progress.to());
    m_progress.setIndeterminate(false);
}

void Activity::fail()
{
    Q_ASSERT(m_status == Status::Pending);
    m_status = Status::Failed;
    emit statusChanged(m_status);
    emit failed();
    m_progress.setIndeterminate(false);
}

void Activity::setMessage(const QJsonObject& message)
{
    if (m_message == message) return;
    m_message = message;
    emit messageChanged(m_message);
}
