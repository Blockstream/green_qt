#ifndef GREEN_LEDGERGETWALLETPUBLICKEYACTIVITY_H
#define GREEN_LEDGERGETWALLETPUBLICKEYACTIVITY_H

#include "device.h"

QT_FORWARD_DECLARE_CLASS(LedgerDevice);

class LedgerGetWalletPublicKeyActivity : public GetWalletPublicKeyActivity
{
    LedgerDevice* const m_device;
    Network* const m_network;
    const QVector<uint32_t> m_path;
    QByteArray m_public_key;
public:
    LedgerGetWalletPublicKeyActivity(Network* network, const QVector<uint32_t>& path, LedgerDevice* device);
    QByteArray publicKey() const override;
    void exec() override;
};


#endif // GREEN_LEDGERGETWALLETPUBLICKEYACTIVITY_H
