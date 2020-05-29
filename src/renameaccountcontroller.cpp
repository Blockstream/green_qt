#include "renameaccountcontroller.h"
#include "account.h"
#include "json.h"
#include "wallet.h"

#include <gdk.h>

RenameAccountController::RenameAccountController(QObject* parent)
    : AccountController(parent)
{
}

void RenameAccountController::rename(const QString& name)
{
    if (!account()) return;
    int res = GA_rename_subaccount(session(), account()->m_pointer, name.toLatin1().constData());
    Q_ASSERT(res == GA_OK);
    wallet()->reload();
}
