#include "watchonlycontroller.h"

#include "task.h"
#include "wallet.h"
#include "context.h"
#include "session.h"

WatchOnlyController::WatchOnlyController(QObject* parent)
    : SessionController(parent)
{
}

void WatchOnlyController::update(const QString& username, const QString& password)
{
    if (!m_session) return;

    auto watchonly_data = qobject_cast<WatchonlyData*>(m_context->wallet()->login());
    if (watchonly_data) return;

    auto task = new RegisterUserTask({{ "username", username }, { "password", password }}, {}, m_session);

    connect(task, &Task::finished, this, [=] {
        m_session->setUsername(username);
        emit finished();
    });

    connect(task, &Task::failed, this, [=] {
        emit failed(task->error());
    });

    auto group = new TaskGroup(this);
    group->add(task);
    dispatcher()->add(group);
    monitor()->add(group);
}

void WatchOnlyController::clear()
{
    update("", "");
}
