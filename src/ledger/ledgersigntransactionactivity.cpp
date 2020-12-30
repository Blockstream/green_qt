#include "command.h"
#include "ledgerdevice.h"
#include "ledgersigntransactionactivity.h"
#include "util.h"

namespace {

QByteArray inputBytes(const QJsonObject& input, bool is_segwit)
{
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);

    QByteArray txhash_hex = ParseByteArray(input.value("txhash"));
    for (int i = txhash_hex.size() - 1; i >= 0; --i) {
        stream << uint8_t(txhash_hex.at(i));
    }
    uint32_t pt_idx = input.value("pt_idx").toInt();
    stream << pt_idx;
    if (is_segwit) {
        // TODO ensure "satoshi" is double, not an object
        const quint64 satoshi = ParseSatoshi(input.value("satoshi"));
        stream << satoshi;
    }
    return data;
}

} // namespace

LedgerSignTransactionActivity::LedgerSignTransactionActivity(uint32_t version, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, uint32_t locktime, LedgerDevice* device)
    : SignTransactionActivity(device)
    , m_device(device)
    , m_version(version)
    , m_transaction(transaction)
    , m_signing_inputs(signing_inputs)
    , m_outputs(outputs)
    , m_locktime(locktime)
{
}

QList<QByteArray> LedgerSignTransactionActivity::signatures() const
{
    return m_signatures;
}

DeviceCommand *LedgerSignTransactionActivity::exchange(const QByteArray &data)
{
    return m_device->exchange(data);
}

void LedgerSignTransactionActivity::exec()
{
    bool new_transaction = true;
    bool segwit = true;
    int input_index = 0;
    QList<Input> used_inputs;
    for (auto i : m_signing_inputs) {
        auto input = i.toObject();
        Input in;
        uint32_t sequence = ParseSequence(input.value("sequence"));
        QDataStream stream(&in.sequence, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::LittleEndian);
        stream << sequence;
        in.value = inputBytes(input, segwit);
        in.trusted = false;
        in.segwit = true;
        used_inputs.append(in);
    }
    Q_ASSERT(m_signing_inputs.size() > 0 && m_signing_inputs.first().toObject().contains("prevout_script"));
    const auto redeem_script = ParseByteArray(m_signing_inputs.first().toObject().value("prevout_script"));

    startUntrustedTransaction(new_transaction, input_index, used_inputs, redeem_script, true);
    auto bytes = outputBytes();
    finalizeInputFull(bytes);
    signSWInputs(used_inputs);
}

QByteArray LedgerSignTransactionActivity::outputBytes()
{
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    varInt(stream, m_outputs.size());
    for (const auto& out : m_outputs) {
        // TODO ensure "satoshi" is double, not an object
        const quint64 satoshi = ParseSatoshi(out["satoshi"]);
        const QByteArray script = ParseByteArray(out["script"]);
        stream << satoshi;
        varInt(stream, script.size());
        stream.writeRawData(script.data(), script.size());
    }
    return data;
}

void LedgerSignTransactionActivity::startUntrustedTransaction(bool new_transaction, int64_t input_index, const QList<Input> &used_input, const QByteArray &redeem_script, bool segwit)
{
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);

    // Start building a fake transaction with the passed inputs
    stream << m_version << varint<uint32_t>(used_input.size());
    const uint8_t p2 = new_transaction ? (segwit ? 0x02 : 0x00) : 0x80;
    auto c = exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x00, p2, data));
    connect(c, &Command::finished, [] {
        qDebug("startUntrustedTransaction OK");
    });
    hashInputs(used_input, input_index, redeem_script);
}

void LedgerSignTransactionActivity::hashInputs(const QList<Input> &used_inputs, int64_t input_index, const QByteArray &redeem_script)
{
    for (int index = 0; index < used_inputs.size(); ++index) {
        hashInput(used_inputs.at(index), index == input_index ? redeem_script : QByteArray());
    }
}

void LedgerSignTransactionActivity::hashInput(const Input &input, const QByteArray &script)
{
    const uint8_t first = input.segwit ? 0x02 : (input.trusted ? 0x01 : 0x00);
    const QByteArray value = QByteArray::fromHex(input.value);

    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);

    stream << first;
    if (input.trusted) stream << uint8_t(input.value.size());
    stream.writeRawData(input.value.data(), input.value.size());
    stream << varint<uint32_t>(script.size());

    auto c1 = exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x80, 0x00, data));
    auto seq = input.sequence;
    connect(c1, &Command::finished, [this, script, seq] {
        qDebug("HASH INPUT 1ST FINISHED");
        //        QByteArray data;
        //        QDataStream stream(&data, QIODevice::WriteOnly);
        //        stream.setByteOrder(QDataStream::LittleEndian);

    });
    auto c2 = exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x80, 0x00, script + seq));
    connect(c2, &Command::finished, [] {
        qDebug("HASH INPUT 2ND FINISHED!");
    });
}

void LedgerSignTransactionActivity::signSWInputs(const QList<Input> &hwInputs)
{
    count = hwInputs.size();
    for (int i = 0; i < hwInputs.size(); ++i) {
        const auto& input = hwInputs.at(i);
        signSWInput(input, m_signing_inputs.at(i).toObject());
    }
}

void LedgerSignTransactionActivity::signSWInput(const Input &hwInput, const QJsonObject &input)
{
    auto script = ParseByteArray(input.value("prevout_script"));
    startUntrustedTransaction(false, 0, {hwInput}, script, true);
    QVector<uint32_t> user_path = ParsePath(input.value("user_path"));
    uint8_t SIGHASH_ALL = 1;
    untrustedHashSign(user_path, "0", SIGHASH_ALL);
}

void LedgerSignTransactionActivity::untrustedHashSign(const QVector<uint32_t> &private_key_path, QString pin, uint8_t sig_hash_type)
{
    auto path = pathToData(private_key_path);
    auto _pin = pin.toUtf8();
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.writeRawData(path.data(), path.size());
    stream.setByteOrder(QDataStream::BigEndian);
    stream << uint8_t(pin.size());
    stream.writeRawData(_pin.data(), _pin.size());
    stream << uint32_t(m_locktime) << sig_hash_type;
    qDebug("untrustedHashSign EXCHANGE");
    auto c1 = exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_SIGN, 0, 0, data));
    connect(c1, &Command::error, [] {
        qDebug("untrustedHashSign FAILED!!!!!!!!!");
    });
    connect(c1, &Command::finished, [this, c1] {
        qDebug("untrustedHashSign FINISHED!!");
        QByteArray signature;
        signature.append(0x30);
        signature.append(c1->m_response.mid(1));
        //signature = x;
        m_signatures.append(signature);
        if (m_signatures.size() == count) {
            finish();
        }
    });
}

void LedgerSignTransactionActivity::finalizeInputFull(const QByteArray &data)
{
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
        auto c1 = exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_FINALIZE_FULL, p1, 0x00, datas.at(i)));
        connect(c1, &Command::finished, [i, c1, datas] {
        });
    }
}
