#include "command.h"
#include "ledgerdevice.h"
#include "ledgersignliquidtransactionactivity.h"
#include "util.h"

#include <wally_wrapper.h>

namespace {

QByteArray inputLiquidBytes(const QJsonObject& input, bool strict)
{
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);

    QByteArray txhash_hex = ParseByteArray(input["txhash"]);
    for (int i = txhash_hex.size() - 1; i >= 0; --i) {
        stream << uint8_t(txhash_hex.at(i));
    }
    uint32_t pt_idx = input.value("pt_idx").toInt();
    stream << pt_idx;
    if (strict || input.contains("commitment")) {
        const auto commitment = ParseByteArray(input.value("commitment"));
        stream.writeRawData(commitment.data(), commitment.size());
    } else {
        for (int j = 0; j < 3; j++) {
            stream << uint8_t(0x08);
            for (int i = 0; i < 10; ++i) {
                stream << uint8_t(0x00);
            }
        }
    }
    return data;
}

QByteArray sequenceBytes(const QJsonObject& input)
{
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    stream << ParseSequence(input.value("sequence"));
    return data;
}

} // namespace

LedgerSignLiquidTransactionActivity::LedgerSignLiquidTransactionActivity(const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, LedgerDevice* device)
    : SignLiquidTransactionActivity(device)
    , m_device(device)
    , m_inputs(signing_inputs)
    , m_outputs(outputs)
    , m_batch(new CommandBatch)
{
    wally_tx* tx;
    wally_tx_from_bytes((const unsigned char*) transaction.constData(), transaction.size(), WALLY_TX_FLAG_USE_ELEMENTS, &tx);
    m_version = tx->version;
    m_locktime = tx->locktime;
    wally_tx_free(tx);

    connect(m_batch, &Command::error, this, [this] { fail(); });
}

void LedgerSignLiquidTransactionActivity::exec()
{
    exchange_total = 3 + 6 * m_inputs.size() + 5 * m_outputs.size();
    progress()->setTo(exchange_total);
    progress()->setIndeterminate(false);

    for (int i = 0; i < m_inputs.size(); ++i) {
        const auto input = m_inputs.at(i).toObject();
        m_hw_inputs.append(inputLiquidBytes(input, true));
        m_hw_sequences.append(sequenceBytes(input));
    }

    Q_ASSERT(m_inputs.size() > 0);
    const auto input0 = m_inputs.at(0).toObject();
    Q_ASSERT(input0.contains("prevout_script"));
    const auto script0 = ParseByteArray(input0.value("prevout_script"));

    startUntrustedTransaction(true, 0, m_hw_inputs, m_hw_sequences, script0);

    for (const auto input : m_inputs) {
        m_values.append(ParseSatoshi(input.toObject().value("satoshi")));
        m_abfs.append(ReverseByteArray(ParseByteArray(input.toObject().value("assetblinder"))));
        m_vbfs.append(ReverseByteArray(ParseByteArray(input.toObject().value("amountblinder"))));
    }

    getLiquidCommitment(0);

    m_batch->exec();
}

void LedgerSignLiquidTransactionActivity::startUntrustedTransaction(bool new_transaction, int input_index, const QList<QByteArray>& inputs, const QList<QByteArray>& sequences, const QByteArray& redeem_script)
{
    Q_ASSERT(inputs.size() == sequences.size());
    {
        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::LittleEndian);
        stream << m_version << varint<uint32_t>(inputs.size());
        exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x00, new_transaction ? 0x06 : 0x80, data));
    }
    for (int i = 0; i < inputs.size(); ++i) {
        QByteArray script = i == input_index ? redeem_script : QByteArray();

        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::LittleEndian);
        stream << uint8_t(0x03);
        stream.writeRawData(inputs.at(i).data(), inputs.at(i).size());
        stream << varint<uint32_t>(script.size());

        exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x80, 0x00, data));
        exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x80, 0x00, script + sequences.at(i)));
    }
}

