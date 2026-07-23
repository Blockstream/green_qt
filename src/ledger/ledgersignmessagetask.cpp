#include "command.h"
#include "ledgerdevice.h"
#include "ledgersignmessagetask.h"

LedgerSignMessageTask::LedgerSignMessageTask(const QString& message, const QVector<uint32_t>& path, LedgerDevice* device)
    : DeviceSignMessageTask(device)
    , m_device(device)
    , m_message(message)
    , m_path(path)
{
}

QByteArray LedgerSignMessageTask::signature() const
{
    return m_signature;
}

void LedgerSignMessageTask::update()
{
    if (m_status != Status::Ready) return;
    setStatus(Status::Active);

    prepare();
}

void LedgerSignMessageTask::prepare()
{
    QByteArray data;
    QDataStream s(&data, QIODevice::WriteOnly);
    s << uint8_t(m_path.size());
    for (auto p : m_path) s << uint32_t(p);
    s << uint8_t(0) << uint8_t(m_message.size());
    s.writeRawData(m_message.toLocal8Bit().constData(), m_message.size());
    auto command = m_device->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_SIGN_MESSAGE, 0x00, 0x01, data));
    connect(command, &Command::finished, this, [this, command] {
        command->deleteLater();
        sign();
    });
    connect(command, &Command::error, this, [this, command] {
        command->deleteLater();
        setStatus(Status::Failed);
    });
}

void LedgerSignMessageTask::sign()
{
    QByteArray data;
    QDataStream s(&data, QIODevice::WriteOnly);
    s << uint8_t(1) << uint8_t(0);
    auto command = m_device->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_SIGN_MESSAGE, 0x80, 0x01, data));
    connect(command, &Command::finished, this, [this, command] {
        command->deleteLater();
        m_signature = command->m_response;
        m_signature[0] = 0x30;
        setStatus(Status::Finished);
    });
    connect(command, &Command::error, this, [this, command] {
        command->deleteLater();
        setStatus(Status::Failed);
    });
}
