#include "accountcontroller.h"
#include "../account.h"
#include <QQmlEngine>
#include <QQmlContext>

AccountController::AccountController(QObject *parent)
    : Controller(parent)
{

}

Account *AccountController::account() const
{
    if (m_account) return m_account;
    auto context = qmlContext(this);
    if (!context) return nullptr;
    return qobject_cast<Account*>(context->contextProperty("account").value<QObject*>());
}

void AccountController::setAccount(Account *account)
{
    if (m_account == account)
        return;

    m_account = account;
    emit accountChanged(m_account);

    setWallet(account ? account->wallet() : nullptr);
}

Wallet *AccountController::wallet() const
{
    auto self = account();
    if (self) return self->wallet();
    return Controller::wallet();
}
