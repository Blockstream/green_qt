#include "device.h"
#include "device_p.h"
#include "ga.h"
#include "handler.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
#include "util.h"
#include "wallet.h"
#include "walletmanager.h"


#define BTCHIP_CLA              0xe0
#define BTCHIP_CLA_COMMON_SDK   0xb0

#define BTCHIP_INS_GET_APP_NAME_AND_VERSION         0x01
#define BTCHIP_INS_GET_LIQUID_BLINDING_KEY          0xe2
#define BTCHIP_INS_HASH_INPUT_START                 0x44
#define BTCHIP_INS_HASH_INPUT_FINALIZE_FULL         0x4a
#define BTCHIP_INS_HASH_SIGN                        0x48
#define BTCHIP_INS_GET_WALLET_PUBLIC_KEY            0x40
#define BTCHIP_INS_GET_LIQUID_BLINDING_KEY          0xe2
#define BTCHIP_INS_GET_LIQUID_NONCE                 0xe4
#define BTCHIP_INS_GET_LIQUID_COMMITMENTS           0xe0
#define BTCHIP_INS_GET_LIQUID_BLINDING_FACTOR       0xe8
#define BTCHIP_INS_GET_LIQUID_ISSUANCE_INFORMATION  0xe6
#define BTCHIP_INS_GET_FIRMWARE_VERSION             0xc4
#define BTCHIP_INS_SIGN_MESSAGE                     0x4e

#include <wally_core.h>
#include <wally_bip32.h>
#include <wally_elements.h>

template <typename T> struct Varint { T v; };
template <typename T> Varint<T> varint(T v) { return {v}; }
QDataStream& operator<<(QDataStream& out, const Varint<uint32_t>& v)
{
    if (v.v < 0xfd) return out << uint8_t(v.v & 0xff);
    if (v.v < 0xffff) return out << uint8_t(0xfd) << uint8_t(v.v & 0xff) << uint8_t((v.v >> 8) & 0xff);
    return out << uint8_t(0xfe) << v.v;
}

QByteArray apdu(uint8_t cla, uint8_t ins, uint8_t p1, uint8_t p2, const QByteArray& data = QByteArray())
{
    QByteArray result;
    QDataStream stream(&result, QIODevice::WriteOnly);
    Q_ASSERT(data.length() < 256);
    stream << cla << ins << p1 << p2 << uint8_t(data.length());
    return result + data;
}

QByteArray compressPublicKey(const QByteArray& pubkey)
{
    Q_ASSERT(pubkey.size() > 0);
    switch (pubkey[0]) {
    case 0x04:
        Q_ASSERT(pubkey.size() == 65);
        break;
    case 0x02:
    case 0x03:
        Q_ASSERT(pubkey.size() == 33);
        return pubkey;
    default:
        Q_UNREACHABLE();
    }
    auto type = pubkey[64] & 0x01 ? 0x03 : 0x02;
    return pubkey.mid(1, 32).prepend(type);
}



Device::Device(DevicePrivate* d, QObject* parent)
    : QObject(parent)
    , d(d)
{
    d->q = this;
}

Device::~Device()
{
    delete d;
}

Device::Type Device::type() const
{
    return d->m_type;
}

Device::Transport Device::transport() const
{
    return d->m_transport;
}

QString Device::name() const
{
    switch (d->m_type) {
    case LedgerNanoS: return "Ledger Nano S";
    case LedgerNanoX: return "Ledger Nano X";
    default: Q_UNREACHABLE();
    }
}

bool Device::isBusy() const
{
    return !d->queue.empty();
}

QString Device::appName() const
{
    return d->app_name;
}

void Device::setAppName(const QString& app_name)
{
    if (d->app_name == app_name) return;
    d->app_name = app_name;
    emit appNameChanged();
}

void Device::exchange(DeviceCommand* command)
{
    d->exchange(command);
}

