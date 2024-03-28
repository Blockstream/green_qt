#include "jadedevice.h"
#include "jadeapi.h"
#include "network.h"

#include <wally_wrapper.h>

#include <QVersionNumber>

namespace {
const QVersionNumber JADE_MIN_ALLOWED_FW_VERSION{1, 0, 26};

bool IsSegwitAddressType(const QString& addr_type)
{
    if (addr_type == "csv" || addr_type == "p2wsh" || addr_type == "p2wpkh" || addr_type == "p2sh-p2wpkh") {
        return true;
    }
    if (addr_type == "p2sh" || addr_type == "p2pkh") {
        return false;
    }
    Q_UNREACHABLE();
}
} // namespace

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
            Q_ASSERT(msg.contains("result") && msg["result"].typeId() == QMetaType::QString);
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
            if (result.contains("error")) {
                qDebug() << "JadeSignMessageActivity" << result;
                fail();
                return;
            }

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
    const QByteArray m_transaction;
    const QJsonArray m_signing_inputs;
    const QJsonArray m_transaction_outputs;
    const QJsonObject m_signing_transactions;
    QList<QByteArray> m_signatures;
    QList<QByteArray> m_signer_commitments;
public:
    JadeSignTransactionActivity(Network* network, const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions, JadeDevice* device)
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
        QVariantList inputs;
        QVariantList change;

        for (const auto value : m_signing_inputs) {
            const auto input = value.toObject();
            const bool is_witness = IsSegwitAddressType(input.value("address_type").toString());
            const auto script = ParseByteArray(input.value("prevout_script"));
            const auto ae_host_commitment = ParseByteArray(input.value("ae_host_commitment"));
            const auto ae_host_entropy = ParseByteArray(input.value("ae_host_entropy"));

            if (is_witness && m_signing_inputs.size() == 1) {
                inputs.append(QVariantMap({
                    { "is_witness", is_witness },
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
                    { "is_witness", is_witness },
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

        m_device->api()->signTx(m_network->canonicalId(), m_transaction, inputs, change, [this](const QVariantMap& result) {
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
            Q_ASSERT(msg.contains("result") && msg["result"].typeId() == QMetaType::QByteArray);
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
            Q_ASSERT(msg.contains("result") && msg["result"].typeId() == QMetaType::QByteArray);
            m_nonce = msg["result"].toByteArray();
            finish();
        });
    }
};

class JadeSignLiquidTransactionActivity : public SignLiquidTransactionActivity
{
    Network* const m_network;
    JadeDevice* const m_device;
    const QByteArray m_transaction;
    const QJsonArray m_signing_inputs;
    const QJsonArray m_outputs;

    QVariantList m_inputs;
    QVariantList m_change;
    QVariantList m_trusted_commitments;

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
    JadeSignLiquidTransactionActivity(Network* network, const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, JadeDevice* device)
        : SignLiquidTransactionActivity(device)
        , m_network(network)
        , m_device(device)
        , m_transaction(transaction)
        , m_signing_inputs(signing_inputs)
        , m_outputs(outputs)
    {
    }
    QList<QByteArray> signatures() const override { return m_signatures; };
    QList<QByteArray> signerCommitments() const override { return m_signer_commitments; }
    void exec() override
    {
        for (const auto value : m_signing_inputs) {
            const auto input = value.toObject();
            const auto address_type = input.value("address_type").toString();
            const bool is_witness = IsSegwitAddressType(address_type);
            const auto script = ParseByteArray(input.value("prevout_script"));
            const auto value_commitment = ParseByteArray(input.value("commitment"));
            const auto path = ParsePath(input.value("user_path"));
            const auto ae_host_commitment = ParseByteArray(input.value("ae_host_commitment"));
            const auto ae_host_entropy = ParseByteArray(input.value("ae_host_entropy"));
            m_inputs.append(QVariantMap{
                { "is_witness", is_witness },
                { "script", script },
                { "value_commitment", value_commitment },
                { "path", path },
                { "ae_host_commitment", ae_host_commitment },
                { "ae_host_entropy", ae_host_entropy }
            });
        }

        for (int i = 0; i < m_outputs.size(); i++) {
            const auto output = m_outputs.at(i).toObject();
            if (output.contains("blinding_key")) {
                m_trusted_commitments.append(QVariantMap{
                    { "asset_id", ParseByteArray(output.value("asset_id")) },
                    { "value", ParseSatoshi(output.value("satoshi")) },
                    { "blinding_key", ParseByteArray(output.value("blinding_key")) },
                    { "abf", ReverseByteArray(ParseByteArray(output.value("assetblinder"))) },
                    { "vbf", ReverseByteArray(ParseByteArray(output.value("amountblinder"))) },
                });
            } else {
                m_trusted_commitments.append(QVariant::fromValue(nullptr));
            }

            if (output.value("is_change").toBool()) {
                const auto path = ParsePath(output.value("user_path"));
                const auto recovery_xpub = output.value("recovery_xpub").toString();
                const auto type = output.value("address_type").toString();
                const auto csv_blocks = type == "csv" ? output.value("subtype").toInt() : 0;

                QString variant;
                if (type == "p2pkh") variant = "pkh(k)";
                if (type == "p2wpkh") variant = "wpkh(k)";
                if (type == "p2sh-p2wpkh") variant = "sh(wpkh(k))";

                m_change.append(QVariantMap{
                    { "path", path },
                    { "recovery_xpub", recovery_xpub },
                    { "csv_blocks", csv_blocks },
                    { "variant", variant },
                });
            } else {
                m_change.append(QVariant::fromValue(nullptr));
            }
        }

        progress()->setIndeterminate(false);
        progress()->setTo(m_outputs.size() + 1 + 1 + m_inputs.size());

        m_device->api()->signLiquidTx(m_network->canonicalId(), m_transaction, m_inputs, m_trusted_commitments, m_change, [this](const QVariantMap& msg) {
            qDebug() << msg;
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
        Q_ASSERT(msg["error"].typeId() == QMetaType::QVariantMap);
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
        m_device->api()->getMasterBlindingKey(/* only_if_silent = */ false, [this](const QVariantMap& msg) {
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

class JadeGetBlindingFactorsActivity : public GetBlindingFactorsActivity
{
    JadeDevice* const m_device;
    QJsonArray m_inputs;
    QJsonArray m_outputs;
    QByteArray m_hash_prevouts;
    QList<QByteArray> m_asset_blinders;
    QList<QByteArray> m_amount_blinders;
public:
    JadeGetBlindingFactorsActivity(const QJsonArray& inputs, const QJsonArray& outputs, JadeDevice* device)
        : GetBlindingFactorsActivity(device)
        , m_device(device)
        , m_inputs(inputs)
        , m_outputs(outputs)
    {
    }
    void exec() override
    {
        QByteArray txhashes;
        QList<uint32_t> utxo_indices;
        for (auto value : m_inputs) {
            const auto input = value.toObject();
            const auto txhash = ParseByteArray(input.value("txhash"));
            const auto pt_idx = input.value("pt_idx").toInt();

            txhashes.append(txhash);
            utxo_indices.append(pt_idx);
        }

        unsigned char hash_prevouts_bytes[SHA256_LEN];
        auto rc = wally_get_hash_prevouts(
            (const unsigned char *) txhashes.constData(), txhashes.size(),
            utxo_indices.constData(), m_inputs.size(),
            hash_prevouts_bytes, SHA256_LEN);
        Q_ASSERT(rc == WALLY_OK);
        m_hash_prevouts = QByteArray((const char*) hash_prevouts_bytes, SHA256_LEN);

        processOutput(0);
    }
    void processOutput(qsizetype index)
    {
        if (index == m_outputs.size()) {
            finish();
            return;
        }

        const auto output = m_outputs.at(index).toObject();
        if (!output.contains("blinding_key")) {
            m_asset_blinders.append(QByteArray());
            m_amount_blinders.append(QByteArray());
            processOutput(index + 1);
            return;
        }

        m_device->api()->getBlindingFactor(m_hash_prevouts, index, "ASSET", [=](const QVariantMap& msg) {
            m_asset_blinders.append(msg.value("result").toByteArray());
            QMetaObject::invokeMethod(this, [=] {
                m_device->api()->getBlindingFactor(m_hash_prevouts, index, "VALUE", [=](const QVariantMap& msg) {
                    m_amount_blinders.append(msg.value("result").toByteArray());
                    QMetaObject::invokeMethod(this, [=] {
                        processOutput(index + 1);
                    }, Qt::QueuedConnection);
                });
            }, Qt::QueuedConnection);
        });
    }
    QList<QByteArray> assetBlinders() const override
    {
        return m_asset_blinders;
    }
    QList<QByteArray> amountBlinders() const override
    {
        return m_amount_blinders;
    }
};


class JadeLogoutActivity : public LogoutActivity
{
    JadeDevice* const m_device;
public:
    JadeLogoutActivity(JadeDevice* device)
        : LogoutActivity(device)
        , m_device(device)
    {
    }
    void exec() override
    {
        auto backend = m_device->api();
        if (backend) {
            backend->logout([this](const QVariantMap& msg) {
                finish();
            });
        } else {
            finish();
        }
    }
};

JadeDevice::JadeDevice(QObject* parent)
    : Device(parent)
{
}

void JadeDevice::setBackend(JadeAPI* backend)
{
    m_api = backend;
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

SignTransactionActivity *JadeDevice::signTransaction(Network* network, const QByteArray &transaction, const QJsonArray &signing_inputs, const QJsonArray &transaction_outputs, const QJsonObject &signing_transactions)
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

SignLiquidTransactionActivity *JadeDevice::signLiquidTransaction(Network* network, const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs)
{
    return new JadeSignLiquidTransactionActivity(network, transaction, signing_inputs, outputs, this);
}

GetMasterBlindingKeyActivity *JadeDevice::getMasterBlindingKey()
{
    return new JadeGetMasterBlindingKeyActivity(this);
}

GetBlindingFactorsActivity* JadeDevice::getBlindingFactors(const QJsonArray& inputs, const QJsonArray& outputs)
{
    return new JadeGetBlindingFactorsActivity(inputs, outputs, this);
}

LogoutActivity *JadeDevice::logout()
{
    return new JadeLogoutActivity(this);
}

void JadeDevice::updateVersionInfo()
{
    api()->getVersionInfo(true, [this](const QVariantMap& data) {
        if (data.contains("error")) {
            qDebug() << "update version info failed";
            emit error();
            return;
        } else if (data.contains("result")) {
            setVersionInfo(data.value("result").toMap());
        }
    });
}

JadeDevice::State JadeDeviceGetState(const QVariantMap& version_info)
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
    if (version_info.contains("JADE_STATE")) {
        const auto state = version_info.value(QStringLiteral("JADE_STATE")).toString();
        if (state == "READY") return JadeDevice::StateReady;
        if (state == "TEMP") return JadeDevice::StateTemporary;
        if (state == "UNSAVED") return JadeDevice::StateUnsaved;
        if (state == "LOCKED") return JadeDevice::StateLocked;
        if (state == "UNINIT") return JadeDevice::StateUninitialized;
    }
    if (version_info.contains("JADE_HAS_PIN")) {
        const bool has_pin = version_info.value("JADE_HAS_PIN").toBool();
        if (!has_pin) return JadeDevice::StateUninitialized;
    }
    return JadeDevice::StateLocked;
}

void JadeDevice::setVersionInfo(const QVariantMap& version_info)
{
    if (m_version_info == version_info) return;
    m_version_info = version_info;
    emit versionInfoChanged();
    updateState();
    m_name = QString("Jade %1").arg(version_info.value("EFUSEMAC").toString().mid(6));
    emit nameChanged();
    emit detailsChanged();
}

QVariantMap JadeDevice::versionInfo() const
{
    return m_version_info;
}

QVersionNumber JadeDevice::minimumRequiredVersion() const
{
    return JADE_MIN_ALLOWED_FW_VERSION;
}

bool JadeDevice::updateRequired() const
{
    return QVersionNumber::fromString(version()) < JADE_MIN_ALLOWED_FW_VERSION;
}

QString JadeDevice::version() const
{
    return m_version_info.value("JADE_VERSION").toString();
}

void JadeDevice::setSystemLocation(const QString& system_location)
{
    if (m_system_location == system_location) return;
    m_system_location = system_location;
    emit systemLocationChanged();
}

void JadeDevice::setState(JadeDevice::State state)
{
    if (m_state == state) return;
    m_state = state;
    emit stateChanged();
    if (m_state != StateReady) {
        clearSession();
    }
}

void JadeDevice::updateState()
{
    const auto state = JadeDeviceGetState(m_version_info);
    setState(state);
}

void JadeDevice::setStatus(Status status)
{
    if (m_status == status) return;
    m_status = status;
    emit statusChanged();
}

void JadeDevice::setUnlocking(bool unlocking)
{
    if (m_unlocking == unlocking) return;
    m_unlocking = unlocking;
    emit unlockingChanged();
}

bool JadeDevice::versionGreaterOrEqualThan(const QString& other)
{
    return QVersionNumber::fromString(version()) >= QVersionNumber::fromString(other);
}

bool JadeDevice::supportsNetwork(Network *network)
{
    const auto networks = m_version_info.value("JADE_NETWORKS").toString();
    if (networks == "TEST") return !network->isMainnet();
    return true;

}
