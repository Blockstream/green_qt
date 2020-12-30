#include "command.h"
#include "ledgerdevice.h"
#include "ledgergetblindingkeyactivity.h"
#include "util.h"

LedgerGetBlindingKeyActivity::LedgerGetBlindingKeyActivity(const QString& script, LedgerDevice* device)
    : GetBlindingKeyActivity(device)
    , m_device(device)
    , m_script(script)
{}

QByteArray LedgerGetBlindingKeyActivity::publicKey() const
{
    return m_public_key;
}

void LedgerGetBlindingKeyActivity::exec()
{
    auto command = m_device->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_GET_LIQUID_BLINDING_KEY, 0x00, 0x00, ParseByteArray(m_script)));
    connect(command, &Command::finished, [this, command] {
        command->deleteLater();
        m_public_key = compressPublicKey(command->m_response);
        finish();
    });
    connect(command, &Command::error, [this, command] {
        command->deleteLater();
        fail();
    });
}
