#include "accountcontroller.h"
#include "account.h"

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
    auto xxx = context->contextProperty("account");
    auto yyy = xxx.value<QObject*>();
    return qobject_cast<Account*>(yyy);
}

Wallet *AccountController::wallet() const
{
    auto self = account();
    if (self) return self->wallet();
    return Controller::wallet();
}
