#ifndef GREEN_LEDGERGETBLINDINGNONCEACTIVITY_H
#define GREEN_LEDGERGETBLINDINGNONCEACTIVITY_H

#include "device.h"

class LedgerDevice;

class LedgerGetBlindingNonceActivity : public GetBlindingNonceActivity
{
    LedgerDevice* const m_device;
    const QByteArray m_pubkey;
    const QByteArray m_script;
    QByteArray m_nonce;
public:
    LedgerGetBlindingNonceActivity(const QByteArray& pubkey, const QByteArray& script, LedgerDevice* device);
    QByteArray nonce() const override;
private:
    void exec() override;
};

#endif // GREEN_LEDGERGETBLINDINGNONCEACTIVITY_H
