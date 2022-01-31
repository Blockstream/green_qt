#include "command.h"
#include "ledgerdevice.h"
#include "ledgersigntransactionactivity.h"
#include "util.h"

#include <wally_transaction.h>

LedgerSignTransactionActivity::LedgerSignTransactionActivity(const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions, const QJsonArray& signing_address_types, LedgerDevice* device)
    : SignTransactionActivity(device)
    , m_device(device)
    , m_transaction(transaction)
    , m_signing_inputs(signing_inputs)
    , m_transaction_outputs(transaction_outputs)
    , m_signing_transactions(signing_transactions)
    , m_signing_address_types(signing_address_types)
{
}

QList<QByteArray> LedgerSignTransactionActivity::signatures() const
{
    return m_signatures.toList();
}

QList<QByteArray> LedgerSignTransactionActivity::signerCommitments() const
{
    Q_UNREACHABLE();
}

DeviceCommand *LedgerSignTransactionActivity::exchange(CommandBatch* batch, const QByteArray& data)
{
    auto command = new LedgerGenericCommand(m_device, data);
    batch->add(command);
    return command;
}

void LedgerSignTransactionActivity::exec()
{
    const bool sw = m_signing_address_types.contains("p2wsh") || m_signing_address_types.contains("csv");
    const bool p2sh = m_signing_address_types.contains("p2sh");

    // Hardware Wallet cannot sign sweep inputs
    Q_ASSERT(!m_signing_address_types.contains("p2pkh"));

    auto batch = new CommandBatch;

    m_signatures.resize(m_signing_inputs.size());
    if (sw) batch->add(signSW());
    if (p2sh) batch->add(signNonSW());

    connect(batch, &CommandBatch::finished, [this, batch] {
        batch->deleteLater();
        emit finished();
    });
    connect(batch, &CommandBatch::error, [this, batch] {
        batch->deleteLater();
        emit fail();
    });

    batch->exec();
}

QByteArray LedgerSignTransactionActivity::outputBytes()
{
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    varInt(stream, m_transaction_outputs.size());
    for (const auto& out : m_transaction_outputs) {
        // TODO ensure "satoshi" is double, not an object
        const quint64 satoshi = ParseSatoshi(out["satoshi"]);
        const QByteArray script = ParseByteArray(out["script"]);
        stream << satoshi;
        varInt(stream, script.size());
        stream.writeRawData(script.data(), script.size());
    }
    return data;
}

Command* LedgerSignTransactionActivity::finalizeInputFull(const QByteArray &data)
{
    auto batch = new CommandBatch;
    QList<QByteArray> datas;
    QByteArray x;
    x.append(uint8_t(0));
    datas.append(x);
    int offset = 0;
    while (offset < data.size()) {
        int blockLength = (data.size() - offset) > 255 ? 255 : data.size() - offset;
        datas.append(data.mid(offset, blockLength));
        offset += blockLength;
    }

    for (int i = 0; i < datas.size(); ++i) {
        uint8_t p1 = i == 0 ? 0xff : (i == datas.size() - 1 ? 0x80 : 0x00);
        exchange(batch, apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_FINALIZE_FULL, p1, 0x00, datas.at(i)));
    }
    return batch;
}

Command* LedgerSignTransactionActivity::untrustedHashSign(int index, const QVector<uint32_t> &private_key_path, QString pin, uint32_t locktime)
{
    const uint8_t sig_hash_type = 1;
    auto batch = new CommandBatch;

    auto path = pathToData(private_key_path);
    auto _pin = pin.toUtf8();
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.writeRawData(path.data(), path.size());
    stream.setByteOrder(QDataStream::BigEndian);
    stream << uint8_t(pin.size());
    stream.writeRawData(_pin.data(), _pin.size());
    stream << locktime << sig_hash_type;
    auto cmd = exchange(batch, apdu(BTCHIP_CLA, BTCHIP_INS_HASH_SIGN, 0, 0, data));
    connect(cmd, &Command::finished, [this, cmd, index] {
        QByteArray signature;
        signature.append(0x30);
        signature.append(cmd->m_response.mid(1));
        m_signatures[index] = signature;
    });
    return batch;
}

