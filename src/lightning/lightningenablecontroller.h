#ifndef BLOCKSTREAM_LIGHTNING_ENABLE_CONTROLLER_H
#define BLOCKSTREAM_LIGHTNING_ENABLE_CONTROLLER_H

#include "controller.h"

class LightningEnableController : public Controller
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit LightningEnableController(QObject* parent = nullptr);

public slots:
    void enable();
    void disable();

signals:
    void failed(const QString& error);
};

#endif // BLOCKSTREAM_LIGHTNING_ENABLE_CONTROLLER_H
