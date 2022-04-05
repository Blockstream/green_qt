#include "command.h"
#include "ledgerdevice.h"
#include "ledgersignliquidtransactionactivity.h"
#include "util.h"

#include <wally_elements.h>

namespace {

QByteArray inputLiquidBytes(const QJsonObject& input)
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
    const auto commitment = ParseByteArray(input.value("commitment"));
    stream.writeRawData(commitment.data(), commitment.size());
    return data;
}

QByteArray sequenceBytes(const QJsonObject& input)
{
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    Q_ASSERT(input.contains("sequence"));
    stream << ParseSequence(input.value("sequence"));
    return data;
}

} // namespace

LedgerSignLiquidTransactionActivity::LedgerSignLiquidTransactionActivity(const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, LedgerDevice* device)
    : SignLiquidTransactionActivity(device)
    , m_device(device)
    , m_transaction(transaction)
    , m_inputs(signing_inputs)
    , m_outputs(outputs)
    , m_batch(new CommandBatch)
{
    connect(m_batch, &Command::error, this, [this] { fail(); });
}

void LedgerSignLiquidTransactionActivity::exec()
{
    exchange_total = 3 + 6 * m_inputs.size() + 5 * m_outputs.size();
    progress()->setTo(exchange_total);
    progress()->setIndeterminate(false);

    for (int i = 0; i < m_inputs.size(); ++i) {
        const auto input = m_inputs.at(i).toObject();
        m_hw_inputs.append(inputLiquidBytes(input));
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
        uint32_t version = m_transaction.value("transaction_version").toDouble();
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

void LedgerSignLiquidTransactionActivity::getLiquidCommitment(int output_index)
{
    if (output_index == m_outputs.size()) {
        return finalizeLiquidInputFull();
    }

    Q_ASSERT(output_index < m_outputs.size());
    const auto output = m_outputs.at(output_index).toObject();
    const bool last = (output_index + 2) == m_outputs.size();

    Q_ASSERT(output.contains("script"));
    if (output.value("script").toString().isEmpty()) {
        m_commitments.append(QByteArray());
        m_abfs.append(QByteArray());
        m_vbfs.append(QByteArray());
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
//        qDebug() << output;
        const auto script = ParseByteArray(output.value("script"));
        if (script.size() == 0) {
            QByteArray data;
            QDataStream stream(&data, QIODevice::WriteOnly);
            stream.setByteOrder(QDataStream::BigEndian);
            stream << uint8_t(0x01);
            const auto asset_id = ParseByteArray(output.value("asset_id"));
            Q_ASSERT(asset_id.size() == 32);
            for (int j = asset_id.size() - 1; j >= 0; --j) {
                stream << uint8_t(asset_id.at(j));
            }
            stream << uint8_t(0x01) << ParseSatoshi(output.value("satoshi"));
            res.append({{}, data});
        } else {
            res.append({{}, m_commitments.at(i).mid(64, 143)});
        }

        if (output.contains("blinding_key")) {
            const auto eph_keypair_pub = ParseByteArray(output.value("eph_keypair_pub"));
            const auto blinding_key = ParseByteArray(output.value("blinding_key"));
            res.append({{}, eph_keypair_pub});
            res.append({{}, blinding_key});
        } else {
            QByteArray nonce(1, 0);
            res.append({{}, nonce});
            res.append({{}, nonce});
        }

        {
            QByteArray data;
            QDataStream stream(&data, QIODevice::WriteOnly);
            stream.setByteOrder(QDataStream::LittleEndian);
            if (script.size() == 0) {
                stream << varint<uint32_t>(0);
            } else {
                stream << varint<uint32_t>(script.size());
                stream.writeRawData(script.data(), script.size());
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

    const uint32_t locktime = ParseLocktime(m_transaction.value("transaction_locktime"));

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

            stream.writeRawData(path.data(), data.size());

            stream.setByteOrder(QDataStream::BigEndian);

            // TODO android implementation uses empty pin, like:
            //    stream << uint8_t(0x00);
            QString pin = "0";
            auto _pin = pin.toUtf8();
            stream.writeRawData(path.data(), path.size());
            stream << uint8_t(pin.size());
            stream.writeRawData(_pin.data(), _pin.size());
            stream << uint32_t(locktime);
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
