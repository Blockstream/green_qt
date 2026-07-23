#ifndef GREEN_LEDGERGETBLINDINGNONCETASK_H
#define GREEN_LEDGERGETBLINDINGNONCETASK_H

#include "device.h"

class LedgerDevice;

class LedgerGetBlindingNonceTask : public DeviceGetBlindingNonceTask
{
    LedgerDevice* const m_device;
    const QByteArray m_pubkey;
    const QByteArray m_script;
    QByteArray m_nonce;
public:
    LedgerGetBlindingNonceTask(const QByteArray& pubkey, const QByteArray& script, LedgerDevice* device);
    QByteArray nonce() const override;
private:
    void update() override;
};

#endif // GREEN_LEDGERGETBLINDINGNONCETASK_H
