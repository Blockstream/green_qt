#include "jadedevice.h"
#include "asset.h"
#include "jadeapi.h"
#include "network.h"

#include <wally_wrapper.h>

#include <QJsonDocument>
#include <QVersionNumber>

namespace {

bool checkDeviceConnected(JadeDevice* device, Task* task)
{
    if (!device || !device->isConnected()) {
        task->abort("Device not connected");
        return false;
    }
    return true;
}

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

const QVersionNumber JADE_MIN_ALLOWED_FW_VERSION{1, 0, 40};

// Jade renders the asset contract into a 768 byte buffer before hashing it, and
// a single oversized entry rejects the whole signing request
constexpr int JADE_MAX_ASSET_CONTRACT_SIZE = 700;

} // namespace

class JadeGetWalletPublicKeyTask : public DeviceGetWalletPublicKeyTask
{
    JadeDevice* const m_device;
public:
    JadeGetWalletPublicKeyTask(Network* network, const QVector<uint32_t>& path, JadeDevice* device)
        : DeviceGetWalletPublicKeyTask(network, path, device)
        , m_device(device)
    {}
    void fetch() override
    {
        if (!checkDeviceConnected(m_device, this)) return;

        m_device->api()->getXpub(m_network->canonicalId(), m_path, this, [this](const QVariantMap& msg) {
            if (msg.contains("error")) {
                setStatus(Status::Failed);
                return;
            }
            Q_ASSERT(msg.contains("result") && msg["result"].typeId() == QMetaType::QString);
            m_public_key = msg["result"].toString().toLocal8Bit();
            setStatus(Status::Finished);
        });
    }
};

class JadeSignMessageTask : public DeviceSignMessageTask
{
    JadeDevice* const m_device;
    const QString m_message;
    const QVector<uint32_t> m_path;
    const QByteArray m_ae_host_commitment;
    const QByteArray m_ae_host_entropy;
    QByteArray m_signature;
    QByteArray m_signer_commitment;
public:
    JadeSignMessageTask(const QString& message, const QVector<uint32_t>& path, const QByteArray& ae_host_commitment, const QByteArray& ae_host_entropy, JadeDevice* device)
        : DeviceSignMessageTask(device)
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
    void update() override
    {
        if (m_status != Status::Ready) return;
        setStatus(Status::Active);

        if (!checkDeviceConnected(m_device, this)) return;

        m_device->api()->signMessage(m_path, m_message, m_ae_host_commitment, m_ae_host_entropy, this, [this](const QVariantMap& result) {
            if (result.contains("error")) {
                qDebug() << "JadeSignMessageTask" << result;
                setStatus(Status::Failed);
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
            setStatus(Status::Finished);
        });
    }
};

#include "util.h"

class JadeSignTransactionTask : public DeviceSignTransactionTask
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
    JadeSignTransactionTask(Network* network, const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions, JadeDevice* device)
        : DeviceSignTransactionTask(device)
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

