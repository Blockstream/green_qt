#include "activity.h"

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
    emit finished();
}

void Activity::fail()
{
    Q_ASSERT(m_status == Status::Pending);
    m_status = Status::Failed;
    emit failed();
}
