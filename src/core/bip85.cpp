#include "bip85.h"

#include <wally_bip32.h>
#include <wally_bip39.h>
#include <wally_bip85.h>
#include <wally_core.h>
#include <wally_crypto.h>

namespace {

struct Bip85SensitiveData {
    unsigned char seed_bytes[BIP39_SEED_LEN_512] = {};
    ext_key key = {};
    unsigned char entropy_bytes[HMAC_SHA512_LEN] = {};

    ~Bip85SensitiveData()
    {
        wally_bzero(seed_bytes, sizeof(seed_bytes));
        wally_bzero(&key, sizeof(key));
        wally_bzero(entropy_bytes, sizeof(entropy_bytes));
    }
};

} // namespace

QString DeriveBip85Mnemonic(
    const bool mainnet,
    const QString& mnemonic,
    const QString& passphrase,
    const uint32_t index,
    const uint32_t word_count)
{
    Bip85SensitiveData sensitive;
    if (bip39_mnemonic_to_seed512(
            mnemonic.toUtf8().constData(),
            passphrase.isEmpty() ? nullptr : passphrase.toUtf8().constData(),
            sensitive.seed_bytes,
            BIP39_SEED_LEN_512) != WALLY_OK) {
        return {};
    }

    const uint32_t version = mainnet ? BIP32_VER_MAIN_PRIVATE : BIP32_VER_TEST_PRIVATE;

    if (bip32_key_from_seed(
            sensitive.seed_bytes,
            BIP39_SEED_LEN_512,
            version,
            BIP32_FLAG_SKIP_HASH,
            &sensitive.key) != WALLY_OK) {
        return {};
    }

    size_t entropy_len = 0;
    if (bip85_get_bip39_entropy(
            &sensitive.key,
            nullptr,
            word_count,
            index,
            sensitive.entropy_bytes,
            HMAC_SHA512_LEN,
            &entropy_len) != WALLY_OK) {
        return {};
    }

    char* derived_mnemonic_chars = nullptr;
    if (bip39_mnemonic_from_bytes(
            nullptr,
            sensitive.entropy_bytes,
            entropy_len,
            &derived_mnemonic_chars) != WALLY_OK || !derived_mnemonic_chars) {
        return {};
    }

    const auto derived_mnemonic = QString::fromLatin1(derived_mnemonic_chars);
    wally_free_string(derived_mnemonic_chars);

    return derived_mnemonic;
}
