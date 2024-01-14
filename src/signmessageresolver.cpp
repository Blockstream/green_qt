#include "activitymanager.h"
#include "device.h"
#include "resolver.h"
#include "util.h"

#include <wally_wrapper.h>

namespace {

QByteArray HashMessage(const QString& message)
{
    QByteArray data = message.toUtf8();
    QByteArray hash(SHA256_LEN, 0);
    size_t written;
    auto rc = wally_format_bitcoin_message(
        (unsigned char*) data.constData(), data.size(),
        BITCOIN_MESSAGE_FLAG_HASH,
        (unsigned char*) hash.data(), hash.size(),
        &written);
    Q_ASSERT(rc == WALLY_OK);
    Q_ASSERT(written == SHA256_LEN);
    return hash.toHex();
}

}

static inline bool ishardened(const uint32_t n) { return n & 0x80000000; }
static inline uint32_t harden(const uint32_t n) { return n | 0x80000000; }
static inline uint32_t unharden(const uint32_t n) { return n & ~0x80000000; }

static bool wallet_bip32_path_as_str(const uint32_t* parts, const size_t num_parts, char* output, const size_t output_len)
{
    output[0] = 'm';
    output[1] = '\0';

    for (size_t pos = 1, i = 0; i < num_parts; ++i) {
        uint32_t val = parts[i];
        const char* fmt = "/%u";

        if (ishardened(val)) {
            val = unharden(val);
            fmt = "/%u'"; // hardened
        }

        const size_t freespace = output_len - pos;
        const int nchars = snprintf(output + pos, freespace, fmt, val);
        if (nchars < 0 || nchars > freespace) {
            return false;
        }
        pos += nchars;
    }
    return true;
}

SignMessageResolver::SignMessageResolver(Device *device, const QJsonObject& result, AuthHandlerTask* task)
    : DeviceResolver(device, result, task)
    , m_message(m_required_data.value("message").toString())
    , m_path(ParsePath(m_required_data.value("path").toArray()))
    , m_use_ae_protocol(m_required_data.value("use_ae_protocol").toBool())
    , m_ae_host_commitment(ParseByteArray(m_required_data.value("ae_host_commitment")))
    , m_ae_host_entropy(ParseByteArray(m_required_data.value("ae_host_entropy")))
{
}

QString SignMessageResolver::hash() const
{
    return HashMessage(m_message);
}

QString SignMessageResolver::path() const
{
    char output[1024];
    wallet_bip32_path_as_str(m_path.constData(), m_path.size(), output, sizeof(output));
    return QString::fromUtf8(output);
}

void SignMessageResolver::resolve()
{
    if (!m_device->isConnected()) {
        return;
    }

    auto activity = m_use_ae_protocol ? m_device->signMessage(m_message, m_path, m_ae_host_commitment, m_ae_host_entropy) : m_device->signMessage(m_message, m_path);
    connect(activity, &Activity::finished, this, [this, activity] {
        activity->deleteLater();
        QJsonObject data{
            { "signature", QString::fromLocal8Bit(activity->signature().toHex()) }
        };
        if (m_use_ae_protocol) {
            data["signer_commitment"] = QString::fromLocal8Bit(activity->signerCommitment().toHex());
        }
        emit resolved(data);
    });
    connect(activity, &Activity::failed, this, [this, activity] {
        activity->deleteLater();
        emit failed();
    });
    ActivityManager::instance()->exec(activity);
    pushActivity(activity);
}
