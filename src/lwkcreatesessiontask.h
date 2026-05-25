#ifndef BLOCKSTREAM_LWKCREATESESSIONTASK_H
#define BLOCKSTREAM_LWKCREATESESSIONTASK_H

#include "task.h"

#include <QQmlEngine>

class LwkCreateSessionTask : public ContextTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LwkCreateSessionTask(Context* context);
    void update() override;
};

#endif // BLOCKSTREAM_LWKCREATESESSIONTASK_H
