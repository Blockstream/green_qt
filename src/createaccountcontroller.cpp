#include "createaccountcontroller.h"

#include <gdk.h>
#include <wally_wrapper.h>

#include "context.h"
#include "ga.h"
#include "json.h"
#include "task.h"
#include "wallet.h"

namespace {

bool IsValidXpub(const QString& xpub)
{
    ext_key key;
    const auto rc = bip32_key_from_base58(xpub.toUtf8().constData(), &key);
    return rc == WALLY_OK;
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
    emit nameChanged();

    clearError("create");
    updateError("name", QString{"empty"}, m_name.isEmpty());
}

void CreateAccountController::setType(const QString& type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged();

    clearError("create");
}

void CreateAccountController::setRecoveryMnemonic(const QStringList& recovery_mnemonic)
{
    if (m_recovery_mnemonic == recovery_mnemonic) return;
    m_recovery_mnemonic = recovery_mnemonic;
    emit recoveryMnemonicChanged();
    if (!m_recovery_xpub.isEmpty()) {
        m_recovery_xpub.clear();
        emit recoveryXpubChanged();
    }
}

QStringList CreateAccountController::generateMnemonic(int size) const
{
    return gdk::generate_mnemonic(size);
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

    const auto context = m_context;
    const auto create_account = new CreateAccountTask(details, context);
    const auto load_accounts = new LoadAccountsTask(context);

    create_account->then(load_accounts);

    auto group = new TaskGroup(this);

    group->add(create_account);
    group->add(load_accounts);

    m_dispatcher->add(group);

    connect(create_account, &Task::failed, this, [=](const QString& error) {
        setError("create", error);
    });

    connect(group, &TaskGroup::finished, this, [=] {
        m_account = context->getAccountByPointer(create_account->pointer());
        if (!m_account) return;
        emit accountChanged();
        emit created(m_account);
    });
}

void CreateAccountController::setRecoveryXpub(const QString& recovery_xpub)
{
    if (m_recovery_xpub == recovery_xpub) return;
    if (!m_recovery_mnemonic.isEmpty()) {
        m_recovery_mnemonic.clear();
        emit recoveryMnemonicChanged();
    }
    m_recovery_xpub = recovery_xpub;
    emit recoveryXpubChanged();
    if (m_recovery_xpub.isEmpty()) {
        setError("recoveryXpub", QString{"empty"});
    } else if (!IsValidXpub(m_recovery_xpub)) {
        setError("recoveryXpub", QString{"invalid"});
    } else {
        clearError("recoveryXpub");
    }
}

MnemonicGenerator::MnemonicGenerator(QObject *parent)
    : QObject(parent)
{
    generate();
}

void MnemonicGenerator::setSize(int size)
{
    if (m_size == size) return;
    if (size != 12 && size != 24) return;
    m_size = size;
    emit sizeChanged();
    generate();
}

void MnemonicGenerator::generate()
{
    m_mnemonic = gdk::generate_mnemonic(m_size);
    emit mnemonicChanged();
}
