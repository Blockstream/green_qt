#include "activitymanager.h"
#include "device.h"
#include "network.h"
#include "resolver.h"
#include "session.h"
#include "task.h"
#include "util.h"

Resolver::Resolver(const QJsonObject& result, AuthHandlerTask* task)
    : QObject(task)
    , m_task(task)
    , m_session(task->session())
    , m_result(result)
{
}

void Resolver::pushActivity(Activity* activity)
{
    Q_ASSERT(!m_activity);
    m_activity = activity;
    connect(m_activity, &Activity::destroyed, this, [this] {
        m_activity = nullptr;
        emit activityChanged();
    });
    emit activityChanged();
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

QString TwoFactorResolver::telegramBrowserUrl() const
{
    Q_ASSERT(m_method == "telegram");
    return m_result.value("auth_data").toObject().value("telegram_url").toString();
}

QString TwoFactorResolver::telegramAppUrl() const
{
    auto url = telegramBrowserUrl();
    url.replace("https://t.me/", "tg://resolve?domain=");
    url.replace("?start=", "&start=");
    return url;
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
    auto activity = m_device->getWalletPublicKey(m_session->network(), path);
    connect(activity, &Activity::finished, this, [this, activity] {
        activity->deleteLater();
        m_xpubs.append(QString::fromLocal8Bit(activity->publicKey()));
        resolve();
    });
    connect(activity, &GetWalletPublicKeyActivity::failed, this, [this, activity] {
        activity->deleteLater();
        emit failed();
    });
    ActivityManager::instance()->exec(activity);
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

    auto activity = device()->signTransaction(m_session->network(), transaction, signing_inputs, transaction_outputs, signing_transactions);
    connect(activity, &SignTransactionActivity::finished, [this, activity] {
        activity->deleteLater();
        QJsonArray signatures;
        for (const auto& signature : activity->signatures()) {
            signatures.append(QString::fromLocal8Bit(signature.toHex()));
        }
        QJsonObject data{
            { "signatures", signatures }
        };
        if (m_required_data.value("use_ae_protocol").toBool()) {
            QJsonArray signer_commitments;
            for (const auto& signer_commitment : activity->signerCommitments()) {
                signer_commitments.append(QString::fromLocal8Bit(signer_commitment.toHex()));
            }
            data["signer_commitments"] = signer_commitments;
        }
        emit resolved(data);
    });
    connect(activity, &SignTransactionActivity::failed, [this, activity] {
        activity->deleteLater();
        emit failed();
    });
    ActivityManager::instance()->exec(activity);
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
    auto activity = device()->getBlindingKey(script.toString());
    connect(activity, &Activity::finished, this, [this, activity] {
        activity->deleteLater();
        m_public_keys.append(QString::fromLocal8Bit(activity->publicKey().toHex()));
        resolve();
    });
    connect(activity, &Activity::failed, this, [this, activity] {
        activity->deleteLater();
        emit failed();
    });
    ActivityManager::instance()->exec(activity);
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

    auto activity = device()->getBlindingNonce(pubkey, script);
    connect(activity, &Activity::finished, this, [=] {
        activity->deleteLater();
        m_nonces.append(QString::fromLocal8Bit(activity->nonce().toHex()));
        if (m_blinding_keys_required) {
            auto activity = device()->getBlindingKey(m_scripts.at(index).toString());
            connect(activity, &Activity::finished, this, [=] {
                activity->deleteLater();
                m_blinding_keys.append(QString::fromLocal8Bit(activity->publicKey().toHex()));
                resolve();
            });
            connect(activity, &Activity::failed, this, [=] {
                activity->deleteLater();
                emit failed();
            });
            ActivityManager::instance()->exec(activity);
        } else {
            resolve();
        }
    });
    connect(activity, &Activity::failed, this, [this, activity] {
        activity->deleteLater();
        emit failed();
    });
    ActivityManager::instance()->exec(activity);
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

    auto activity = device()->signLiquidTransaction(m_session->network(), transaction, signing_inputs, outputs);

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
        QJsonObject data{
            { "signatures", signatures },
        };

        if (m_required_data.value("use_ae_protocol").toBool()) {
            QJsonArray signer_commitments;
            for (const auto& signer_commitment : activity->signerCommitments()) {
                signer_commitments.append(QString::fromLocal8Bit(signer_commitment.toHex()));
            }
            data["signer_commitments"] = signer_commitments;
        }

        emit resolved(data);
    });
    connect(activity, &Activity::failed, this, &Resolver::failed);
    ActivityManager::instance()->exec(activity);
    pushActivity(activity);
}

GetMasterBlindingKeyResolver::GetMasterBlindingKeyResolver(Device* device, const QJsonObject& result, AuthHandlerTask* task)
    : DeviceResolver(device, result, task)
{
}

void GetMasterBlindingKeyResolver::resolve()
{
    auto activity = device()->getMasterBlindingKey();
    connect(activity, &Activity::finished, [this, activity] {
        activity->deleteLater();
        emit resolved({
            { "master_blinding_key", QString::fromLocal8Bit(activity->masterBlindingKey().toHex()) }
        });
    });
    connect(activity, &Activity::failed, this, &Resolver::failed);
    ActivityManager::instance()->exec(activity);
    pushActivity(activity);
}

GetBlindingFactorsResolver::GetBlindingFactorsResolver(Device *device, const QJsonObject &result, AuthHandlerTask* task)
    : DeviceResolver(device, result, task)
{
}

void GetBlindingFactorsResolver::resolve()
{
    const auto inputs = m_required_data.value("transaction_inputs").toArray();
    const auto outputs = m_required_data.value("transaction_outputs").toArray();

    auto activity = device()->getBlindingFactors(inputs, outputs);
    connect(activity, &Activity::finished, this, [=] {
        activity->deleteLater();

        QJsonArray assetblinders;
        for (const auto& b : activity->assetBlinders()) {
            assetblinders.append(QString::fromLocal8Bit(b.toHex()));
        }

        QJsonArray amountblinders;
        for (const auto& b : activity->amountBlinders()) {
            amountblinders.append(QString::fromLocal8Bit(b.toHex()));
        }

        emit resolved({
            { "assetblinders", assetblinders },
            { "amountblinders", amountblinders }
        });
    });
    connect(activity, &Activity::failed, this, &Resolver::failed);
    ActivityManager::instance()->exec(activity);
    pushActivity(activity);
}
