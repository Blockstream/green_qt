#ifndef GREEN_LEDGERGETBLINDINGKEYACTIVITY_H
#define GREEN_LEDGERGETBLINDINGKEYACTIVITY_H

#include "device.h"

QT_FORWARD_DECLARE_CLASS(LedgerDevice)

class LedgerGetBlindingKeyActivity : public GetBlindingKeyActivity
{
    LedgerDevice* const m_device;
    const QString m_script;
    QByteArray m_public_key;
public:
    LedgerGetBlindingKeyActivity(const QString& script, LedgerDevice* device);
    QByteArray publicKey() const override;
    void exec() override;
};

#endif // GREEN_LEDGERGETBLINDINGKEYACTIVITY_H
