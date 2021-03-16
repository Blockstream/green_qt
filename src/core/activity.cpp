#include "activity.h"

Progress::Progress(QObject* parent)
    : QObject(parent)
{
}

void Progress::setFrom(qreal from)
{
    if (m_from == from) return;
    m_from = from;
    emit fromChanged(m_from);
}

void Progress::setTo(qreal to)
{
    if (m_to == to) return;
    m_to = to;
    emit toChanged(m_to);
}

void Progress::setValue(qreal value)
{
    if (m_value == value) return;
    m_value = value;
    emit valueChanged(m_value);
}

void Progress::setIndeterminate(bool indeterminate)
{
    if (m_indeterminate == indeterminate) return;
    m_indeterminate = indeterminate;
    emit indeterminateChanged(m_indeterminate);
}

void Progress::incrementValue(int inc)
{
    setValue(value() + inc);
}

Activity::Activity(QObject* parent)
    : QObject(parent)
{
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
