#include "command.h"
#include "ledgerdevice.h"
#include "ledgergetblindingkeytask.h"
#include "util.h"

LedgerGetBlindingKeyTask::LedgerGetBlindingKeyTask(const QString& script, LedgerDevice* device)
    : DeviceGetBlindingKeyTask(device)
    , m_device(device)
    , m_script(script)
{}

QByteArray LedgerGetBlindingKeyTask::publicKey() const
{
    return m_public_key;
}

void LedgerGetBlindingKeyTask::update()
{
    if (m_status != Status::Ready) return;
    setStatus(Status::Active);

    auto command = m_device->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_GET_LIQUID_BLINDING_KEY, 0x00, 0x00, ParseByteArray(m_script)));
    connect(command, &Command::finished, [this, command] {
        command->deleteLater();
        m_public_key = compressPublicKey(command->m_response);
        setStatus(Status::Finished);
    });
    connect(command, &Command::error, [this, command] {
        command->deleteLater();
        setStatus(Status::Failed);
    });
}
