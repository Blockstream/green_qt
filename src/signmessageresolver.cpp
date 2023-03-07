#include "activitymanager.h"
#include "device.h"
#include "resolver.h"
#include "util.h"

#include <wally_crypto.h>

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

SignMessageResolver::SignMessageResolver(Device *device, const QJsonObject& result)
    : DeviceResolver(device, result)
    , m_message(m_required_data.value("message").toString())
    , m_hash(HashMessage(m_message))
    , m_path(ParsePath(m_required_data.value("path").toArray()))
    , m_use_ae_protocol(m_required_data.value("use_ae_protocol").toBool())
    , m_ae_host_commitment(ParseByteArray(m_required_data.value("ae_host_commitment")))
    , m_ae_host_entropy(ParseByteArray(m_required_data.value("ae_host_entropy")))
{
}

QString SignMessageResolver::path() const
{
    QStringList path;
    path.append("m");
    for (auto x : m_path) {
        path.append(QString::number(x));
    }
    return path.join("/");
}

void SignMessageResolver::resolve()
{
    auto activity = m_use_ae_protocol ? m_device->signMessage(m_message, m_path, m_ae_host_commitment, m_ae_host_entropy) : m_device->signMessage(m_message, m_path);
    connect(activity, &Activity::finished, this, [this, activity] {
        activity->deleteLater();
        QJsonObject data{
            { "signature", QString::fromLocal8Bit(activity->signature().toHex()) }
        };
        if (m_use_ae_protocol) {
            data["signer_commitment"] = QString::fromLocal8Bit(activity->signerCommitment().toHex());
        }
        qDebug() << "******" << data;
        emit resolved(data);
    });
    connect(activity, &Activity::failed, this, [this, activity] {
        activity->deleteLater();
        emit failed();
    });
    ActivityManager::instance()->exec(activity);
    pushActivity(activity);
}
