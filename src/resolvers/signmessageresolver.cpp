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
    auto batch = new CommandBatch;
    auto prepare_command = new SignMessageCommand(device(), m_path, m_message.toLocal8Bit());
    auto sign_command = new SignMessageCommand(device());
    batch->add(prepare_command);
    batch->add(sign_command);
    connect(batch, &Command::finished, this, [this, sign_command] {
        m_handler->resolve({{ "signature", QString::fromLocal8Bit(sign_command->signature.toHex()) }});
    });
    batch->exec();
}