DeviceCommand* Device::exchange(const QByteArray& data) {
    auto command = new GenericCommand(this, data);
    command->exec();
    return command;
}

class LedgerGetWalletPublicKeyActivity : public GetWalletPublicKeyActivity
{
public:
    LedgerGetWalletPublicKeyActivity(Network* network, const QVector<uint32_t>& path, Device* device)
        : GetWalletPublicKeyActivity(device)
        , m_network(network)
        , m_path(path)
    {
    }
    void exec() override
    {
        QByteArray path;
        QDataStream s(&path, QIODevice::WriteOnly);
        s << uint8_t(m_path.size());
        for (auto p : m_path) s << uint32_t(p);
        auto cmd = device()->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_GET_WALLET_PUBLIC_KEY, 0x0, 0, path));
        connect(cmd, &GenericCommand::finished, this, [this, cmd] {
            cmd->deleteLater();
            uint32_t version = m_network->data().value("mainnet").toBool() ? BIP32_VER_MAIN_PUBLIC : BIP32_VER_TEST_PUBLIC;
            QDataStream stream(&cmd->m_response, QIODevice::ReadOnly);
            uint8_t pubkey_len, address_len;
            stream >> pubkey_len;
            QByteArray pubkey(pubkey_len, 0);
            stream.readRawData(pubkey.data(), pubkey_len);
            stream >> address_len;
            QByteArray address(address_len, 0);
            stream.readRawData(address.data(), address_len);
            QByteArray chain_code(32, 0);

            stream.readRawData(chain_code.data(), 33);

            pubkey = compressPublicKey(pubkey);
            ext_key* k;
            int x = bip32_key_init_alloc(version, 1, 0, (const unsigned char *) chain_code.data(), chain_code.length(), (const unsigned char *) pubkey.constData(), pubkey.length(), nullptr, 0, nullptr, 0, nullptr, 0, &k);
            Q_ASSERT(x == 0);

            char* base58;
            x = bip32_key_to_base58(k, BIP32_FLAG_KEY_PUBLIC, &base58);
            Q_ASSERT(x == 0);
            bip32_key_free(k);

            QString xpub(base58);

            wally_free_string(base58);
            setResult(xpub);
        });
        connect(cmd, &Command::error, this, [this, cmd] {
            cmd->deleteLater();
            fail();
        });
    }
    Network* const m_network;
    const QVector<uint32_t> m_path;
};

GetWalletPublicKeyActivity *Device::getWalletPublicKey(Network* network, const QVector<uint32_t>& path)
{
    return new LedgerGetWalletPublicKeyActivity(network, path, this);
}

class SignMessageCommand2 : public Command2<QByteArray>
{
public:
    SignMessageCommand2(const QString& message, const QVector<uint32_t>& path, Device* device)
        : Command2<QByteArray>(device)
        , m_message(message)
        , m_path(path)
    {
    }
    virtual void exec() override
    {
        auto batch = new CommandBatch;
        auto prepare_command = new SignMessageCommand(device(), m_path, m_message.toLocal8Bit());
        auto sign_command = new SignMessageCommand(device());
        batch->add(prepare_command);
        batch->add(sign_command);
        connect(batch, &Command::finished, this, [this, sign_command] {
            setResult(sign_command->m_response);
        });
        batch->exec();
    }
    const QString m_message;
    const QVector<uint32_t> m_path;
};

Command2<QByteArray>* Device::signMessage(const QString& message, const QVector<uint32_t>& path)
{
    return new SignMessageCommand2(message, path, this);
}

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

int varIntSize(int i) {
    // if negative, it's actually a very large unsigned long value
    if (i < 0) return 9; // 1 marker + 8 data bytes
    if (i< 253) return 1; // 1 data byte
    if (i <= 0xFFFF) return 3; // 1 marker + 2 data bytes
    if (i <= 0xFFFFFFFF) return 5; // 1 marker + 4 data bytes
    return 9; // 1 marker + 8 data bytes
}

