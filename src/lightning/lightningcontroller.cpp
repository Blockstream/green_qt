#include "lightningcontroller.h"

#include "context.h"
#include "lightningtask.h"
#include "task.h"

LightningController::LightningController(QObject* parent)
    : Controller(parent)
{
}

void LightningController::enable()
{
    if (!context() || context()->lightningEnabled()) return;

    auto group = new TaskGroup(this);
    group->setName("id_lightning");

    auto enable_lightning = new LightningEnableTask(context());
    connect(enable_lightning, &Task::failed, this, [this](const QString& error) {
        emit failed(error);
    });
    group->add(enable_lightning);

    if (!monitor()) {
        setMonitor(new TaskGroupMonitor(this));
    }
    monitor()->add(group);
    dispatcher()->add(group);
}

void LightningController::disable()
{
    if (!context() || !context()->lightningEnabled()) return;

    context()->setLightningEnabled(false);
}
