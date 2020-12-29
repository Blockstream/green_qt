#include "command.h"
#include "device.h"

CommandBase::CommandBase(Device* device)
    : QObject(device)
    , m_device(device)
{
}

Device *CommandBase::device() const
{
    return m_device;
}

CommandBase::Status CommandBase::status() const
{
    return m_status;
}

void CommandBase::finish()
{
    Q_ASSERT(m_status == Status::Pending);
    m_status = Status::Finished;
    emit finished();
}

void CommandBase::fail()
{
    Q_ASSERT(m_status == Status::Pending);
    m_status = Status::Failed;
    emit failed();
}