void varInt(QDataStream& stream, int64_t i)
{
    switch (varIntSize(i)) {
    case 1:
        stream << uint8_t(i);
        break;
    case 3:
        stream << uint8_t(253) << uint8_t(i & 0xff) << uint8_t((i >> 8) & 0xff);
        break;
    case 5:
        stream << uint8_t(254) << uint32_t(i);
        break;
    default:
        stream << uint8_t(255) << qint64(i);
    }
}

QByteArray pathToData(const QVector<uint32_t>& path)
{
    Q_ASSERT(path.size() <= 10);
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::BigEndian);
    stream << uint8_t(path.size());
    for (int32_t p : path) stream << uint32_t(p);
    return data;
}

QByteArray outputBytes(const QJsonArray outputs)
{
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    varInt(stream, outputs.size());
    for (const auto& out : outputs) {
        // TODO ensure "satoshi" is double, not an object
        const quint64 satoshi = ParseSatoshi(out["satoshi"]);
        const QByteArray script = ParseByteArray(out["script"]);
        stream << satoshi;
        varInt(stream, script.size());
        stream.writeRawData(script.data(), script.size());
    }
    return data;
}

SignLiquidTransactionCommand::SignLiquidTransactionCommand(Device* device, const QJsonObject& required_data, CommandBatch* batch)
    : DeviceCommand(device, batch)
    , m_required_data(required_data)
    , m_batch(new CommandBatch)
{
    connect(m_batch, &Command::error, this, &Command::error);
}

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

void SignLiquidTransactionCommand::exec()
{
    m_transaction = m_required_data.value("transaction").toObject();
    m_version = m_transaction.value("transaction_version").toDouble();
    m_inputs = m_required_data.value("signing_inputs").toArray();
    m_outputs = m_required_data.value("transaction_outputs").toArray();

    exchange_total = 3 + 6 * m_inputs.size() + 5 * m_outputs.size();

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

void SignLiquidTransactionCommand::startUntrustedTransaction(bool new_transaction, int input_index, const QList<QByteArray>& inputs, const QList<QByteArray>& sequences, const QByteArray& redeem_script)
{
    Q_ASSERT(inputs.size() == sequences.size());
    {
        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::LittleEndian);
        stream << uint32_t(m_version) << varint<uint32_t>(inputs.size());
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

void SignLiquidTransactionCommand::getLiquidCommitment(int output_index)
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

DeviceCommand *SignLiquidTransactionCommand::exchange(const QByteArray& data)
{
    auto command = new GenericCommand(m_device, data);
    connect(command, &Command::finished, [this] {
       exchange_count ++;
       emit progressChanged(exchange_count, exchange_total);
    });
    m_batch->add(command);
    return command;
}

QList<QPair<QJsonObject, QByteArray>> SignLiquidTransactionCommand::outputLiquidBytes()
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

        if (output.contains("public_key")) {
            const auto eph_keypair_pub = ParseByteArray(output.value("eph_keypair_pub"));
            const auto public_key = ParseByteArray(output.value("public_key"));
            res.append({{}, eph_keypair_pub});
            res.append({{}, public_key});
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


void SignLiquidTransactionCommand::finalizeLiquidInputFull()
{
    int i = 0;
    m_output_liquid_bytes = outputLiquidBytes();
    for (const auto& data : m_output_liquid_bytes) {
        auto c = exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_FINALIZE_FULL, i == m_output_liquid_bytes.size()-1 ? 0x80 : 0x00, 0x00, data.second));
        connect(c, &Command::finished, [this, i] {
            if (i + 1 < m_output_liquid_bytes.size()) {
                emit message(m_output_liquid_bytes.at(i + 1).first);
            } else {
                emit message({});
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
                    finished();
                }
            });
        }
    }
}


