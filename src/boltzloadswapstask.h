#ifndef BLOCKSTREAM_BOLTZLOADSWAPSTASK_H
#define BLOCKSTREAM_BOLTZLOADSWAPSTASK_H

#include "task.h"

#include <QQmlEngine>

class BoltzLoadSwapsTask : public ContextTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    BoltzLoadSwapsTask(Context* context);
    void update() override;
};

#endif // BLOCKSTREAM_BOLTZLOADSWAPSTASK_H
