#ifndef BLOCKSTREAM_BOLTZCREATESESSIONTASK_H
#define BLOCKSTREAM_BOLTZCREATESESSIONTASK_H

#include "task.h"

#include <QQmlEngine>

class BoltzCreateSessionTask : public ContextTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    BoltzCreateSessionTask(Context* context);
    void update() override;
};

#endif // BLOCKSTREAM_BOLTZCREATESESSIONTASK_H
