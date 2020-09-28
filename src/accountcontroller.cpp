#include "accountcontroller.h"
#include "account.h"

AccountController::AccountController(QObject *parent)
    : Controller(parent)
{
}

Account *AccountController::account() const
{
    return m_account;
}

void AccountController::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged(m_account);
    setWallet(m_account ? m_account->wallet() : nullptr);
}
