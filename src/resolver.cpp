#include "context.h"
#include "device.h"
#include "network.h"
#include "resolver.h"
#include "session.h"
#include "task.h"
#include "util.h"

#include <QSet>

namespace {

QList<Asset*> GetAssets(Context* context, const QJsonArray& outputs)
{
    if (!context) return {};
    QList<Asset*> assets;
    QSet<QString> asset_ids;
    for (const auto value : outputs) {
        const auto asset_id = value.toObject().value("asset_id").toString();
        if (asset_id.isEmpty()) continue;
        if (asset_ids.contains(asset_id)) continue;
        asset_ids.insert(asset_id);
        assets.append(context->getOrCreateAsset(asset_id));
    }
    return assets;
}

}

Resolver::Resolver(const QJsonObject& result, AuthHandlerTask* task)
    : QObject(task)
    , m_task(task)
    , m_session(task->session())
    , m_result(result)
{
}

void Resolver::pushDeviceTask(Task* task)
{
    Q_ASSERT(!m_device_task);
    m_device_task = task;
    connect(m_device_task, &QObject::destroyed, this, [this] {
        m_device_task = nullptr;
        emit deviceTaskChanged();
    });
    emit deviceTaskChanged();
}

QString Resolver::getTaskError(Task* task, const QString& defaultMessage) const
{
    const QString error = task->error();
    return error.isEmpty() ? defaultMessage : error;
}

TwoFactorResolver::TwoFactorResolver(const QJsonObject& result, AuthHandlerTask* task)
    : Resolver(result, task)
    , m_method(result.value("method").toString())
    , m_attempts_remaining(result.value("attempts_remaining").toInt())
{
}

void TwoFactorResolver::resolve()
{
//    emit resolved(m_code.toLocal8Bit());
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

DeviceResolver::DeviceResolver(Device* device, const QJsonObject& result, AuthHandlerTask* task)
    : Resolver(result, task)
    , m_device(device)
    , m_required_data(result.value("required_data").toObject())
{
    Q_ASSERT(m_required_data.contains("device"));
}

GetXPubsResolver::GetXPubsResolver(Device* device, const QJsonObject& result, AuthHandlerTask* task)
    : DeviceResolver(device, result, task)
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
    if (m_paths.empty()) {
        emit resolved({{ "xpubs", m_xpubs }});
        return;
    }

    auto path = m_paths.takeFirst();
    auto task = m_device->getWalletPublicKey(m_session->network(), path);
    connect(task, &Task::finished, this, [this, task] {
        task->deleteLater();
        m_xpubs.append(QString::fromLocal8Bit(task->publicKey()));
        resolve();
    });
    connect(task, &Task::failed, this, [this, task] {
        task->deleteLater();
        emit failed(getTaskError(task, "Failed to get wallet public key"));
    });
    m_device->exec(task);
}

SignTransactionResolver::SignTransactionResolver(Device* device, const QJsonObject& result, AuthHandlerTask* task)
    : DeviceResolver(device, result, task)
{
}

void SignTransactionResolver::resolve()
{
    Q_ASSERT(m_required_data.value("action").toString() == "sign_tx");

    const auto transaction = ParseByteArray(m_required_data.value("transaction"));
    const auto signing_inputs = m_required_data.value("transaction_inputs").toArray();
    const auto transaction_outputs = m_required_data.value("transaction_outputs").toArray();
    const auto signing_transactions = m_required_data.value("signing_transactions").toObject();

    auto task = device()->signTransaction(m_session->network(), transaction, signing_inputs, transaction_outputs, signing_transactions);
    connect(task, &Task::finished, [this, task] {
        task->deleteLater();
        QJsonArray signatures;
        for (const auto& signature : task->signatures()) {
            signatures.append(QString::fromLocal8Bit(signature.toHex()));
        }
        QJsonObject data{
            { "signatures", signatures }
        };
        if (m_required_data.value("use_ae_protocol").toBool()) {
            QJsonArray signer_commitments;
            for (const auto& signer_commitment : task->signerCommitments()) {
                signer_commitments.append(QString::fromLocal8Bit(signer_commitment.toHex()));
            }
            data["signer_commitments"] = signer_commitments;
        }
        emit resolved(data);
    });
    connect(task, &Task::failed, [this, task] {
        task->deleteLater();
        emit failed(getTaskError(task, "Failed to sign transaction"));
    });
    m_device->exec(task);
}

BlindingKeysResolver::BlindingKeysResolver(Device* device, const QJsonObject& result, AuthHandlerTask* task)
    : DeviceResolver(device, result, task)
{
    m_scripts = m_required_data.value("scripts").toArray();
}

void BlindingKeysResolver::resolve()
{
    if (m_public_keys.size() == m_scripts.size()) {
        emit resolved(QJsonObject({{ "public_keys", m_public_keys }}));
        return;
    }

    const auto script = m_scripts.at(m_public_keys.size());
    auto task = device()->getBlindingKey(script.toString());
    connect(task, &Task::finished, this, [this, task] {
        task->deleteLater();
        m_public_keys.append(QString::fromLocal8Bit(task->publicKey().toHex()));
        resolve();
    });
    connect(task, &Task::failed, this, [this, task] {
        task->deleteLater();
        emit failed(getTaskError(task, "Failed to get blinding key"));
    });
    m_device->exec(task);
}