class SignTransactionCommand2 : public Command2<QList<QByteArray>>
{
public:
    SignTransactionCommand2(const QJsonObject& required_data, Device* device)
        : Command2<QList<QByteArray>>(device)
        , m_required_data(required_data)
    {
    }
    void exec() override
    {
        Q_ASSERT(m_required_data.value("action").toString() == "sign_tx");

        auto transaction = m_required_data.value("transaction").toObject();
        auto inputs = m_required_data.value("signing_inputs").toArray();
        auto outputs = m_required_data.value("transaction_outputs").toArray();
        // these are unused
        uint32_t version = transaction.value("transaction_version").toInt();
        uint32_t locktime = transaction.value("transaction_locktime").toInt();

        bool new_transaction = true;
        bool segwit = true;
        int input_index = 0;
        QList<Input> used_inputs;
        for (auto i : inputs) {
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
        Q_ASSERT(inputs.size() > 0 && inputs.first().toObject().contains("prevout_script"));
        const auto redeem_script = ParseByteArray(inputs.first().toObject().value("prevout_script"));

        startUntrustedTransaction(version, new_transaction, input_index, used_inputs, redeem_script, true);
        auto bytes = outputBytes(outputs);
        finalizeInputFull(bytes);
        signSWInputs(used_inputs, inputs, version, locktime);
    }
    void startUntrustedTransaction(uint32_t tx_version, bool new_transaction, int64_t input_index, const QList<Input>& used_input, const QByteArray& redeem_script, bool segwit)
    {
        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::LittleEndian);

        // Start building a fake transaction with the passed inputs
        stream << tx_version << varint<uint32_t>(used_input.size());
        const uint8_t p2 = new_transaction ? (segwit ? 0x02 : 0x00) : 0x80;
        auto c = device()->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x00, p2, data));
        connect(c, &Command::finished, [] {
            qDebug("startUntrustedTransaction OK");
        });
        hashInputs(used_input, input_index, redeem_script);
    }

    void hashInputs(const QList<Input>& used_inputs, int64_t input_index, const QByteArray& redeem_script)
    {
        for (int index = 0; index < used_inputs.size(); ++index) {
            hashInput(used_inputs.at(index), index == input_index ? redeem_script : QByteArray());
        }
    }

    void hashInput(const Input& input, const QByteArray& script)
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

        auto c1 = device()->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x80, 0x00, data));
        auto seq = input.sequence;
        connect(c1, &Command::finished, [this, script, seq] {
            qDebug("HASH INPUT 1ST FINISHED");
    //        QByteArray data;
    //        QDataStream stream(&data, QIODevice::WriteOnly);
    //        stream.setByteOrder(QDataStream::LittleEndian);

        });
        auto c2 = device()->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_START, 0x80, 0x00, script + seq));
        connect(c2, &Command::finished, [] {
            qDebug("HASH INPUT 2ND FINISHED!");
        });
    }
    void signSWInputs(const QList<Input>& hwInputs, const QJsonArray& inputs, uint32_t version, uint32_t locktime)
    {
        count = hwInputs.size();
        for (int i = 0; i < hwInputs.size(); ++i) {
            const auto& input = hwInputs.at(i);
            signSWInput(input, inputs.at(i).toObject(), version, locktime);
        }
    }

    void signSWInput(const Input& hwInput, const QJsonObject& input, uint32_t version, uint32_t locktime)
    {
        auto script = ParseByteArray(input.value("prevout_script"));
        startUntrustedTransaction(version, false, 0, {hwInput}, script, true);
        QVector<uint32_t> user_path = ParsePath(input.value("user_path"));
        uint8_t SIGHASH_ALL = 1;
        untrustedHashSign(user_path, "0", locktime, SIGHASH_ALL);
    }
    void untrustedHashSign(const QVector<uint32_t>& private_key_path, QString pin, uint32_t locktime, uint8_t sig_hash_type)
    {
        auto path = pathToData(private_key_path);
        auto _pin = pin.toUtf8();
        QByteArray data;
        QDataStream stream(&data, QIODevice::WriteOnly);
        stream.writeRawData(path.data(), path.size());
        stream.setByteOrder(QDataStream::BigEndian);
        stream << uint8_t(pin.size());
        stream.writeRawData(_pin.data(), _pin.size());
        stream << uint32_t(locktime) << sig_hash_type;
        qDebug("untrustedHashSign EXCHANGE");
        auto c1 = device()->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_SIGN, 0, 0, data));
        connect(c1, &Command::error, [] {
           qDebug("untrustedHashSign FAILED!!!!!!!!!");
        });
        connect(c1, &Command::finished, [this, c1] {
           qDebug("untrustedHashSign FINISHED!!");
           QByteArray signature;
           signature.append(0x30);
           signature.append(c1->m_response.mid(1));
           //signature = x;
           signatures.append(signature);
           if (signatures.size() == count) {
               setResult(signatures);
           }
        });
    }
    void finalizeInputFull(const QByteArray& data)
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
            auto c1 = device()->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_HASH_INPUT_FINALIZE_FULL, p1, 0x00, datas.at(i)));
            connect(c1, &Command::finished, [i, c1, datas] {
            });
        }
    }
    const QJsonObject m_required_data;
    int count{0};
    QList<QByteArray> signatures;
};