Command* LedgerSignTransactionActivity::signSW()
{
    auto batch = new CommandBatch;
    auto cmd = getHwInputs(true);
    connect(cmd, &Command::finished, [this, batch] {
        // Prepare the pseudo transaction
        // Provide the first script instead of a null script to initialize the P2SH confirmation logic
        const uint32_t version = m_transaction.value("transaction_version").toDouble();
        const uint32_t locktime = m_transaction.value("transaction_locktime").toDouble();
        const auto script0 = ParseByteArray(m_signing_inputs[0].toObject().value("prevout_script"));
        batch->add(startUntrustedTransaction(version, true, 0, m_hw_inputs, script0, true));
        batch->add(finalizeInputFull(outputBytes()));

        for (int i = 0; i < m_hw_inputs.size(); i++) {
            const auto input = m_signing_inputs[i].toObject();
            const auto address_type = input.value("address_type").toString();
            if (address_type == "p2sh") continue;
            const auto script = ParseByteArray(input.value("prevout_script"));
            const auto user_path = ParsePath(input.value("user_path"));

            batch->add(startUntrustedTransaction(version, false, 0, m_hw_inputs.mid(i, 1), script, true));
            batch->add(untrustedHashSign(i, user_path, "0", locktime));
        }

        m_hw_inputs.clear();
    });
    batch->add(cmd);
    return batch;
}

Command* LedgerSignTransactionActivity::signNonSW()
{
    auto batch = new CommandBatch;
    auto cmd = getHwInputs(false);
    connect(cmd, &Command::finished, [this, batch] {
        const uint32_t version = m_transaction.value("transaction_version").toDouble();
        const uint32_t locktime = m_transaction.value("transaction_locktime").toDouble();
        const auto data = outputBytes();

        for (int i = 0; i < m_hw_inputs.size(); i++) {
            const auto input = m_signing_inputs[i].toObject();
            const auto address_type = input.value("address_type").toString();
            const auto script = ParseByteArray(input.value("prevout_script"));
            const auto user_path = ParsePath(input.value("user_path"));

            batch->add(startUntrustedTransaction(version, i == 0, i, m_hw_inputs, script, false));
            batch->add(finalizeInputFull(data));
            if (address_type == "p2sh") batch->add(untrustedHashSign(i, user_path, "0", locktime));
        }
    });
    batch->add(cmd);
    return batch;
}

QByteArray sequenceBytes(const QJsonObject& in)
{
    const uint32_t sequence = in.value("sequence").toDouble();
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    stream << sequence;
    return data;
}

Command* LedgerSignTransactionActivity::getHwInputs(bool segwit)
{
    const bool shouldUseTrustedInputForSegwit = true;
    const bool prefer_trusted_inputs = !segwit || shouldUseTrustedInputForSegwit;

    auto batch = new CommandBatch;

    if (prefer_trusted_inputs) {
        for (const auto i : m_signing_inputs) {
            const auto input = i.toObject();
            const auto txhash = input.value("txhash").toString();
            uint32_t index = input.value("pt_idx").toDouble();
            uint32_t sequence = input.value("sequence").toDouble();
            Q_ASSERT(m_signing_transactions.contains(txhash));
            const auto raw = ParseByteArray(m_signing_transactions.value(txhash));
            batch->add(getTrustedInput(raw, index, sequence, segwit));
        }
    } else {
        Q_UNREACHABLE();
    }

    return batch;
}