BlindingNoncesResolver::BlindingNoncesResolver(Device* device, const QJsonObject& result, AuthHandlerTask* task)
    : DeviceResolver(device, result, task)
{
    m_blinding_keys_required = m_required_data.value("blinding_keys_required").toBool();
    m_scripts = m_required_data.value("scripts").toArray();
    m_public_keys = m_required_data.value("public_keys").toArray();
    Q_ASSERT(m_scripts.size() == m_public_keys.size());
}

void BlindingNoncesResolver::resolve()
{
    const int index = m_nonces.size();
    if (index == m_scripts.size()) {
        emit resolved({{ "nonces", m_nonces }, { "public_keys", m_blinding_keys }});
        return;
    }

    const auto pubkey = QByteArray::fromHex(m_public_keys.at(index).toString().toLocal8Bit());
    const auto script = QByteArray::fromHex(m_scripts.at(index).toString().toLocal8Bit());

    auto task = device()->getBlindingNonce(pubkey, script);
    connect(task, &Task::finished, this, [=, this] {
        task->deleteLater();
        m_nonces.append(QString::fromLocal8Bit(task->nonce().toHex()));
        if (m_blinding_keys_required) {
            auto task = device()->getBlindingKey(m_scripts.at(index).toString());
            connect(task, &Task::finished, this, [=, this] {
                task->deleteLater();
                m_blinding_keys.append(QString::fromLocal8Bit(task->publicKey().toHex()));
                resolve();
            });
            connect(task, &Task::failed, this, [this, task] {
                task->deleteLater();
                emit failed(getTaskError(task, "Failed to get blinding key"));
            });
            m_device->exec(task);
        } else {
            resolve();
        }
    });
    connect(task, &Task::failed, this, [this, task] {
        task->deleteLater();
        emit failed(getTaskError(task, "Failed to get blinding nonce"));
    });
    m_device->exec(task);
}

SignLiquidTransactionResolver::SignLiquidTransactionResolver(Device* device, const QJsonObject& result, AuthHandlerTask* task)
    : DeviceResolver(device, result, task)
    , m_transaction(m_required_data.value("transaction").toObject())
    , m_outputs(m_required_data.value("transaction_outputs").toArray())
{
    Q_ASSERT(m_session->network()->isLiquid());
    Q_ASSERT(m_required_data.value("action").toString() == "sign_tx");
}

void SignLiquidTransactionResolver::resolve()
{
    const auto transaction = ParseByteArray(m_required_data.value("transaction"));
    const auto signing_inputs = m_required_data.value("transaction_inputs").toArray();
    const auto outputs = m_required_data.value("transaction_outputs").toArray();
    const auto assets = GetAssets(m_session->context(), outputs);

    auto task = device()->signLiquidTransaction(m_session->network(), transaction, signing_inputs, outputs, assets);

    connect(task, &Task::finished, [this, task] {
        task->deleteLater();
        QJsonArray signatures;
        QJsonArray asset_commitments;
        QJsonArray value_commitments;
        QJsonArray abfs;
        QJsonArray vbfs;
        for (const auto& signature : task->signatures()) {
            signatures.append(QString::fromLocal8Bit(signature.toHex()));
        }
        QJsonObject data{
            { "signatures", signatures },
        };

        if (m_required_data.value("use_ae_protocol").toBool()) {
            QJsonArray signer_commitments;
            for (const auto& signer_commitment : task->signerCommitments()) {
                signer_commitments.append(QString::fromLocal8Bit(signer_commitment.toHex()));
            }
            data["signer_commitments"] = signer_commitments;
        }

        emit resolved(data);
    });
    connect(task, &Task::failed, this, [this, task] {
        task->deleteLater();
        emit failed(getTaskError(task, "Failed to sign liquid transaction"));
    });
    m_device->exec(task);
    pushDeviceTask(task);
}

GetMasterBlindingKeyResolver::GetMasterBlindingKeyResolver(Device* device, const QJsonObject& result, AuthHandlerTask* task)
    : DeviceResolver(device, result, task)
{
}

void GetMasterBlindingKeyResolver::resolve()
{
    auto task = device()->getMasterBlindingKey();
    connect(task, &Task::finished, [this, task] {
        task->deleteLater();
        emit resolved({
            { "master_blinding_key", QString::fromLocal8Bit(task->masterBlindingKey().toHex()) }
        });
    });
    connect(task, &Task::failed, this, [this, task] {
        task->deleteLater();
        emit failed(getTaskError(task, "Failed to get master blinding key"));
    });
    m_device->exec(task);
    pushDeviceTask(task);
}

GetBlindingFactorsResolver::GetBlindingFactorsResolver(Device *device, const QJsonObject &result, AuthHandlerTask* task)
    : DeviceResolver(device, result, task)
{
}

void GetBlindingFactorsResolver::resolve()
{
    const auto inputs = m_required_data.value("transaction_inputs").toArray();
    const auto outputs = m_required_data.value("transaction_outputs").toArray();

    auto task = device()->getBlindingFactors(inputs, outputs);
    connect(task, &Task::finished, this, [=, this] {
        task->deleteLater();

        QJsonArray assetblinders;
        for (const auto& b : task->assetBlinders()) {
            assetblinders.append(QString::fromLocal8Bit(b.toHex()));
        }

        QJsonArray amountblinders;
        for (const auto& b : task->amountBlinders()) {
            amountblinders.append(QString::fromLocal8Bit(b.toHex()));
        }

        emit resolved({
            { "assetblinders", assetblinders },
            { "amountblinders", amountblinders }
        });
    });
    connect(task, &Task::failed, this, [this, task] {
        task->deleteLater();
        emit failed(getTaskError(task, "Failed to get blinding factors"));
    });
    m_device->exec(task);
    pushDeviceTask(task);
}
