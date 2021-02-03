#include "command.h"
#include "ledgerdevice.h"
#include "ledgergetblindingnonceactivity.h"

LedgerGetBlindingNonceActivity::LedgerGetBlindingNonceActivity(const QByteArray& pubkey, const QByteArray& script, LedgerDevice* device)
    : GetBlindingNonceActivity(device)
    , m_device(device)
    , m_pubkey(pubkey)
    , m_script(script)
{
}

QByteArray LedgerGetBlindingNonceActivity::nonce() const
{
    return m_nonce;
}

void LedgerGetBlindingNonceActivity::exec()
{
    auto command = m_device->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_GET_LIQUID_NONCE, 0x00, 0x00, m_pubkey + m_script));
    connect(command, &Command::finished, this, [this, command] {
        command->deleteLater();
        Q_ASSERT(command->m_response.length() == 32);
        m_nonce = command->m_response;
        finish();
    });
    connect(command, &Command::error, this, [this, command] {
        command->deleteLater();
        fail();
    });
}
