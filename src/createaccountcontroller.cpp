#include "createaccountcontroller.h"
#include "handlers/createaccounthandler.h"
#include "json.h"
#include "wallet.h"

#include <gdk.h>
#include "ga.h"

CreateAccountController::CreateAccountController(QObject *parent)
    : Controller(parent)
{
}

void CreateAccountController::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged(m_name);
}

void CreateAccountController::setType(const QString& type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged(m_type);
}

void CreateAccountController::setRecoveryMnemonic(const QStringList& recovery_mnemonic)
{
    if (m_recovery_mnemonic == recovery_mnemonic) return;
    m_recovery_mnemonic = recovery_mnemonic;
    emit recoveryMnemonicChanged(m_recovery_mnemonic);
    m_recovery_xpub.clear();
    emit recoveryXpubChanged(m_recovery_xpub);
}

void CreateAccountController::generateRecoveryMnemonic()
{
    setRecoveryMnemonic(GA::generate_mnemonic(12));
}

void CreateAccountController::create()
{
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

    auto handler = new CreateAccountHandler(details, wallet());
    connect(handler, &Handler::done, this, [this, handler] {
        // TODO switch to new account
        auto account = wallet()->getOrCreateAccount(handler->result().value("result").toObject());
        wallet()->reload();
        emit created(handler);
    });
    exec(handler);
}

void CreateAccountController::setRecoveryXpub(const QString &recovery_xpub)
{
    if (m_recovery_xpub == recovery_xpub) return;
    m_recovery_xpub = recovery_xpub;
    emit recoveryXpubChanged(m_recovery_xpub);
    m_recovery_mnemonic.clear();
    emit recoveryMnemonicChanged(m_recovery_mnemonic);
}