void LedgerSignLiquidTransactionActivity::getLiquidCommitment(int output_index)
{
    if (output_index == m_outputs.size()) {
        return finalizeLiquidInputFull();
    }

    Q_ASSERT(output_index < m_outputs.size());
    const auto output = m_outputs.at(output_index).toObject();
    const bool last = (output_index + 2) == m_outputs.size();

    if (!output.contains("blinding_key")) {
        m_commitments.append(QByteArray());
        return getLiquidCommitment(output_index + 1);
    }

    Q_ASSERT(output.contains("satoshi"));
    const quint64 value = ParseSatoshi(output.value("satoshi"));
    m_values.append(value);

    Q_ASSERT(output.contains("asset_id"));
    const auto asset_id = ParseByteArray(output.value("asset_id"));
    Q_ASSERT(asset_id.size() == 32);

    if (last) {
        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::BigEndian);
        stream << uint32_t(output_index);
        auto c = exchange(apdu(BTCHIP_CLA, BTCHIP_INS_GET_LIQUID_BLINDING_FACTOR, 0x01, 0x00, data));
        connect(c, &Command::finished, [this, c, output_index, value, asset_id] {
            Q_ASSERT(c->m_response.size() == 32);
            m_abfs.append(c->m_response);

            QByteArray data;
            QDataStream stream(&data, QIODevice::WriteOnly);
            stream.setByteOrder(QDataStream::BigEndian);

            stream.writeRawData(asset_id.data(), asset_id.length());
            stream << quint64(value) << uint32_t(output_index);

            const auto values = m_values.toVector();
            const auto abf = m_abfs.join();
            const auto vbf = m_vbfs.join();

            char final_vbf[BLINDING_FACTOR_LEN];
            int ret = wally_asset_final_vbf(
                        (const uint64_t*) values.data(), values.size(),
                        m_inputs.size(),
                        (const unsigned char*) abf.data(), abf.size(),
                        (const unsigned char*) vbf.data(), vbf.size(),
                        (unsigned char*) final_vbf, BLINDING_FACTOR_LEN);
            Q_ASSERT(ret == WALLY_OK);
            m_vbfs.append(QByteArray(final_vbf, BLINDING_FACTOR_LEN));
            stream.writeRawData(final_vbf, BLINDING_FACTOR_LEN);

            auto c = exchange(apdu(BTCHIP_CLA, BTCHIP_INS_GET_LIQUID_COMMITMENTS, 0x02, 0x00, data));
            connect(c, &Command::finished, [this, c, output_index] {
                m_commitments.append(c->m_response);
                getLiquidCommitment(output_index + 1);
            });
        });
    } else {
        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::BigEndian);

        stream.writeRawData(asset_id.data(), asset_id.length());
        stream << quint64(value) << uint32_t(output_index);

        auto c = exchange(apdu(BTCHIP_CLA, BTCHIP_INS_GET_LIQUID_COMMITMENTS, 0x01, 0x00, data));
        connect(c, &Command::finished, [this, c, output_index] {
            Q_ASSERT(c->m_response.size() >= 64);
            m_commitments.append(c->m_response);
            m_abfs.append(c->m_response.mid(0, 32));
            m_vbfs.append(c->m_response.mid(32, 32));
            getLiquidCommitment(output_index + 1);
        });
    }
}

DeviceCommand *LedgerSignLiquidTransactionActivity::exchange(const QByteArray& data)
{
    auto command = new LedgerGenericCommand(m_device, data);
    connect(command, &Command::finished, [this] {
       exchange_count ++;
       progress()->setValue(exchange_count);
    });
    m_batch->add(command);
    return command;
}

