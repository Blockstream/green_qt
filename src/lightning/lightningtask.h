#ifndef BLOCKSTREAM_LIGHTNING_TASK_H
#define BLOCKSTREAM_LIGHTNING_TASK_H

#include "task.h"

#include <QQmlEngine>

class LightningConnectNodeTask : public ContextTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LightningConnectNodeTask(Context* context);
    void update() override;
};

class LightningEnableTask : public ContextTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LightningEnableTask(Context* context);
    void update() override;
};

#endif // BLOCKSTREAM_LIGHTNING_TASK_H
