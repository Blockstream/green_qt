#include "device.h"
#include "handler.h"
#include "signmessageresolver.h"
#include "util.h"

SignMessageResolver::SignMessageResolver(Handler* handler, const QJsonObject& result)
    : DeviceResolver(handler, result)
    , m_message(m_required_data.value("message").toString())
    , m_path(ParsePath(m_required_data.value("path").toArray()))
    , m_use_ae_protocol(m_required_data.value("use_ae_protocol").toBool())
    , m_ae_host_commitment(ParseByteArray(m_required_data.value("ae_host_commitment")))
    , m_ae_host_entropy(ParseByteArray(m_required_data.value("ae_host_entropy")))
{
}

void SignMessageResolver::resolve()
{
    auto activity = m_use_ae_protocol ? device()->signMessage(m_message, m_path, m_ae_host_commitment, m_ae_host_entropy) : device()->signMessage(m_message, m_path);
    connect(activity, &Activity::finished, this, [this, activity] {
        activity->deleteLater();
        QJsonObject data{
            { "signature", QString::fromLocal8Bit(activity->signature().toHex()) }
        };
        if (m_use_ae_protocol) {
            data["signer_commitment"] = QString::fromLocal8Bit(activity->signerCommitment().toHex());
        }
        handler()->resolve(data);
    });
    connect(activity, &Activity::failed, this, [this, activity] {
        activity->deleteLater();
        setFailed(true);
    });
    activity->exec();
}
