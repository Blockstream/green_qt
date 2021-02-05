#include "command.h"
#include "ledgerdevice.h"
#include "ledgergetblindingnonceactivity.h"

#include <wally_crypto.h>

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
    QByteArray pubkey_uncompressed = QByteArray(EC_PUBLIC_KEY_UNCOMPRESSED_LEN, 0);
    int res = wally_ec_public_key_decompress(
                (const unsigned char*) m_pubkey.constData(), m_pubkey.size(),
                (unsigned char*) pubkey_uncompressed.data(), pubkey_uncompressed.size());
    Q_ASSERT(res == WALLY_OK);

    auto command = m_device->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_GET_LIQUID_NONCE, 0x00, 0x00, pubkey_uncompressed + m_script));
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