    void update() override
    {
        if (m_status != Status::Ready) return;
        setStatus(Status::Active);

        QVariantList inputs;
        QVariantList change;

        for (const auto value : m_signing_inputs) {
            const auto input = value.toObject();
            const bool is_witness = IsSegwitAddressType(input.value("address_type").toString());
            const auto script = ParseByteArray(input.value("prevout_script"));
            const auto ae_host_commitment = ParseByteArray(input.value("ae_host_commitment"));
            const auto ae_host_entropy = ParseByteArray(input.value("ae_host_entropy"));

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

        if (!checkDeviceConnected(m_device, this)) return;

        m_device->api()->signTx(m_network->canonicalId(), m_transaction, inputs, change, this, [this](const QVariantMap& result) {
            if (result.contains("result")) {
                for (const auto& s : result["result"].toMap()["signatures"].toList()) {
                    m_signatures.append(s.toByteArray());
                }
                for (const auto& c : result["result"].toMap()["signer_commitments"].toList()) {
                    m_signer_commitments.append(c.toByteArray());
                }
                setStatus(Status::Finished);
            } else {
                setStatus(Status::Failed);
            }
        });
    }
};

class JadeGetBlindingKeyTask : public DeviceGetBlindingKeyTask
{
    JadeDevice* const m_device;
    const QString m_script;
    QByteArray m_public_key;
public:
    JadeGetBlindingKeyTask(const QString& script, JadeDevice* device)
        : DeviceGetBlindingKeyTask(device)
        , m_device(device)
        , m_script(script)
    {
    }
    QByteArray publicKey() const override
    {
        return m_public_key;
    }
    void update() override
    {
        if (m_status != Status::Ready) return;
        setStatus(Status::Active);

        if (!checkDeviceConnected(m_device, this)) return;

        // TODO: the following QByteArray::fromHex should be done in resolver (and refactor ledger task)
        const auto script = QByteArray::fromHex(m_script.toLocal8Bit());
        m_device->api()->getBlindingKey(script, this, [this](const QVariantMap& msg) {
            if (msg.contains("error") || !msg.contains("result") || msg["result"].typeId() != QMetaType::QByteArray) {
                setStatus(Status::Failed);
                return;
            }
            m_public_key = msg["result"].toByteArray();
            setStatus(Status::Finished);
        });
    }
};

class JadeGetBlindingNonceTask : public DeviceGetBlindingNonceTask
{
    JadeDevice* const m_device;
    const QByteArray m_pubkey;
    const QByteArray m_script;
    QByteArray m_nonce;
public:
    JadeGetBlindingNonceTask(const QByteArray& pubkey, const QByteArray& script, JadeDevice* device)
        : DeviceGetBlindingNonceTask(device)
        , m_device(device)
        , m_pubkey(pubkey)
        , m_script(script)
    {
    }
    QByteArray nonce() const override
    {
        return m_nonce;
    }
    void update() override
    {
        if (m_status != Status::Ready) return;
        setStatus(Status::Active);

        if (!checkDeviceConnected(m_device, this)) return;

        m_device->api()->getSharedNonce(m_script, m_pubkey, this, [this](const QVariantMap& msg) {
            if (msg.contains("error") || !msg.contains("result") || msg["result"].typeId() != QMetaType::QByteArray) {
                setStatus(Status::Failed);
                return;
            }
            m_nonce = msg["result"].toByteArray();
            setStatus(Status::Finished);
        });
    }
};

class JadeSignLiquidTransactionTask : public DeviceSignLiquidTransactionTask
{
    Network* const m_network;
    JadeDevice* const m_device;
    const QByteArray m_transaction;
    const QJsonArray m_signing_inputs;
    const QJsonArray m_outputs;
    const QList<Asset*> m_assets;

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
    JadeSignLiquidTransactionTask(Network* network, const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, const QList<Asset*>& assets, JadeDevice* device)
        : DeviceSignLiquidTransactionTask(device)
        , m_network(network)
        , m_device(device)
        , m_transaction(transaction)
        , m_signing_inputs(signing_inputs)
        , m_outputs(outputs)
        , m_assets(assets)
    {
    }
    QList<QByteArray> signatures() const override { return m_signatures; };
    QList<QByteArray> signerCommitments() const override { return m_signer_commitments; }
    void update() override
    {
        if (m_status != Status::Ready) return;
        setStatus(Status::Active);

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

        const auto policy_asset = m_network->policyAsset();
        QVariantList asset_info;
        for (auto asset : m_assets) {
            // Jade has the policy asset information built in
            if (asset->id() == policy_asset) continue;
            const auto data = asset->data();
            const auto contract = data.value("contract").toObject();
            const auto issuance_prevout = data.value("issuance_prevout").toObject();
            if (contract.isEmpty()) continue;
            if (!issuance_prevout.contains("txid") || !issuance_prevout.contains("vout")) continue;
            if (QJsonDocument(contract).toJson(QJsonDocument::Compact).size() > JADE_MAX_ASSET_CONTRACT_SIZE) continue;
            // The registry entry is passed on as a QJsonObject so that it reaches
            // Jade with its keys in the alphabetical order the asset contract hash
            // is computed over, and with its numbers kept as integers. Jade
            // re-computes the asset id from the contract and the issuance prevout.
            asset_info.append(QVariant::fromValue(QJsonObject{
                { "asset_id", asset->id() },
                { "contract", contract },
                { "issuance_prevout", QJsonObject{
                    { "txid", issuance_prevout.value("txid") },
                    { "vout", issuance_prevout.value("vout") },
                }},
            }));
        }

        progress()->setIndeterminate(false);
        progress()->setTo(m_outputs.size() + 1 + 1 + m_inputs.size());

        if (!checkDeviceConnected(m_device, this)) return;

        m_device->api()->signLiquidTx(m_network->canonicalId(), m_transaction, m_inputs, m_trusted_commitments, m_change, asset_info, this, [this](const QVariantMap& msg) {
            qDebug() << msg;
            if (handleError(msg)) return;
            if (!msg.contains("result")) {
                setStatus(Status::Failed);
                return;
            }
            progress()->incrementValue();
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
            setStatus(Status::Finished);
        });
    }
    bool handleError(const QVariantMap& msg)
    {
        if (!msg.contains("error")) return false;
        Q_ASSERT(msg["error"].typeId() == QMetaType::QVariantMap);
        abort(msg["error"].toMap().value("message").toString());
        return true;
    }
};

JadeGetMasterBlindingKeyTask::JadeGetMasterBlindingKeyTask(JadeDevice* device)
    : DeviceGetMasterBlindingKeyTask(device)
    , m_device(device)
{
}

void JadeGetMasterBlindingKeyTask::update()
{
    if (m_status != Status::Ready) return;
    setStatus(Status::Active);
    request();
}

void JadeGetMasterBlindingKeyTask::request()
{
    if (!checkDeviceConnected(m_device, this)) return;

    m_device->api()->getMasterBlindingKey(m_only_if_silent, this, [=, this](const QVariantMap& msg) {
        if (msg.contains("result")) {
            m_master_blinding_key = msg["result"].toByteArray();
            setStatus(Status::Finished);
            return;
        }
        auto error = msg["error"].toMap();
        if (error["code"] == -32000) { // CBOR_RPC_USER_CANCELLED
            if (m_only_if_silent) {
                m_ask = true;
                emit askChanged();
            } else {
                setStatus(Status::Finished);
            }
            return;
        }
        setStatus(Status::Failed);
    });
}

void JadeGetMasterBlindingKeyTask::confirm()
{
    m_only_if_silent = false;
    request();
}

class JadeGetBlindingFactorsTask : public DeviceGetBlindingFactorsTask
{
    JadeDevice* const m_device;
    QJsonArray m_inputs;
    QJsonArray m_outputs;
    QByteArray m_hash_prevouts;
    QList<QByteArray> m_asset_blinders;
    QList<QByteArray> m_amount_blinders;
public:
    JadeGetBlindingFactorsTask(const QJsonArray& inputs, const QJsonArray& outputs, JadeDevice* device)
        : DeviceGetBlindingFactorsTask(device)
        , m_device(device)
        , m_inputs(inputs)
        , m_outputs(outputs)
    {
    }
    void update() override
    {
        if (m_status != Status::Ready) return;
        setStatus(Status::Active);

        if (!checkDeviceConnected(m_device, this)) return;

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
            setStatus(Status::Finished);
            return;
        }

