#include "device.h"
#include "handler.h"
#include "network.h"
#include "resolver.h"
#include "util.h"
#include "wallet.h"

#include <wally_crypto.h>

Resolver::Resolver(Handler *handler, const QJsonObject& result)
    : QObject(handler)
    , m_handler(handler)
    , m_result(result)
{
}

Wallet *Resolver::wallet() const
{
    return m_handler->wallet();
}

Network *Resolver::network() const
{
    return wallet()->network();
}

void Resolver::setFailed(bool failed)
{
    if (m_failed == failed) return;
    m_failed = failed;
    emit failedChanged(m_failed);
    if (m_failed) emit m_handler->error();
}

TwoFactorResolver::TwoFactorResolver(Handler* handler, const QJsonObject& result)
    : Resolver(handler, result)
    , m_method(result.value("method").toString())
    , m_attempts_remaining(result.value("attempts_remaining").toInt())
{
}

void TwoFactorResolver::resolve()
{
    m_handler->resolve(m_code.toLocal8Bit());
}

void TwoFactorResolver::retry(const QJsonObject& result)
{
    m_attempts_remaining = result.value("attempts_remaining").toInt();
    emit attemptsRemainingChanged();
    emit invalidCode();
}

void TwoFactorResolver::setCode(const QString &code)
{
    if (m_code == code) return;
    m_code = code;
    emit codeChanged(m_code);
}

DeviceResolver::DeviceResolver(Handler* handler, const QJsonObject& result)
    : Resolver(handler, result)
    , m_required_data(result.value("required_data").toObject())
{
    Q_ASSERT(m_required_data.contains("device"));
}

Device *DeviceResolver::device() const
{
    return wallet()->m_device;
}

GetXPubsResolver::GetXPubsResolver(Handler* handler, const QJsonObject& result)
    : DeviceResolver(handler, result)
{
    for (auto path : m_required_data.value("paths").toArray()) {
        QVector<uint32_t> p;
        for (auto x : path.toArray()) {
            p.append(x.toDouble());
        }
        m_paths.append(p);
    }
}

void GetXPubsResolver::resolve()
{
    emit progress(m_xpubs.size(), m_xpubs.size() + m_paths.size());
    if (m_paths.empty()) return emit m_handler->resolve({{ "xpubs", m_xpubs }});

    auto path = m_paths.takeFirst();
    auto command = device()->getWalletPublicKey(wallet()->network(), path);
    connect(command, &GetWalletPublicKeyActivity::finished, this, [this, command] {
        command->deleteLater();
        m_xpubs.append(command->result());
        resolve();
    });
    connect(command, &GetWalletPublicKeyActivity::failed, this, [this, command] {
        command->deleteLater();
        setFailed(true);
    });
    command->exec();
}

SignTransactionResolver::SignTransactionResolver(Handler* handler, const QJsonObject& result)
    : DeviceResolver(handler, result)
{
}

void SignTransactionResolver::resolve()
{
    Q_ASSERT(m_required_data.value("action").toString() == "sign_tx");

    auto transaction = m_required_data.value("transaction").toObject();
    auto signing_inputs = m_required_data.value("signing_inputs").toArray();
    auto outputs = m_required_data.value("transaction_outputs").toArray();
    uint32_t version = transaction.value("transaction_version").toInt();
    uint32_t locktime = transaction.value("transaction_locktime").toInt();

    auto command = device()->signTransaction(version, transaction, signing_inputs, outputs, locktime);
    connect(command, &SignTransactionActivity::finished, [this, command] {
        command->deleteLater();
        for (const auto& signature : command->result()) {
            m_signatures.append(QString::fromLocal8Bit(signature.toHex()));
        }
        m_handler->resolve({{ "signatures", m_signatures }});
    });
    connect(command, &SignTransactionActivity::failed, [this, command] {
        command->deleteLater();
        m_handler->error();
    });
    command->exec();
}

BlindingKeysResolver::BlindingKeysResolver(Handler* handler, const QJsonObject& result)
    : DeviceResolver(handler, result)
{
    const auto transaction = m_required_data.value("transaction").toObject();
    if (transaction.isEmpty() || !transaction.contains("change_address")) return;

    const auto change_address = transaction.value("change_address").toObject();
    for (auto i = change_address.begin(); i != change_address.end(); ++i) {
        const auto key = i.key();
        const auto address = i.value().toObject();
        const auto script = address.value("blinding_script_hash").toString();
        m_keys.append(key);
        m_scripts.append(script);
    }
}

void BlindingKeysResolver::resolve()
{
    Q_ASSERT(m_keys.size() == m_scripts.size());

    if (m_scripts.empty()) return m_handler->resolve({{ "blinding_keys", m_blinding_keys }});

    const auto key = m_keys.takeFirst();
    const auto script = m_scripts.takeFirst();
    auto activity = device()->getBlindingKey(script);
    connect(activity, &Activity::finished, [this, activity, key] {
        activity->deleteLater();
        m_blinding_keys.insert(key, QString::fromLocal8Bit(activity->result().toHex()));
        resolve();
    });
    connect(activity, &Activity::failed, [this, activity] {
        activity->deleteLater();
        m_handler->error();
    });
    activity->exec();
}