Command2<QList<QByteArray>>* Device::signTransaction(const QJsonObject& required_data)
{
    return new SignTransactionCommand2(required_data, this);
}

GetBlindingKeyCommand *Device::getBlindingKey(const QString& script)
{
    auto command = new GetBlindingKeyCommand(this, script);
    command->exec();
    return command;
}


GetBlindingNonceCommand *Device::getBlindingNonce(const QByteArray& pubkey, const QByteArray& script)
{
    auto command = new GetBlindingNonceCommand(this, pubkey, script);
    command->exec();
    return command;
}


Device::Type Device::typefromVendorAndProduct(uint32_t vendor_id, uint32_t product_id)
{
    if (vendor_id == LEDGER_VENDOR_ID) {
        if (product_id == 0x0001 || product_id & 0x1000) {
            return Device::LedgerNanoS;
        }
        if (product_id == 0x0004 || product_id & 0x4000) {
            return Device::LedgerNanoX;
        }
    }
    return Device::Unknown;
}


QByteArray GetFirmwareCommand::payload() const
{
    return apdu(BTCHIP_CLA, BTCHIP_INS_GET_FIRMWARE_VERSION, 0x00, 0x00);
}

bool GetFirmwareCommand::parse(QDataStream &stream)
{
    uint8_t features, arch, fw_major, fw_minor, fw_patch, loader_major, loader_minor;
    stream >> features >> arch >> fw_major >> fw_minor >> fw_patch >> loader_major >> loader_minor;
    Q_ASSERT(arch == 0x30);
    //    0x01 : public keys are compressed (otherwise not compressed)
    //    0x02 : implementation running with screen + buttons handled by the Secure Element
    //    0x04 : implementation running with screen + buttons handled externally
    //    0x08 : NFC transport and payment extensions supported
    //    0x10 : BLE transport and low power extensions supported
    //    0x20 : implementation running on a Trusted Execution Environment
    qDebug() << features << arch << fw_major << fw_minor << fw_patch << loader_major << loader_minor;
    return true;
}

bool DeviceCommand::readAPDUResponse(Device* device, int length, QDataStream &stream)
{
    QByteArray response;
    if (length > 0) {
        response.resize(length - 2);
        stream.readRawData(response.data(), length - 2);
    }
    uint16_t sw;
    stream >> sw;
    if (sw != 0x9000) {
        qDebug() << "SW = " << sw;
        emit error();
        return false;
    }
    bool result = parse(response);
    if (result) {
        m_response = response;
        emit finished();
    }
    return result;
}

void DeviceCommand::exec()
{
    m_device->exchange(this);
}

Command::Command(CommandBatch* batch)
    : QObject(batch)
{
    if (batch) batch->add(this);
}

