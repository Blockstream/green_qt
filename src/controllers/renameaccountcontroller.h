#ifndef GREEN_RENAMEACCOUNTCONTROLLER_H
#define GREEN_RENAMEACCOUNTCONTROLLER_H

#include "accountcontroller.h"

class RenameAccountController : public AccountController
{
    Q_OBJECT
public:
    RenameAccountController(QObject* parent = nullptr);
    Q_INVOKABLE void rename(const QString& name);
};

#endif // GREEN_RENAMEACCOUNTCONTROLLER_H
