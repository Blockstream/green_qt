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
    auto command = device()->signMessage(m_message, m_path);
    connect(command, &Command2<QByteArray>::finished, this, [this, command] {
        command->deleteLater();
        handler()->resolve({
            { "signature", QString::fromLocal8Bit(command->result().toHex()) }
        });
    });
    connect(command, &Command2<QByteArray>::failed, this, [this, command] {
        command->deleteLater();
        setFailed(true);
    });
    command->exec();
}
