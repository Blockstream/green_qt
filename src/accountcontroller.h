#ifndef GREEN_ACCOUNTCONTROLLER_H
#define GREEN_ACCOUNTCONTROLLER_H

#include "controller.h"

class Account;

class AccountController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
public:
    explicit AccountController(QObject* parent = nullptr);

    Account* account() const;
    void setAccount(Account* account);

signals:
    void accountChanged();

protected:
    Account* m_account{nullptr};
};

#endif // GREEN_ACCOUNTCONTROLLER_H
