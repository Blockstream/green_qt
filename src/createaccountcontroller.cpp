#include "createaccountcontroller.h"

#include <gdk.h>
#include <wally_bip32.h>

#include "ga.h"
#include "handlers/createaccounthandler.h"
#include "json.h"
#include "wallet.h"

namespace {

bool IsValidXpub(const QByteArray& xpub)
{
    ext_key key;
    return bip32_key_from_base58(xpub.constData(), &key) == WALLY_OK;
}

} // namespace

CreateAccountController::CreateAccountController(QObject *parent)
    : Controller(parent)
{
}

void CreateAccountController::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged(m_name);
    updateError("name", QString{"empty"}, m_name.isEmpty());
}

void CreateAccountController::setType(const QString& type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged(m_type);
}

void CreateAccountController::setRecoveryMnemonicSize(int recovery_mnemonic_size)
{
    if (m_recovery_mnemonic_size == recovery_mnemonic_size) return;
    m_recovery_mnemonic_size = recovery_mnemonic_size;
    emit recoveryMnemonicSizeChanged(m_recovery_mnemonic_size);
    generateRecoveryMnemonic();
}

void CreateAccountController::setRecoveryMnemonic(const QStringList& recovery_mnemonic)
{
    if (m_recovery_mnemonic == recovery_mnemonic) return;
    m_recovery_mnemonic = recovery_mnemonic;
    emit recoveryMnemonicChanged(m_recovery_mnemonic);
    setRecoveryXpub({});
}

void CreateAccountController::generateRecoveryMnemonic()
{
    setRecoveryMnemonic(gdk::generate_mnemonic(m_recovery_mnemonic_size));
}

void CreateAccountController::create()
{
    Q_ASSERT(noErrors());

    auto details = QJsonObject{
        { "name", m_name },
        { "type", m_type },
    };

    if (m_type == "2of3") {
        if (!m_recovery_mnemonic.isEmpty()) {
            Q_ASSERT(m_recovery_xpub.isEmpty());
            details["recovery_mnemonic"] = m_recovery_mnemonic.join(" ");
        } else if (!m_recovery_xpub.isEmpty()) {
            details["recovery_xpub"] = m_recovery_xpub;
        } else {
            Q_UNREACHABLE();
        }
    }

    auto handler = new CreateAccountHandler(details, wallet()->session());
    connect(handler, &Handler::done, this, [this, handler] {
        // TODO switch to new account
        auto account = wallet()->getOrCreateAccount(handler->result().value("result").toObject());
        wallet()->reload();
        emit created(handler, account);
    });
    exec(handler);
}

void CreateAccountController::setRecoveryXpub(const QString& recovery_xpub)
{
    if (m_recovery_xpub == recovery_xpub) return;
    m_recovery_xpub = recovery_xpub;
    emit recoveryXpubChanged(m_recovery_xpub);
    setRecoveryMnemonic({});
    if (m_recovery_xpub.isEmpty()) {
        setError("recoveryXpub", QString{"empty"});
    } else if (!IsValidXpub(m_recovery_xpub.toLocal8Bit())) {
        setError("recoveryXpub", QString{"invalid"});
    } else {
        clearError("recoveryXpub");
    }
}
