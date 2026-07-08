#ifndef BLOCKSTREAM_LIGHTNING_UTIL_H
#define BLOCKSTREAM_LIGHTNING_UTIL_H

#include <QtGlobal>

#include <optional>

inline quint64 LightningMsatToSatoshi(const quint64 msat)
{
    return msat / 1000ULL;
}

inline quint64 LightningMsatToDisplaySatoshi(const quint64 msat)
{
    return msat / 1000ULL + (msat % 1000ULL == 0 ? 0 : 1);
}

inline std::optional<quint64> LightningMsatToDisplaySatoshi(const std::optional<quint64>& msat)
{
    if (!msat) return std::nullopt;
    return LightningMsatToDisplaySatoshi(*msat);
}

inline quint64 LightningSatoshiToMsat(const quint64 satoshi)
{
    return satoshi * 1000ULL;
}

inline std::optional<quint64> LightningSatoshiToMsat(const std::optional<quint64>& satoshi)
{
    if (!satoshi) return std::nullopt;
    return LightningSatoshiToMsat(*satoshi);
}

#endif // BLOCKSTREAM_LIGHTNING_UTIL_H
