#include "jadedevice.h"
#include "jadeapi.h"
#include "network.h"
#include "semver.h"

#include <wally_crypto.h>
#include <wally_elements.h>

class JadeGetWalletPublicKeyActivity : public GetWalletPublicKeyActivity
{
    JadeDevice* const m_device;
public:
    JadeGetWalletPublicKeyActivity(Network* network, const QVector<uint32_t>& path, JadeDevice* device)
        : GetWalletPublicKeyActivity(network, path, device)
        , m_device(device)
    {}
    void fetch() override
    {
        m_device->api()->getXpub(m_network->canonicalId(), m_path, [this](const QVariantMap& msg) {
            if (msg.contains("error")) return fail();
            Q_ASSERT(msg.contains("result") && msg["result"].type() == QVariant::String);
            m_public_key = msg["result"].toString().toLocal8Bit();
            finish();
        });
    }
};

class JadeSignMessageActivity : public SignMessageActivity
{
    JadeDevice* const m_device;
    const QString m_message;
    const QVector<uint32_t> m_path;
    const QByteArray m_ae_host_commitment;
    const QByteArray m_ae_host_entropy;
    QByteArray m_signature;
    QByteArray m_signer_commitment;
public:
    JadeSignMessageActivity(const QString& message, const QVector<uint32_t>& path, const QByteArray& ae_host_commitment, const QByteArray& ae_host_entropy, JadeDevice* device)
        : SignMessageActivity(device)
        , m_device(device)
        , m_message(message)
        , m_path(path)
        , m_ae_host_commitment(ae_host_commitment)
        , m_ae_host_entropy(ae_host_entropy)
    {}
    QByteArray signature() const override
    {
        return m_signature;
    }
    QByteArray signerCommitment() const override
    {
        return m_signer_commitment;
    }
    virtual void exec() override
    {
        m_device->api()->signMessage(m_path, m_message, m_ae_host_commitment, m_ae_host_entropy, [this](const QVariantMap& result) {
            auto sig = QByteArray::fromBase64(result["signature"].toString().toLocal8Bit());
            if (sig.size() == EC_SIGNATURE_RECOVERABLE_LEN) sig = sig.mid(1);
            Q_ASSERT(sig.size() == EC_SIGNATURE_LEN);
            QByteArray xxx(EC_SIGNATURE_DER_MAX_LEN, 0);
            size_t yyy;
            wally_ec_sig_to_der((const unsigned char*) sig.constData(), sig.size(), (unsigned char*) xxx.data(), EC_SIGNATURE_DER_MAX_LEN, &yyy);
            m_signature = QByteArray(xxx.constData(), yyy);
            m_signer_commitment = result["signer_commitment"].toByteArray();
            finish();
        });
    }
};

#include "util.h"

class JadeSignTransactionActivity : public SignTransactionActivity
{
    JadeDevice* const m_device;
    Network* const m_network;
    const QJsonObject m_transaction;
    const QJsonArray m_signing_inputs;
    const QJsonArray m_transaction_outputs;
    const QJsonObject m_signing_transactions;
    QList<QByteArray> m_signatures;
    QList<QByteArray> m_signer_commitments;
public:
    JadeSignTransactionActivity(Network* network, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions, JadeDevice* device)
        : SignTransactionActivity(device)
        , m_device(device)
        , m_network(network)
        , m_transaction(transaction)
        , m_signing_inputs(signing_inputs)
        , m_transaction_outputs(transaction_outputs)
        , m_signing_transactions(signing_transactions)
    {
        Q_ASSERT(!m_signing_transactions.isEmpty());
    }

    QList<QByteArray> signatures() const override { return m_signatures; }
    QList<QByteArray> signerCommitments() const override { return m_signer_commitments; }

    static QVariantList ParsePath(const QJsonValue& value)
    {
        QVariantList path;
        for (const auto p : ::ParsePath(value)) path.append(p);
        return path;
    }

