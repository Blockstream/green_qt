#ifndef GREEN_LEDGERSIGNTRANSACTIONACTIVITY_H
#define GREEN_LEDGERSIGNTRANSACTIONACTIVITY_H

#include "device.h"


struct Input {
    QByteArray value;
    QByteArray sequence;
    bool trusted;
    bool segwit;
};

class LedgerSignTransactionActivity : public SignTransactionActivity
{
public:
    LedgerSignTransactionActivity(uint32_t version, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, uint32_t locktime, LedgerDevice* device);
    QList<QByteArray> signatures() const override;
    DeviceCommand* exchange(const QByteArray& data);
    void exec() override;
    QByteArray outputBytes();
    void startUntrustedTransaction(bool new_transaction, int64_t input_index, const QList<Input>& used_input, const QByteArray& redeem_script, bool segwit);

    void hashInputs(const QList<Input>& used_inputs, int64_t input_index, const QByteArray& redeem_script);

    void hashInput(const Input& input, const QByteArray& script);
    void signSWInputs(const QList<Input>& hwInputs);

    void signSWInput(const Input& hwInput, const QJsonObject& input);
    void untrustedHashSign(const QVector<uint32_t>& private_key_path, QString pin, uint8_t sig_hash_type);
    void finalizeInputFull(const QByteArray& data);
    LedgerDevice* const m_device;
    const uint32_t m_version;
    const QJsonObject m_transaction;
    const QJsonArray m_signing_inputs;
    const QJsonArray m_outputs;
    const uint32_t m_locktime;
    int count{0};
    QList<QByteArray> m_signatures;
};

#endif // GREEN_LEDGERSIGNTRANSACTIONACTIVITY_H
