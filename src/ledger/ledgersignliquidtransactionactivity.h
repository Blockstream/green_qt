#ifndef LEDGERSIGNLIQUIDTRANSACTIONACTIVITY_H
#define LEDGERSIGNLIQUIDTRANSACTIONACTIVITY_H

#include "device.h"

QT_FORWARD_DECLARE_CLASS(CommandBatch);
QT_FORWARD_DECLARE_CLASS(LedgerDevice);

class LedgerSignLiquidTransactionActivity : public SignLiquidTransactionActivity
{
public:
    LedgerSignLiquidTransactionActivity(const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, LedgerDevice* device);

    virtual QList<QByteArray> signatures() const override { return m_sigs; }
    virtual QList<QByteArray> assetCommitments() const override { return m_asset_commitments; }
    virtual QList<QByteArray> valueCommitments() const override { return m_value_commitments; }
    virtual QList<QByteArray> assetBlinders() const override { return m_abfs; }
    virtual QList<QByteArray> amountBlinders() const override { return m_vbfs; }

    void exec() override;
    void getLiquidCommitment(int output_index);

    DeviceCommand* exchange(const QByteArray& data);
    LedgerDevice* const m_device;
    QJsonObject m_transaction;
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
};

#endif // LEDGERSIGNLIQUIDTRANSACTIONACTIVITY_H