    void exec() override
    {
        const auto txn = ParseByteArray(m_transaction.value("transaction"));
        QVariantList inputs;
        QVariantList change;

        for (const auto value : m_signing_inputs) {
            const auto input = value.toObject();
            const bool sw_input = input.value("address_type") != "p2sh";
            const auto script = ParseByteArray(input.value("prevout_script"));
            const auto ae_host_commitment = ParseByteArray(input.value("ae_host_commitment"));
            const auto ae_host_entropy = ParseByteArray(input.value("ae_host_entropy"));

            if (sw_input && m_signing_inputs.size() == 1) {
                inputs.append(QVariantMap({
                    { "is_witness", true },
                    { "input_tx", QVariant() },
                    { "script", script },
                    { "satoshi", ParseSatoshi(input.value("satoshi")) },
                    { "path", ParsePath(input.value("user_path")) },
                    { "ae_host_commitment", ae_host_commitment },
                    { "ae_host_entropy", ae_host_entropy },
                }));
            } else {
                const auto input_tx = ParseByteArray(m_signing_transactions.value(input.value("txhash").toString()));
                Q_ASSERT(!input_tx.isEmpty());
                inputs.append(QVariantMap({
                    { "is_witness", true },
                    { "input_tx", input_tx },
                    { "script", script },
                    { "satoshi", ParseSatoshi(input.value("satoshi")) },
                    { "path", ParsePath(input.value("user_path")) },
                    { "ae_host_commitment", ae_host_commitment },
                    { "ae_host_entropy", ae_host_entropy },
                }));
            }
        }

        for (const auto& value : m_transaction_outputs) {
            const auto output = value.toObject();
            const bool is_change = output.value("is_change").toBool();
            if (is_change) {
                const auto path = ParsePath(output.value("user_path"));
                const auto recovery_xpub = output.value("recovery_xpub").toString();
                const auto type = output.value("address_type").toString();
                const auto csv_blocks = type == "csv" ? output.value("subtype").toInt() : 0;

                QString variant;
                if (type == "p2pkh") variant = "pkh(k)";
                if (type == "p2wpkh") variant = "wpkh(k)";
                if (type == "p2sh-p2wpkh") variant = "sh(wpkh(k))";
                Q_ASSERT(!variant.isEmpty());

                const QVariantMap data = {
                    { "path", path },
                    { "recovery_xpub", recovery_xpub },
                    { "csv_blocks", csv_blocks },
                    { "variant", variant },
                };
                change.append(data);
            } else {
                change.append(QVariant());
            }
        }

        m_device->api()->signTx(m_network->canonicalId(), txn, inputs, change, [this](const QVariantMap& result) {
            if (result.contains("result")) {
                for (const auto& s : result["result"].toMap()["signatures"].toList()) {
                    m_signatures.append(s.toByteArray());
                }
                for (const auto& c : result["result"].toMap()["signer_commitments"].toList()) {
                    m_signer_commitments.append(c.toByteArray());
                }
                finish();
            } else {
                fail();
            }
        });
    }
};

class JadeGetBlindingKeyActivity : public GetBlindingKeyActivity
{
    JadeDevice* const m_device;
    const QString m_script;
    QByteArray m_public_key;
public:
    JadeGetBlindingKeyActivity(const QString& script, JadeDevice* device)
        : GetBlindingKeyActivity(device)
        , m_device(device)
        , m_script(script)
    {
    }
    QByteArray publicKey() const override
    {
        return m_public_key;
    }
    void exec() override
    {
        // TODO: the following QByteArray::fromHex should be done in resolver (and refactor ledger activity)
        const auto script = QByteArray::fromHex(m_script.toLocal8Bit());
        m_device->api()->getBlindingKey(script, [this](const QVariantMap& msg) {
            Q_ASSERT(msg.contains("result") && msg["result"].type() == QVariant::ByteArray);
            m_public_key = msg["result"].toByteArray();
            finish();
        });
    }
};

class JadeGetBlindingNonceActivity : public GetBlindingNonceActivity
{
    JadeDevice* const m_device;
    const QByteArray m_pubkey;
    const QByteArray m_script;
    QByteArray m_nonce;
public:
    JadeGetBlindingNonceActivity(const QByteArray& pubkey, const QByteArray& script, JadeDevice* device)
        : GetBlindingNonceActivity(device)
        , m_device(device)
        , m_pubkey(pubkey)
        , m_script(script)
    {
    }
    QByteArray nonce() const override
    {
        return m_nonce;
    }
    void exec() override
    {
        m_device->api()->getSharedNonce(m_script, m_pubkey, [this](const QVariantMap& msg) {
            Q_ASSERT(msg.contains("result") && msg["result"].type() == QVariant::ByteArray);
            m_nonce = msg["result"].toByteArray();
            finish();
        });
    }
};

class JadeSignLiquidTransactionActivity : public SignLiquidTransactionActivity
{
    Network* const m_network;
    JadeDevice* const m_device;
    const QJsonObject m_transaction;
    const QJsonArray m_signing_inputs;
    const QJsonArray m_outputs;

