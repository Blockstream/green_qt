#include "renameaccountcontroller.h"
#include "../account.h"
#include "../json.h"
#include "../wallet.h"

#include <QQmlEngine>
#include <QQmlContext>

RenameAccountController::RenameAccountController(QObject* parent)
    : AccountController(parent)
{
}

void RenameAccountController::reset()
{
    AccountController::reset();

    QString name = property("name").toString();
    QQmlContext* context = qmlContext(this);
    if (!context) return;
    Account* account = context->contextProperty("account").value<Account*>();
    if (!account) return;

    setProperty("name", account->name());
}

void RenameAccountController::rename()
{
    QString name = property("name").toString();
    QQmlContext* context = qmlContext(this);
    if (!context) return;
    Account* account = context->contextProperty("account").value<Account*>();
    if (!account) return;
    setAccount(account);

    QMetaObject::invokeMethod(m_wallet->m_context, [this, name] {
        int res = GA_rename_subaccount(m_wallet->m_session, m_account->m_pointer, name.toLocal8Bit().constData());
        qDebug() << "GA_rename_subaccount" << res;
        Q_ASSERT(res == GA_OK);

        m_wallet->reload();
    });
}
