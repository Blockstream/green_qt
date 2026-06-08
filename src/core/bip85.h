#ifndef BLOCKSTREAM_BIP85_H
#define BLOCKSTREAM_BIP85_H

#include <QString>

#include <cstdint>

QString DeriveBip85Mnemonic(bool mainnet, const QString& mnemonic, const QString& passphrase, uint32_t index, uint32_t word_count = 12);

#endif // BLOCKSTREAM_BIP85_H
