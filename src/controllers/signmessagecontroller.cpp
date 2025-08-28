#include "signmessagecontroller.h"

#include "task.h"

SignMessageController::SignMessageController(QObject* parent)
    : Controller(parent)
{
}

void SignMessageController::setAddress(Address* address)
{
    if (m_address == address) return;
    m_address = address;
    emit addressChanged();
    clearSignature();
    updateValid();
}

void SignMessageController::setMessage(const QString& message)
{
    if (m_message == message) return;
    m_message = message;
    emit messageChanged();
    clearSignature();
    updateValid();
}

void SignMessageController::updateValid()
{
    const bool valid = m_address && !m_message.isEmpty();
    if (m_valid == valid) return;
    m_valid = valid;
    emit validChanged();
}

void SignMessageController::setSignature(const QString& signature)
{
    if (m_signature == signature) return;
    m_signature = signature;
    emit signatureChanged();
}

void SignMessageController::clearSignature()
{
    setSignature({});
    emit cleared();
}

void SignMessageController::sign()
{
    Q_ASSERT(m_valid);

    auto monitor = new TaskGroupMonitor(this);
    setMonitor(monitor);

    auto task = new SignMessageTask(m_message, m_address);

    connect(task, &Task::finished, this, [=] {
        setSignature(task->signature());
        emit accepted(task->signature());
    });

    connect(task, &Task::failed, this, [=] {
        emit rejected();
    });

    auto group = new TaskGroup(this);
    group->add(task);
    monitor->add(group);
    dispatcher()->add(group);
}
