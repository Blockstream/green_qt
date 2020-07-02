#ifndef GREEN_RENAMEACCOUNTCONTROLLER_H
#define GREEN_RENAMEACCOUNTCONTROLLER_H

#include <QtQml>

#include "accountcontroller.h"

class RenameAccountController : public AccountController
{
    Q_OBJECT
    QML_ELEMENT
public:
    RenameAccountController(QObject* parent = nullptr);
    Q_INVOKABLE void rename(const QString& name);
};

#endif // GREEN_RENAMEACCOUNTCONTROLLER_H
