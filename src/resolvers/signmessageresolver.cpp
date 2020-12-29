#include "device.h"
#include "handler.h"
#include "signmessageresolver.h"
#include "util.h"

SignMessageResolver::SignMessageResolver(Handler* handler, const QJsonObject& result)
    : DeviceResolver(handler, result)
    , m_message(m_required_data.value("message").toString())
    , m_path(ParsePath(m_required_data.value("path").toArray()))
{
}

void SignMessageResolver::resolve()
{
    auto activity = device()->signMessage(m_message, m_path);
    connect(activity, &Activity::finished, this, [this, activity] {
        activity->deleteLater();
        handler()->resolve({
            { "signature", QString::fromLocal8Bit(activity->signature().toHex()) }
        });
    });
    connect(activity, &Activity::failed, this, [this, activity] {
        activity->deleteLater();
        setFailed(true);
    });
    activity->exec();
}
