#include "activity.h"
#include "device.h"

Activity::Activity(Device* device)
    : QObject(device)
    , m_device(device)
{
}

Device *Activity::device() const
{
    return m_device;
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
