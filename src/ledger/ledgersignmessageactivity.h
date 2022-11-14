#ifndef GREEN_LEDGERSIGNMESSAGEACTIVITY_H
#define GREEN_LEDGERSIGNMESSAGEACTIVITY_H

#include "device.h"

class LedgerDevice;

class LedgerSignMessageActivity : public SignMessageActivity
{
    LedgerDevice* const m_device;
    const QString m_message;
    const QVector<uint32_t> m_path;
    QByteArray m_signature;
public:
    LedgerSignMessageActivity(const QString& message, const QVector<uint32_t>& path, LedgerDevice* device);
    QByteArray signature() const override;
    void prepare();
    void sign();
private:
    void exec() override;
};

#endif // GREEN_LEDGERSIGNMESSAGEACTIVITY_H