    QVariantList m_inputs;
    QVector<uint64_t> m_values;
    QList<QByteArray> m_abfs;
    QList<QByteArray> m_vbfs;
    QByteArray m_hash_prev_outs;
    int m_last_blinded_index;
    QVariantList m_change;
    QVariantList m_trusted_commitments;
    QByteArray m_last_vbf;

    QList<QByteArray> m_signatures;
    QList<QByteArray> m_signer_commitments;
    QList<QByteArray> m_asset_commitments;
    QList<QByteArray> m_value_commitments;
    QList<QByteArray> m_asset_blinders;
    QList<QByteArray> m_amount_blinders;
private:
    static QVariantList ParsePath(const QJsonValue& value)
    {
        QVariantList path;
        for (const auto p : ::ParsePath(value)) path.append(p);
        return path;
    }
public:
    JadeSignLiquidTransactionActivity(Network* network, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, JadeDevice* device)
        : SignLiquidTransactionActivity(device)
        , m_network(network)
        , m_device(device)
        , m_transaction(transaction)
        , m_signing_inputs(signing_inputs)
        , m_outputs(outputs)
    {
        m_last_blinded_index = m_outputs.size() - 2;
    }
    QList<QByteArray> signatures() const override { return m_signatures; };
    QList<QByteArray> signerCommitments() const override { return m_signer_commitments; }
    QList<QByteArray> assetCommitments() const override { return m_asset_commitments; }
    QList<QByteArray> valueCommitments() const override { return m_value_commitments; }
    QList<QByteArray> assetBlinders() const override { return m_asset_blinders; }
    QList<QByteArray> amountBlinders() const override { return m_amount_blinders; }
    void exec() override
    {
        QByteArray prevouts;
        QDataStream stream_prevouts(&prevouts, QIODevice::WriteOnly);
        stream_prevouts.setByteOrder(QDataStream::LittleEndian);

        for (const auto value : m_signing_inputs) {
            const auto input = value.toObject();
            const auto address_type = input.value("address_type").toString();
            const bool is_segwit = address_type != "p2sh";
            const auto script = ParseByteArray(input.value("prevout_script"));
            const auto value_commitment = ParseByteArray(input.value("commitment"));
            const auto path = ParsePath(input.value("user_path"));
            const auto ae_host_commitment = ParseByteArray(input.value("ae_host_commitment"));
            const auto ae_host_entropy = ParseByteArray(input.value("ae_host_entropy"));
            m_inputs.append(QVariantMap({
                { "is_witness", is_segwit },
                { "script", script },
                { "value_commitment", value_commitment },
                { "path", path },
                { "ae_host_commitment", ae_host_commitment },
                { "ae_host_entropy", ae_host_entropy }
            }));

            m_values.append(ParseSatoshi(input.value("satoshi")));
            m_abfs.append(ReverseByteArray(ParseByteArray(input.value("assetblinder"))));
            m_vbfs.append(ReverseByteArray(ParseByteArray(input.value("amountblinder"))));

            const auto txid = ReverseByteArray(ParseByteArray(input.value("txhash")));
            stream_prevouts.writeRawData(txid.constData(), txid.size());
            stream_prevouts << input.value("pt_idx").toInt();
        }

        QByteArray out(SHA256_LEN, 0);
        wally_sha256d((const unsigned char*) prevouts.constData(), prevouts.size(), (unsigned char*) out.data(), out.size());
        m_hash_prev_outs = out;

        for (const auto value : m_outputs) {
            const auto output = value.toObject();
            const auto satoshi = ParseSatoshi(output.value("satoshi"));
            if (!output.value("is_fee").toBool()) {
                m_values.append(satoshi);
            }
            if (output.value("is_change").toBool()) {
                const auto path = ParsePath(output.value("user_path"));
                const auto recovery_xpub = output.value("recovery_xpub").toString();
                const auto csv_blocks = output.value("address_type").toString() == "csv" ? output.value("subtype").toInt() : 0;
                const QVariantMap data = {
                    { "path", path },
                    { "recovery_xpub", recovery_xpub },
                    { "csv_blocks", csv_blocks },
                };
                m_change.append(data);
            } else {
                m_change.append(QVariant());
            }
        }

        progress()->setIndeterminate(false);
        progress()->setTo(m_outputs.size() + 1 + 1 + m_inputs.size());

        nextTrustedCommitment(0);
    }
    void nextTrustedCommitment(int index) {

        const auto output = m_outputs.at(index).toObject();

        if (output.value("is_fee").toBool()) {
            return nextTrustedCommitment(index + 1);
        }

        if (index == m_last_blinded_index && m_last_vbf.isEmpty()) {
            m_device->api()->getBlindingFactor(m_hash_prev_outs, index, "ASSET", [this, index](const QVariantMap& msg) {
                if (handleError(msg)) return;
                progress()->incrementValue();

                Q_ASSERT(msg.contains("result") && msg["result"].type() == QVariant::ByteArray);
                m_abfs.append(msg["result"].toByteArray());
                const auto abf = m_abfs.join();
                const auto vbf = m_vbfs.join();

                QByteArray out(BLINDING_FACTOR_LEN, 0);
                int res = wally_asset_final_vbf(
                            m_values.constData(), m_values.size(),
                            m_inputs.size(),
                            (const unsigned char*) abf.constData(), abf.size(),
                            (const unsigned char*) vbf.constData(), vbf.size(),
                            (unsigned char*) out.data(), out.size());
                Q_ASSERT(res == WALLY_OK);

                m_last_vbf = out;
                m_vbfs.append(m_last_vbf);

                nextTrustedCommitment(index);
            });
            return;
        }

        const auto asset_id = ParseByteArray(output.value("asset_id"));
        const auto blinding_key = ParseByteArray(output.value("blinding_key"));
        const auto satoshi = ParseSatoshi(output.value("satoshi"));

        m_device->api()->getCommitments(asset_id, satoshi, m_hash_prev_outs, index, m_last_vbf, [this, index, blinding_key](const QVariantMap& msg) {
            if (handleError(msg)) return;
            progress()->incrementValue();

            Q_ASSERT(msg.contains("result") && msg["result"].type() == QVariant::Map);
            auto commitment = msg["result"].toMap();

            m_abfs.append(commitment.value("abf").toByteArray());
            m_vbfs.append(commitment.value("vbf").toByteArray());

            commitment["blinding_key"] = blinding_key;
            m_trusted_commitments.append(commitment);

            if (index == m_last_blinded_index) {
                m_trusted_commitments.append(QVariantMap());
                sign();
            } else {
                nextTrustedCommitment(index + 1);
            }
        });
    }
    void sign()
    {
        const auto tx = ParseByteArray(m_transaction.value("transaction"));
        m_device->api()->signLiquidTx(m_network->canonicalId(), tx, m_inputs, m_trusted_commitments, m_change, [this](const QVariantMap& msg) {
            if (handleError(msg)) return;
            progress()->incrementValue();
            Q_ASSERT(msg.contains("result"));
            for (const auto& signature : msg["result"].toMap()["signatures"].toList()) {
                m_signatures.append(signature.toByteArray());
            }
            for (const auto& signer_commitment : msg["result"].toMap()["signer_commitments"].toList()) {
                m_signer_commitments.append(signer_commitment.toByteArray());
            }
            for (const auto& value : m_trusted_commitments) {
                const auto commitment = value.toMap();
                if (commitment.isEmpty() || commitment["asset_id"].isNull()) {
                    m_asset_commitments.append(QByteArray());
                    m_value_commitments.append(QByteArray());
                    m_asset_blinders.append(QByteArray());
                    m_amount_blinders.append(QByteArray());
                } else {
                    m_asset_commitments.append(commitment["asset_generator"].toByteArray());
                    m_value_commitments.append(commitment["value_commitment"].toByteArray());
                    m_asset_blinders.append(commitment["abf"].toByteArray());
                    m_amount_blinders.append(commitment["vbf"].toByteArray());
                }
            }
            finish();
        });
    }
    bool handleError(const QVariantMap& msg)
    {
        if (!msg.contains("error")) return false;
        Q_ASSERT(msg["error"].type() == QVariant::Map);
        setMessage(QJsonObject::fromVariantMap(msg["error"].toMap()));
        fail();
        return true;
    }
};

