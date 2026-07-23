#ifndef GREEN_LEDGERSIGNMESSAGETASK_H
#define GREEN_LEDGERSIGNMESSAGETASK_H

#include "device.h"

class LedgerDevice;

class LedgerSignMessageTask : public DeviceSignMessageTask
{
    LedgerDevice* const m_device;
    const QString m_message;
    const QVector<uint32_t> m_path;
    QByteArray m_signature;
public:
    LedgerSignMessageTask(const QString& message, const QVector<uint32_t>& path, LedgerDevice* device);
    QByteArray signature() const override;
    void prepare();
    void sign();
private:
    void update() override;
};

#endif // GREEN_LEDGERSIGNMESSAGETASK_H
