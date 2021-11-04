#ifndef GREEN_LEDGERSIGNTRANSACTIONACTIVITY_H
#define GREEN_LEDGERSIGNTRANSACTIONACTIVITY_H

#include "command.h"
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
    LedgerSignTransactionActivity(const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions, const QJsonArray& signing_address_types, LedgerDevice* device);
    QList<QByteArray> signatures() const override;
    QList<QByteArray> signerCommitments() const override;
    Command *startUntrustedTransaction(uint32_t version, bool new_transaction, size_t index, const QList<Input> &used_inputs, const QByteArray &redeem_script, bool segwit);
    Command *untrustedHashSign(const QVector<uint32_t> &private_key_path, QString pin, uint32_t locktime);
private:
    void exec() override;
private:
    DeviceCommand* exchange(CommandBatch *batch, const QByteArray& data);
    Command* signSW();
    Command* signNonSW();

    QByteArray outputBytes();

    Command* getHwInputs(bool segwit);
    Command* finalizeInputFull(const QByteArray &data);
    Command* getTrustedInput(const QByteArray &raw, uint32_t index, uint32_t sequence, bool segwit);

    LedgerDevice* const m_device;
    const QJsonObject m_transaction;
    const QJsonArray m_signing_inputs;
    const QJsonArray m_transaction_outputs;
    const QJsonObject m_signing_transactions;
    const QJsonArray m_signing_address_types;

    QList<Input> m_hw_inputs;
    QList<QByteArray> m_signatures;
};

#endif // GREEN_LEDGERSIGNTRANSACTIONACTIVITY_H