BlindingKeyResolver::BlindingKeyResolver(Handler* handler, const QJsonObject& result)
    : DeviceResolver(handler, result)
{
    const auto address = m_required_data.value("address").toObject();
    m_script = address.value("blinding_script_hash").toString();
}

void BlindingKeyResolver::resolve()
{
    auto activity = device()->getBlindingKey(m_script);
    connect(activity, &Activity::finished, [this, activity] {
        activity->deleteLater();
        const auto blinding_key = QString::fromLocal8Bit(activity->result().toHex());
        m_handler->resolve({{ "blinding_key", blinding_key }});
    });
    connect(activity, &Activity::failed, [this, activity] {
        activity->deleteLater();
        m_handler->error();
    });
    activity->exec();
}


BlindingNoncesResolver::BlindingNoncesResolver(Handler* handler, const QJsonObject& result)
    : DeviceResolver(handler, result)
{
    for (const auto blinded_script : m_required_data.value("blinded_scripts").toArray()) {
        m_pubkeys.append(blinded_script.toObject().value("pubkey").toString());
        m_scripts.append(blinded_script.toObject().value("script").toString());
    }
}

void BlindingNoncesResolver::resolve()
{
    Q_ASSERT(m_pubkeys.size() == m_scripts.size());

    if (m_pubkeys.empty()) return m_handler->resolve({{ "nonces", m_nonces }});

    const auto pubkey = QByteArray::fromHex(m_pubkeys.takeFirst().toLocal8Bit());
    const auto script = QByteArray::fromHex(m_scripts.takeFirst().toLocal8Bit());

    QByteArray pubkey_uncompressed = QByteArray(65, 0);
    wally_ec_public_key_decompress(
                (const unsigned char*) pubkey.constData(), pubkey.size(),
                (unsigned char*) pubkey_uncompressed.data(), pubkey_uncompressed.size());

    auto activity = device()->getBlindingNonce(pubkey_uncompressed, script);
    connect(activity, &Activity::finished, [this, activity] {
        activity->deleteLater();
        m_nonces.append(QString::fromLocal8Bit(activity->result().toHex()));
        resolve();
    });
    connect(activity, &Activity::failed, [this, activity] {
        activity->deleteLater();
        m_handler->error();
    });
    activity->exec();
}

SignLiquidTransactionResolver::SignLiquidTransactionResolver(Handler* handler, const QJsonObject& result)
    : DeviceResolver(handler, result)
{
    Q_ASSERT(network()->isLiquid());
    Q_ASSERT(m_required_data.value("action").toString() == "sign_tx");

}

void SignLiquidTransactionResolver::resolve()
{
    const auto transaction = m_required_data.value("transaction").toObject();
    const auto signing_inputs = m_required_data.value("signing_inputs").toArray();
    const auto outputs = m_required_data.value("transaction_outputs").toArray();
    uint32_t version = transaction.value("transaction_version").toDouble();

    auto activity = device()->signLiquidTransaction(version, transaction, signing_inputs, outputs);

//    connect(command, &SignLiquidTransactionCommand::progressChanged, [this](int count, int total) {
//       m_progress = qreal(count) / qreal(total);
//       emit progressChanged(m_progress);
//    });
//    connect(command, &SignLiquidTransactionCommand::message, [this](const QJsonObject& message) {
//        if (m_message == message) return;
//        m_message = message;
//        emit messageChanged(m_message);
//    });
    connect(activity, &Activity::finished, [this, activity] {
        activity->deleteLater();
        QJsonArray signatures;
        QJsonArray asset_commitments;
        QJsonArray value_commitments;
        QJsonArray abfs;
        QJsonArray vbfs;
        for (const auto& signature : activity->signatures()) {
            signatures.append(QString::fromLocal8Bit(signature.toHex()));
        }
        for (const auto& commitment : activity->assetCommitments()) {
            if (commitment.isEmpty()) {
                asset_commitments.append(QJsonValue::Null);
            } else {
                asset_commitments.append(QString::fromLocal8Bit(commitment.toHex()));
            }
        }
        for (const auto& commitment : activity->valueCommitments()) {
            if (commitment.isEmpty()) {
                value_commitments.append(QJsonValue::Null);
            } else {
                value_commitments.append(QString::fromLocal8Bit(commitment.toHex()));
            }
        }
        for (const auto& abf : activity->assetBlinders()) {
            if (abf.isEmpty()) {
                abfs.append(QJsonValue::Null);
            } else {
                abfs.append(QString::fromLocal8Bit(ReverseByteArray(abf).toHex()));
            }
        }
        for (const auto& vbf : activity->amountBlinders()) {
            if (vbf.isEmpty()) {
                vbfs.append(QJsonValue::Null);
            } else {
                vbfs.append(QString::fromLocal8Bit(ReverseByteArray(vbf).toHex()));
            }
        }
        m_handler->resolve({
            { "signatures", signatures },
            { "asset_commitments", asset_commitments },
            { "value_commitments", value_commitments },
            { "assetblinders", abfs },
            { "amountblinders", vbfs }
        });
    });
    connect(activity, &Activity::failed, [this] {
        setFailed(true);
    });
    activity->exec();
}