Command* LedgerSignTransactionActivity::getTrustedInput(const QByteArray& raw, uint32_t index, uint32_t sequence, bool segwit)
{
    auto batch = new CommandBatch;

    wally_tx* tx;
    wally_tx_from_bytes((const unsigned char*) raw.constData(), raw.size(), WALLY_TX_FLAG_USE_WITNESS, &tx);

    {
        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::BigEndian);
        stream << index;
        stream.setByteOrder(QDataStream::LittleEndian);
        stream << tx->version;
        stream << varint<uint32_t>(tx->num_inputs);
        exchange(batch, apdu(BTCHIP_CLA, BTCHIP_INS_GET_TRUSTED_INPUT, 0x00, 0x00, data));
    }
    for (size_t i = 0; i < tx->num_inputs; ++i) {
        const auto input = tx->inputs + i;
        {
            QByteArray data;
            QDataStream stream(&data, QIODevice::WriteOnly);
            stream.setByteOrder(QDataStream::LittleEndian);
            stream.writeRawData((const char*) input->txhash, 32);
            stream << input->index;
            stream << varint<uint32_t>(input->script_len);
            exchange(batch, apdu(BTCHIP_CLA, BTCHIP_INS_GET_TRUSTED_INPUT, 0x80, 0x00, data));
        }
        {
            QByteArray data;
            QDataStream stream(&data, QIODevice::WriteOnly);
            stream.setByteOrder(QDataStream::LittleEndian);
            stream.writeRawData((const char*) input->script, input->script_len);
            stream << input->sequence;
            exchange(batch, apdu(BTCHIP_CLA, BTCHIP_INS_GET_TRUSTED_INPUT, 0x80, 0x00, data));
        }
    }
    {
        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream << varint<uint32_t>(tx->num_outputs);
        exchange(batch, apdu(BTCHIP_CLA, BTCHIP_INS_GET_TRUSTED_INPUT, 0x80, 0x00, data));
    }
    for (size_t i = 0; i < tx->num_outputs; ++i) {
        const auto output = tx->outputs + i;
        {
            QByteArray data;
            QDataStream stream(&data, QIODevice::WriteOnly);
            stream.setByteOrder(QDataStream::LittleEndian);
            stream << quint64(output->satoshi) << varint<uint32_t>(output->script_len);
            exchange(batch, apdu(BTCHIP_CLA, BTCHIP_INS_GET_TRUSTED_INPUT, 0x80, 0x00, data));
        }
        {
            const auto data = QByteArray((const char*) output->script, output->script_len);
            exchange(batch, apdu(BTCHIP_CLA, BTCHIP_INS_GET_TRUSTED_INPUT, 0x80, 0x00, data));
        }
    }

    {
        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::LittleEndian);
        stream << tx->locktime;

        auto cmd = exchange(batch, apdu(BTCHIP_CLA, BTCHIP_INS_GET_TRUSTED_INPUT, 0x80, 0x00, data));
        connect(cmd, &Command::finished, [this, cmd, sequence, segwit] {
            Input input;
            input.value = cmd->m_response;
            input.segwit = segwit;
            input.trusted = true;

            QDataStream stream(&input.sequence, QIODevice::WriteOnly);
            stream.setByteOrder(QDataStream::LittleEndian);
            stream << sequence;

            m_hw_inputs.append(input);
        });
    }

    wally_tx_free(tx);

    return batch;
}

Command* LedgerSignTransactionActivity::startUntrustedTransaction(uint32_t version, bool new_transaction, size_t index, const QList<Input>& used_inputs, const QByteArray& redeem_script, bool segwit)
{
    auto batch = new CommandBatch;

    {
        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::LittleEndian);
        stream << version << varint<uint32_t>(used_inputs.size());
        exchange(batch, apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x00, new_transaction ? (segwit ? 0x02 : 0x00) : 0x80, data));
    }

    size_t current_index = 0;
    for (auto input : used_inputs) {
        const auto script = (current_index == index ? redeem_script : QByteArray());
        {
            QByteArray data;
            QDataStream stream(&data, QIODevice::WriteOnly);
            stream << uint8_t(input.trusted ? 0x01 : (input.segwit ? 0x02 : 0x00));
            if (input.trusted) stream << uint8_t(input.value.size());
            stream.writeRawData(input.value.data(), input.value.size());
            stream << varint<uint32_t>(script.size());
            exchange(batch, apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x80, 0x00, data));
        }
        {
            const auto data = script + input.sequence;
            exchange(batch, apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x80, 0x00, data));
        }
        current_index++;
    }
    return batch;
}
