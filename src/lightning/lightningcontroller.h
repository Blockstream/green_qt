#ifndef BLOCKSTREAM_LIGHTNING_CONTROLLER_H
#define BLOCKSTREAM_LIGHTNING_CONTROLLER_H

#include "controller.h"

class LightningController : public Controller
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit LightningController(QObject* parent = nullptr);

public slots:
    void enable();
    void disable();

signals:
    void failed(const QString& error);
};

#endif // BLOCKSTREAM_LIGHTNING_CONTROLLER_H
