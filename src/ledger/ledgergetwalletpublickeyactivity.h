#ifndef GREEN_LEDGERGETWALLETPUBLICKEYACTIVITY_H
#define GREEN_LEDGERGETWALLETPUBLICKEYACTIVITY_H

#include "device.h"

QT_FORWARD_DECLARE_CLASS(LedgerDevice);

class LedgerGetWalletPublicKeyActivity : public GetWalletPublicKeyActivity
{
    LedgerDevice* const m_device;
public:
    LedgerGetWalletPublicKeyActivity(Network* network, const QVector<uint32_t>& path, LedgerDevice* device);
private:
    void fetch() override;
};

#endif // GREEN_LEDGERGETWALLETPUBLICKEYACTIVITY_H
