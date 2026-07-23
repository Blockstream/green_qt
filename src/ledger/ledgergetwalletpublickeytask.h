#ifndef GREEN_LEDGERGETWALLETPUBLICKEYTASK_H
#define GREEN_LEDGERGETWALLETPUBLICKEYTASK_H

#include "device.h"

class LedgerDevice;

class LedgerGetWalletPublicKeyTask : public DeviceGetWalletPublicKeyTask
{
    LedgerDevice* const m_device;
public:
    LedgerGetWalletPublicKeyTask(Network* network, const QVector<uint32_t>& path, LedgerDevice* device);
private:
    void fetch() override;
};

#endif // GREEN_LEDGERGETWALLETPUBLICKEYTASK_H