class JadeGetMasterBlindingKeyActivity : public GetMasterBlindingKeyActivity
{
    JadeDevice* const m_device;
    QByteArray m_master_blinding_key;
public:
    JadeGetMasterBlindingKeyActivity(JadeDevice* device)
        : GetMasterBlindingKeyActivity(device)
        , m_device(device)
    {
    }
    QByteArray masterBlindingKey() const override
    {
        return m_master_blinding_key;
    }
    void exec() override
    {
        m_device->api()->getMasterBlindingKey([this](const QVariantMap& msg) {
            if (msg.contains("result")) {
                m_master_blinding_key = msg["result"].toByteArray();
                finish();
                return;
            }
            auto error = msg["error"].toMap();
            if (error["code"] == -32000) { // CBOR_RPC_USER_CANCELLED
                finish();
                return;
            }
            fail();
        });
    }
};

JadeDevice::JadeDevice(JadeAPI* api, const QString& system_location, QObject* parent)
    : Device(parent)
    , m_api(api)
    , m_system_location(system_location)
{
}

QJsonObject JadeDevice::details() const
{
    return {{"type", "jade"}, {"version", version()}, {"name", name()}};
}

GetWalletPublicKeyActivity *JadeDevice::getWalletPublicKey(Network *network, const QVector<uint32_t>& path)
{
    return new JadeGetWalletPublicKeyActivity(network, path, this);
}

