#include "device.h"
#include "handler.h"
#include "network.h"
#include "resolver.h"
#include "wallet.h"


extern "C" {

int wally_ec_public_key_decompress(
    const unsigned char *pub_key,
    size_t pub_key_len,
    unsigned char *bytes_out,
    size_t len);

} // extern "C"


Resolver::Resolver(Handler *handler, const QJsonObject& result)
    : QObject(handler)
    , m_handler(handler)
    , m_result(result)
{
}

Wallet *Resolver::wallet() const
{
    return m_handler->m_wallet;
}

Network *Resolver::network() const
{
    return wallet()->network();
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
    Q_ASSERT(m_handler->m_wallet->m_device);
}

Device *DeviceResolver::device() const
{
    return m_handler->m_wallet->m_device;
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
    if (m_paths.empty()) return emit m_handler->resolve({{ "xpubs", m_xpubs }});

    auto path = m_paths.takeFirst();
    auto command = device()->getWalletPublicKey(m_handler->m_wallet->network(), path);
    connect(command, &Command::finished, [this, command] {
        m_xpubs.append(command->m_xpub);
        resolve();
    });
}

SignTransactionResolver::SignTransactionResolver(Handler* handler, const QJsonObject& result)
    : DeviceResolver(handler, result)
{
}

void SignTransactionResolver::resolve()
{
    // TODO signTransaction should not receive required_data
    auto command = device()->signTransaction(m_required_data);
    connect(command, &Command::finished, [this, command] {
        for (const auto& signature : command->signatures) {
            qDebug() << signature.toHex();
            m_signatures.append(QString::fromLocal8Bit(signature.toHex()));
        }
        m_handler->resolve({{ "signatures", m_signatures }});
    });
}