        const auto output = m_outputs.at(index).toObject();
        if (!output.contains("blinding_key")) {
            m_asset_blinders.append(QByteArray());
            m_amount_blinders.append(QByteArray());
            processOutput(index + 1);
            return;
        }

        auto api = m_device->api();
        if (!api) {
            setStatus(Status::Failed);
            return;
        }
        api->getBlindingFactor(m_hash_prevouts, index, "ASSET", this, [=, this](const QVariantMap& msg) {
            if (msg.contains("error") || !msg.contains("result")) {
                setStatus(Status::Failed);
                return;
            }
            m_asset_blinders.append(msg.value("result").toByteArray());
            QMetaObject::invokeMethod(this, [=, this] {
                auto api = m_device->api();
                if (!api) {
                    setStatus(Status::Failed);
                    return;
                }
                api->getBlindingFactor(m_hash_prevouts, index, "VALUE", this, [=, this](const QVariantMap& msg) {
                    if (msg.contains("error") || !msg.contains("result")) {
                        setStatus(Status::Failed);
                        return;
                    }
                    m_amount_blinders.append(msg.value("result").toByteArray());
                    QMetaObject::invokeMethod(this, [=, this] {
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


class JadeLogoutTask : public DeviceLogoutTask
{
    JadeDevice* const m_device;
public:
    JadeLogoutTask(JadeDevice* device)
        : DeviceLogoutTask(device)
        , m_device(device)
    {
    }
    void update() override
    {
        if (m_status != Status::Ready) return;
        setStatus(Status::Active);

        auto backend = m_device->api();
        if (backend) {
            backend->logout(this, [this](const QVariantMap& msg) {
                setStatus(Status::Finished);
            });
        } else {
            setStatus(Status::Finished);
        }
    }
};

JadeDevice::JadeDevice(QObject* parent)
    : Device(parent)
{
}

JadeAPI* JadeDevice::api() const { return m_api; }
JadeAPI* JadeDevice::usbApi() const { return m_usb_api; }
JadeAPI* JadeDevice::bluetoothApi() const { return m_bluetooth_api; }

void JadeDevice::setBackend(JadeAPI* backend)
{
    if (m_api == backend) return;
    if (m_api) disconnect(m_api, nullptr, this, nullptr);
    m_api = backend;
    if (m_api) {
        connect(m_api, &JadeAPI::onDisconnected, this, [=, this] {
            setConnected(false);
        });
    }
    emit connectionTypeChanged();
    emit detailsChanged();
}

void JadeDevice::setUsbBackend(JadeAPI* backend)
{
    if (m_usb_api == backend) return;
    m_usb_api = backend;
    updateBackend();
}

void JadeDevice::setBluetoothBackend(JadeAPI* backend)
{
    if (m_bluetooth_api == backend) return;
    m_bluetooth_api = backend;
    updateBackend();
}

void JadeDevice::updateBackend()
{
    emit backendsChanged();
    // A new link never takes over the active one, the user picks it instead.
    if (m_api && (m_api == m_usb_api || m_api == m_bluetooth_api)) return;
    if (m_api) {
        setConnectionSelected(false);
        setConnected(false);
    }
    setBackend(m_usb_api ? m_usb_api : m_bluetooth_api);
}

JadeDevice::ConnectionType JadeDevice::connectionType() const
{
    if (!m_api) return NoConnection;
    return m_api == m_bluetooth_api ? Bluetooth : USB;
}

void JadeDevice::selectConnection(ConnectionType type)
{
    const auto backend = type == USB ? m_usb_api : type == Bluetooth ? m_bluetooth_api : nullptr;
    if (!backend) return;
    setBackend(backend);
    setConnectionSelected(true);
}

void JadeDevice::setConnectionSelected(bool connection_selected)
{
    if (m_connection_selected == connection_selected) return;
    m_connection_selected = connection_selected;
    emit connectionSelectedChanged();
}

QJsonObject JadeDevice::details() const
{
    const auto board_type = m_version_info.value("BOARD_TYPE").toString();
    QJsonObject details{{"type", "jade"}, {"version", version()}, {"name", name()}, {"board", board_type}};
    switch (connectionType()) {
    case USB: details.insert("connection", "usb"); break;
    case Bluetooth: details.insert("connection", "bluetooth"); break;
    case NoConnection: break;
    }
    return details;
}

DeviceGetWalletPublicKeyTask *JadeDevice::getWalletPublicKey(Network *network, const QVector<uint32_t>& path)
{
    return new JadeGetWalletPublicKeyTask(network, path, this);
}

DeviceSignMessageTask *JadeDevice::signMessage(const QString &message, const QVector<uint32_t> &path)
{
    Q_UNUSED(message);
    Q_UNUSED(path);
    Q_UNREACHABLE();
}

DeviceSignMessageTask *JadeDevice::signMessage(const QString &message, const QVector<uint32_t> &path, const QByteArray& ae_host_commitment, const QByteArray& ae_host_entropy)
{
    return new JadeSignMessageTask(message, path, ae_host_commitment, ae_host_entropy, this);
}

DeviceSignTransactionTask *JadeDevice::signTransaction(Network* network, const QByteArray &transaction, const QJsonArray &signing_inputs, const QJsonArray &transaction_outputs, const QJsonObject &signing_transactions)
{
    return new JadeSignTransactionTask(network, transaction, signing_inputs, transaction_outputs, signing_transactions, this);
}

DeviceGetBlindingKeyTask *JadeDevice::getBlindingKey(const QString& script)
{
    return new JadeGetBlindingKeyTask(script, this);
}

DeviceGetBlindingNonceTask *JadeDevice::getBlindingNonce(const QByteArray& pubkey, const QByteArray& script)
{
    return new JadeGetBlindingNonceTask(pubkey, script, this);
}

DeviceSignLiquidTransactionTask *JadeDevice::signLiquidTransaction(Network* network, const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, const QList<Asset*>& assets)
{
    return new JadeSignLiquidTransactionTask(network, transaction, signing_inputs, outputs, assets, this);
}

DeviceGetMasterBlindingKeyTask *JadeDevice::getMasterBlindingKey()
{
    return new JadeGetMasterBlindingKeyTask(this);
}

DeviceGetBlindingFactorsTask* JadeDevice::getBlindingFactors(const QJsonArray& inputs, const QJsonArray& outputs)
{
    return new JadeGetBlindingFactorsTask(inputs, outputs, this);
}

DeviceLogoutTask *JadeDevice::logout()
{
    return new JadeLogoutTask(this);
}

void JadeDevice::updateVersionInfo()
{
    if (!api() || !isConnected()) return;
    api()->getVersionInfo(true, this, [this](const QVariantMap& data) {
        if (data.contains("error")) {
            qDebug() << "update version info failed";
            emit error();
            return;
        } else if (data.contains("result")) {
            qDebug() << Q_FUNC_INFO;
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
    setState(JadeDeviceGetState(m_version_info));
    setName(nameForEfusemac(version_info.value("EFUSEMAC").toString()));
    emit nameChanged();
    emit detailsChanged();
}

// Also the name Jade advertises over Bluetooth.
QString JadeDevice::nameForEfusemac(const QString& efusemac)
{
    return QString("Jade %1").arg(efusemac.mid(6));
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

bool JadeDevice::secureBoot() const
{
    return m_version_info.value("JADE_FEATURES").toStringList().contains("SB");
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

void JadeDevice::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged();
}

void JadeDevice::setBluetoothState(BluetoothState state)
{
    if (m_bluetooth_state == state) return;
    m_bluetooth_state = state;
    emit bluetoothStateChanged();
}

void JadeDevice::setBluetoothPin(const QString& pin)
{
    if (m_bluetooth_pin == pin) return;
    m_bluetooth_pin = pin;
    emit bluetoothPinChanged();
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