Command::~Command()
{

}

bool DeviceCommand::parse(const QByteArray& data)
{
    QDataStream stream(data);
    return parse(stream);
}

int DeviceCommand::readHIDReport(Device* device, QDataStream& stream)
{
    // General transport
    uint16_t channel_id;
    uint8_t command_tag;
    uint16_t index;
    stream >> channel_id >> command_tag >> index;

#define CHANNEL_DEFAULT_ID 0x0101
#define TAG_APDU 0x05
#define TAG_PING 0x02

    Q_ASSERT(channel_id == CHANNEL_DEFAULT_ID);
    if (command_tag == TAG_PING) Q_UNIMPLEMENTED();
    Q_ASSERT(command_tag == TAG_APDU);

    if (index == 0) {
        Q_ASSERT(buf.size() == 0);
        stream >> length;
        buf.resize(length);
        offset = 0;
    }

    int read = stream.readRawData(buf.data() + offset, length);
    length -= read;
    offset += read;

    if (length > 0) return 2;

    //qDebug() << "READ APDU RESPONSE" << buf.toHex();

    QDataStream s(buf);
    return readAPDUResponse(device, buf.size(), s) ? 0 : 1;
}

QByteArray GetAppNameCommand::payload() const
{
    return apdu(BTCHIP_CLA_COMMON_SDK, BTCHIP_INS_GET_APP_NAME_AND_VERSION, 0x00, 0x00);
}

bool GetAppNameCommand::parse(QDataStream& stream)
{
    uint8_t format;
    stream >> format;

    char* name = new char[256];
    char* version = new char[256];

    uint8_t name_length, version_length;

    stream >> name_length;
    stream.readRawData(name, name_length);
    stream >> version_length;
    stream.readRawData(version, version_length);

    m_name = QString::fromLocal8Bit(name, name_length);
    m_version = QString::fromLocal8Bit(version, version_length);
    return true;
}



QByteArray SignMessageCommand::payload() const
{
    if (!m_message.isEmpty() && !m_path.isEmpty()) {
        QByteArray data;
        QDataStream s(&data, QIODevice::WriteOnly);
        s << uint8_t(m_path.size());
        for (auto p : m_path) s << uint32_t(p);
        s << uint8_t(0) << uint8_t(m_message.length());
        s.writeRawData(m_message.constData(), m_message.size());
        return apdu(BTCHIP_CLA, BTCHIP_INS_SIGN_MESSAGE, 0x0, 1, data);
    }
    Q_ASSERT(m_message.isEmpty() && m_path.isEmpty());
    QByteArray data;
    QDataStream s(&data, QIODevice::WriteOnly);
    s << uint8_t(1) << uint8_t(0);
    return apdu(BTCHIP_CLA, BTCHIP_INS_SIGN_MESSAGE, 0x80, 1, data);

}

bool SignMessageCommand::parse(QDataStream &stream)
{
    if (m_message.isEmpty() && m_path.isEmpty()) {
        uint8_t b;
        stream >> b;
        signature.append(0x30);
        while (stream.readRawData((char*) &b, 1) == 1) {
            signature.append(b);
        }
        return true;
    }

    return true;
}

QByteArray GetBlindingKeyCommand::payload() const
{
    return apdu(BTCHIP_CLA, BTCHIP_INS_GET_LIQUID_BLINDING_KEY, 0x00, 0x00, ParseByteArray(m_script));
}

bool GetBlindingKeyCommand::parse(const QByteArray& data)
{
    m_pubkey = compressPublicKey(data);
    return true;
}


QByteArray GetBlindingNonceCommand::payload() const
{
    return apdu(BTCHIP_CLA, BTCHIP_INS_GET_LIQUID_NONCE, 0x00, 0x00, m_pubkey + m_script);
}

bool GetBlindingNonceCommand::parse(const QByteArray& data)
{
    Q_ASSERT(data.length() == 32);
    m_nonce = data;
    return true;
}
