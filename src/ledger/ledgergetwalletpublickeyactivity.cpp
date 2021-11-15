#include "command.h"
#include "ledgerdevice.h"
#include "ledgergetwalletpublickeyactivity.h"
#include "network.h"

#include <wally_bip32.h>

LedgerGetWalletPublicKeyActivity::LedgerGetWalletPublicKeyActivity(Network* network, const QVector<uint32_t>& path, LedgerDevice* device)
    : GetWalletPublicKeyActivity(device)
    , m_device(device)
    , m_network(network)
    , m_path(path)
{
}

QByteArray LedgerGetWalletPublicKeyActivity::publicKey() const
{
    return m_public_key;
}

void LedgerGetWalletPublicKeyActivity::exec()
{
    QByteArray path;
    QDataStream s(&path, QIODevice::WriteOnly);
    s << uint8_t(m_path.size());
    for (auto p : m_path) s << uint32_t(p);
    auto cmd = m_device->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_GET_WALLET_PUBLIC_KEY, 0x0, 0, path));
    connect(cmd, &Command::finished, this, [this, cmd] {
        cmd->deleteLater();
        uint32_t version = m_network->isMainnet() ? BIP32_VER_MAIN_PUBLIC : BIP32_VER_TEST_PUBLIC;
        QDataStream stream(cmd->m_response);
        uint8_t pubkey_len, address_len;
        stream >> pubkey_len;
        QByteArray pubkey(pubkey_len, 0);
        stream.readRawData(pubkey.data(), pubkey_len);
        stream >> address_len;
        QByteArray address(address_len, 0);
        stream.readRawData(address.data(), address_len);
        QByteArray chain_code(32, 0);

        stream.readRawData(chain_code.data(), 33);

        pubkey = compressPublicKey(pubkey);
        ext_key* k;
        int x = bip32_key_init_alloc(version, 1, 0, (const unsigned char *) chain_code.data(), chain_code.length(), (const unsigned char *) pubkey.constData(), pubkey.length(), nullptr, 0, nullptr, 0, nullptr, 0, &k);
        Q_ASSERT(x == 0);

        char* base58;
        x = bip32_key_to_base58(k, BIP32_FLAG_KEY_PUBLIC, &base58);
        Q_ASSERT(x == 0);
        bip32_key_free(k);

        m_public_key = QByteArray(base58);

        wally_free_string(base58);
        finish();
    });
    connect(cmd, &Command::error, this, [this, cmd] {
        cmd->deleteLater();
        fail();
    });
}
