#ifndef LEDGERSIGNLIQUIDTRANSACTIONACTIVITY_H
#define LEDGERSIGNLIQUIDTRANSACTIONACTIVITY_H

#include "device.h"

class CommandBatch;
class LedgerDevice;

class LedgerSignLiquidTransactionActivity : public SignLiquidTransactionActivity
{
public:
    LedgerSignLiquidTransactionActivity(const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, LedgerDevice* device);

    virtual QList<QByteArray> signatures() const override { return m_sigs; }
    virtual QList<QByteArray> signerCommitments() const override { Q_UNREACHABLE(); }
//    virtual QList<QByteArray> assetCommitments() const override { return m_asset_commitments; }
//    virtual QList<QByteArray> valueCommitments() const override { return m_value_commitments; }
//    virtual QList<QByteArray> assetBlinders() const override { return m_abfs; }
//    virtual QList<QByteArray> amountBlinders() const override { return m_vbfs; }

    void getLiquidCommitment(int output_index);

    DeviceCommand* exchange(const QByteArray& data);
    LedgerDevice* const m_device;
    QByteArray m_transaction;
    QList<quint64> m_values;
    QList<QByteArray> m_abfs;
    QList<QByteArray> m_vbfs;
    QJsonArray m_inputs;
    QJsonArray m_outputs;
    QList<QByteArray> m_hw_inputs;
    QList<QByteArray> m_hw_sequences;

    QList<QByteArray> m_commitments;

    QList<QByteArray> m_sigs;
    QList<QByteArray> m_asset_commitments;
    QList<QByteArray> m_value_commitments;

    QList<QPair<QJsonObject, QByteArray>> m_output_liquid_bytes;

    int count{0};
    void startUntrustedTransaction(bool new_transaction, int input_index, const QList<QByteArray> &inputs, const QList<QByteArray> &sequences, const QByteArray &redeem_script);
    void finalizeLiquidInputFull();
    QList<QPair<QJsonObject, QByteArray>> outputLiquidBytes();
    int exchange_count{0};
    int exchange_total{0};
    CommandBatch* m_batch;
private:
    void exec() override;
};

class LedgerGetBlindingFactorsActivity : public GetBlindingFactorsActivity
{
public:
    LedgerGetBlindingFactorsActivity(const QJsonArray& inputs, const QJsonArray& outputs, LedgerDevice* device);
    QList<QByteArray> assetBlinders() const override;
    QList<QByteArray> amountBlinders() const override;
private:
    void exec() override;
    DeviceCommand *exchange(const QByteArray &data);
private:
    LedgerDevice* const m_device;
    const QJsonArray m_inputs;
    const QJsonArray m_outputs;

    CommandBatch* m_batch;
    QList<QByteArray> m_hw_inputs;
    QList<QByteArray> m_hw_sequences;
    QList<QByteArray> m_abfs;
    QList<QByteArray> m_vbfs;

    void startUntrustedTransaction(uint32_t version, bool new_transaction, int input_index, const QList<QByteArray> &inputs, const QList<QByteArray> &sequences, const QByteArray &redeem_script);
    DeviceCommand* getBlindingFactor(uint32_t index, uint8_t type);
};

#endif // LEDGERSIGNLIQUIDTRANSACTIONACTIVITY_H