QList<QPair<QJsonObject, QByteArray>> LedgerSignLiquidTransactionActivity::outputLiquidBytes()
{
    QList<QPair<QJsonObject,QByteArray>> res;
    {
        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::LittleEndian);
        stream << varint<uint32_t>(m_outputs.size());
        res.append({{}, data});
    }

    for (int i = 0; i < m_outputs.size(); ++i) {
        const auto output = m_outputs.at(i).toObject();
        if (!output.contains("blinding_key")) {
            QByteArray data;
            QDataStream stream(&data, QIODevice::WriteOnly);
            stream << uint8_t(0x01);
            const auto asset_id = ParseByteArray(output.value("asset_id"));
            Q_ASSERT(asset_id.size() == 32);
            for (int j = asset_id.size() - 1; j >= 0; --j) {
                stream << uint8_t(asset_id.at(j));
            }
            stream << uint8_t(0x01);
            stream.setByteOrder(QDataStream::BigEndian);
            stream << ParseSatoshi(output.value("satoshi"));
            res.append({{}, data});
        } else {
            res.append({{}, m_commitments.at(i).mid(64, 143)});
        }

        if (output.contains("blinding_key")) {
            const auto blinding_key = ParseByteArray(output.value("blinding_key"));
            const auto eph_public_key = ParseByteArray(output.value("eph_public_key"));
            res.append({{}, eph_public_key});
            res.append({{}, blinding_key});
        } else {
            QByteArray dummy(1, 0);
            res.append({{}, dummy});
            res.append({{}, dummy});
        }

        {
            const auto scriptpubkey = ParseByteArray(output.value("scriptpubkey"));
            QByteArray data;
            QDataStream stream(&data, QIODevice::WriteOnly);
            stream.setByteOrder(QDataStream::LittleEndian);
            if (scriptpubkey.size() == 0) {
                stream << varint<uint32_t>(0);
            } else {
                stream << varint<uint32_t>(scriptpubkey.size());
                stream.writeRawData(scriptpubkey.data(), scriptpubkey.size());
            }

            QJsonObject message = {
                { "index", i },
                { "output", output },
            };
            res.append({message, data});
        }
    }
    return res;
}


void LedgerSignLiquidTransactionActivity::finalizeLiquidInputFull()
{
    int i = 0;
    m_output_liquid_bytes = outputLiquidBytes();
    for (const auto& data : m_output_liquid_bytes) {
        auto c = exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_FINALIZE_FULL, i == m_output_liquid_bytes.size()-1 ? 0x80 : 0x00, 0x00, data.second));
        connect(c, &Command::finished, [this, i] {
            if (i + 1 < m_output_liquid_bytes.size()) {
                setMessage(m_output_liquid_bytes.at(i + 1).first);
            } else {
                setMessage({});
            }
            // qDebug() << "RECEIVE BTCHIP_INS_HASH_INPUT_FINALIZE_FULL" << i << c->m_response.toHex();
        });
        connect(c, &Command::error, [] {
            // qDebug() << "RECEIVE BTCHIP_INS_HASH_INPUT_FINALIZE_FULL" << i << "!!!!! ERROR !!!!!";
        });

        i++;
    }

    {
        QByteArray data(m_inputs.size(), 0);
        auto c = exchange(apdu(BTCHIP_CLA, BTCHIP_INS_GET_LIQUID_ISSUANCE_INFORMATION, 0x80, 0x00, data));
        connect(c, &Command::finished, [c] {
//            qDebug() << "RECEIVE BTCHIP_INS_GET_LIQUID_ISSUANCE_INFORMATION" << c->m_response.toHex();
        });
        connect(c, &Command::error, [i] {
//            qDebug() << "RECEIVE BTCHIP_INS_GET_LIQUID_ISSUANCE_INFORMATION" << "!!!!! ERROR !!!!!";
        });
    }

    for (i = 0; i < m_outputs.size(); ++i) {
        const auto commitment = m_commitments.at(i);
        if (commitment.isEmpty()) {
            m_asset_commitments.append(QByteArray());
            m_value_commitments.append(QByteArray());
        } else {
            m_asset_commitments.append(commitment.mid(69, 33));
            m_value_commitments.append(commitment.mid(69 + 33, 33));
        }
    }

    for (i = 0; i < m_hw_inputs.size(); ++i) {
        const auto input = m_inputs.at(i).toObject();
        const auto script = ParseByteArray(input.value("prevout_script"));

        startUntrustedTransaction(false, 0, {m_hw_inputs.at(i)}, {m_hw_sequences.at(i)}, script);

        {
            // untrustedLiquidHashSign
            QByteArray data;
            QDataStream stream(&data, QIODevice::WriteOnly);

            QVector<uint32_t> user_path = ParsePath(input.value("user_path"));
            const auto path = pathToData(user_path);

            stream.writeRawData(path.data(), path.size());
            stream << uint8_t(0x00);
            stream.setByteOrder(QDataStream::BigEndian);
            stream << m_locktime;
            stream.setByteOrder(QDataStream::LittleEndian);
            stream << uint8_t(/* SIGHASH_ALL */ 1);

            auto c = exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_SIGN, 0x00, 0x00, data));
            connect(c, &Command::finished, [this, c] {
                QByteArray signature;
                signature.append(0x30);
                signature.append(c->m_response.mid(1));
                m_sigs.append(signature);

                if (m_sigs.size() == m_hw_inputs.size()) {
                    m_abfs = m_abfs.mid(m_inputs.size());
                    m_vbfs = m_vbfs.mid(m_inputs.size());
                    finish();
                }
            });
        }
    }
}