SignMessageActivity *JadeDevice::signMessage(const QString &message, const QVector<uint32_t> &path)
{
    Q_UNUSED(message);
    Q_UNUSED(path);
    Q_UNREACHABLE();
}

SignMessageActivity *JadeDevice::signMessage(const QString &message, const QVector<uint32_t> &path, const QByteArray& ae_host_commitment, const QByteArray& ae_host_entropy)
{
    return new JadeSignMessageActivity(message, path, ae_host_commitment, ae_host_entropy, this);
}

SignTransactionActivity *JadeDevice::signTransaction(Network* network, const QJsonObject &transaction, const QJsonArray &signing_inputs, const QJsonArray &transaction_outputs, const QJsonObject &signing_transactions)
{
    return new JadeSignTransactionActivity(network, transaction, signing_inputs, transaction_outputs, signing_transactions, this);
}

GetBlindingKeyActivity *JadeDevice::getBlindingKey(const QString& script)
{
    return new JadeGetBlindingKeyActivity(script, this);
}

GetBlindingNonceActivity *JadeDevice::getBlindingNonce(const QByteArray& pubkey, const QByteArray& script)
{
    return new JadeGetBlindingNonceActivity(pubkey, script, this);
}

SignLiquidTransactionActivity *JadeDevice::signLiquidTransaction(Network* network, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs)
{
    return new JadeSignLiquidTransactionActivity(network, transaction, signing_inputs, outputs, this);
}

GetMasterBlindingKeyActivity *JadeDevice::getMasterBlindingKey()
{
    return new JadeGetMasterBlindingKeyActivity(this);
}

void JadeDevice::ping()
{
    if (m_api->isIdle() && !m_api->isBusy()) {
        updateVersionInfo();
    }
}

void JadeDevice::updateVersionInfo()
{
    api()->getVersionInfo([this](const QVariantMap& data) {
        if (data.contains("error")) {
            qDebug() << "update version info failed";
            emit error();
            return;
        }
        setVersionInfo(data.value("result").toMap());
    });
}

void JadeDevice::setVersionInfo(const QVariantMap& version_info)
{
    if (m_version_info == version_info) return;
    m_version_info = version_info;
    emit versionInfoChanged();
    m_name = QString("Jade %1").arg(version_info.value("EFUSEMAC").toString().mid(6));
    emit nameChanged();
    emit detailsChanged();
}

QVariantMap JadeDevice::versionInfo() const
{
    return m_version_info;
}

namespace {
const SemVer JADE_MIN_ALLOWED_FW_VERSION{0, 1, 24};
}

bool JadeDevice::updateRequired() const
{
    return SemVer::parse(version()) < JADE_MIN_ALLOWED_FW_VERSION;
}

QString JadeDevice::version() const
{
    return m_version_info.value("JADE_VERSION").toString();
}

JadeDevice::State JadeDevice::state() const
{
    // 1. Ready - has keys already associated with a message source
    //    - READY
    // 2. Temporary keys - has temporary keys in memory, but not yet connected to app
    //    - TEMP
    // 3. Unsaved keys - has proper keys in memory, but not yet saved with a PIN
    //    - UNSAVED
    // 4. Locked - has persisted/encrypted keys, but no keys in memory
    //    - LOCKED
    // 5. Uninitialised - has no persisted/encrypted keys and no keys in memory
    //    - UNINT
    const auto state = m_version_info.value(QStringLiteral("JADE_STATE")).toString();
    if (state == "READY") return StateReady;
    if (state == "TEMP") return StateTemporary;
    if (state == "UNSAVED") return StateUnsaved;
    if (state == "LOCKED") return StateLocked;
    if (state == "UNINT") return StateUninitialized;
    Q_UNREACHABLE();
}
