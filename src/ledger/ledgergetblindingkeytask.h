#ifndef GREEN_LEDGERGETBLINDINGKEYTASK_H
#define GREEN_LEDGERGETBLINDINGKEYTASK_H

#include "device.h"

class LedgerDevice;

class LedgerGetBlindingKeyTask : public DeviceGetBlindingKeyTask
{
    LedgerDevice* const m_device;
    const QString m_script;
    QByteArray m_public_key;
public:
    LedgerGetBlindingKeyTask(const QString& script, LedgerDevice* device);
    QByteArray publicKey() const override;
private:
    void update() override;
};

#endif // GREEN_LEDGERGETBLINDINGKEYTASK_H