LedgerGetBlindingFactorsActivity::LedgerGetBlindingFactorsActivity(const QJsonArray &inputs, const QJsonArray &outputs, LedgerDevice* device)
    : GetBlindingFactorsActivity(device)
    , m_device(device)
    , m_inputs(inputs)
    , m_outputs(outputs)
    , m_batch(new CommandBatch)
{
    connect(m_batch, &Command::finished, this, [=] {
        finish();
    });
}

DeviceCommand *LedgerGetBlindingFactorsActivity::exchange(const QByteArray& data)
{
    auto command = new LedgerGenericCommand(m_device, data);
    connect(command, &Command::finished, [this] {
//        exchange_count ++;
//        progress()->setValue(exchange_count);
    });
    m_batch->add(command);
    return command;
}

QList<QByteArray> LedgerGetBlindingFactorsActivity::assetBlinders() const
{
    return m_abfs;
}

QList<QByteArray> LedgerGetBlindingFactorsActivity::amountBlinders() const
{
    return m_vbfs;
}

void LedgerGetBlindingFactorsActivity::exec()
{
//    exchange_total = 3 + 6 * m_inputs.size() + 5 * m_outputs.size();
//    progress()->setTo(exchange_total);
    progress()->setIndeterminate(false);

    for (int i = 0; i < m_inputs.size(); ++i) {
        const auto input = m_inputs.at(i).toObject();
        m_hw_inputs.append(inputLiquidBytes(input, false));
        m_hw_sequences.append(sequenceBytes(input));
    }

    Q_ASSERT(m_inputs.size() > 0);
    const auto script0 = QByteArray();

    startUntrustedTransaction(2, true, 0, m_hw_inputs, m_hw_sequences, script0);

    m_abfs.resize(m_outputs.size());
    m_vbfs.resize(m_outputs.size());

    for (int i = 0; i < m_outputs.size(); ++i) {
        const auto output = m_outputs.at(i).toObject();
        if (output.contains("blinding_key")) {
            auto cbfa = getBlindingFactor(i, BTCHIP_BLINDING_FACTOR_ASSET);
            connect(cbfa, &Command::finished, this, [=] {
                m_abfs[i] = ReverseByteArray(cbfa->m_response);
            });

            auto cbfv = getBlindingFactor(i, BTCHIP_BLINDING_FACTOR_AMOUNT);
            connect(cbfv, &Command::finished, this, [=] {
                m_vbfs[i] = ReverseByteArray(cbfv->m_response);
            });
        }
    }

    m_batch->exec();
}

void LedgerGetBlindingFactorsActivity::startUntrustedTransaction(uint32_t version, bool new_transaction, int input_index, const QList<QByteArray>& inputs, const QList<QByteArray>& sequences, const QByteArray& redeem_script)
{
    Q_ASSERT(inputs.size() == sequences.size());
    {
        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::LittleEndian);
        stream << version << varint<uint32_t>(inputs.size());
        exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x00, new_transaction ? 0x06 : 0x80, data));
    }
    for (int i = 0; i < inputs.size(); ++i) {
        QByteArray script = i == input_index ? redeem_script : QByteArray();
        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::LittleEndian);
        stream << uint8_t(0x03);
        stream.writeRawData(inputs.at(i).data(), inputs.at(i).size());
        stream << varint<uint32_t>(script.size());

        exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x80, 0x00, data));
        exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x80, 0x00, script + sequences.at(i)));
    }
}

DeviceCommand* LedgerGetBlindingFactorsActivity::getBlindingFactor(uint32_t index, uint8_t type)
{
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::BigEndian);
    stream << index;
    return exchange(apdu(BTCHIP_CLA, BTCHIP_INS_GET_LIQUID_BLINDING_FACTOR, type, 0x00, data));
}
