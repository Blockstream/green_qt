#ifndef GREEN_ACCOUNTCONTROLLER_H
#define GREEN_ACCOUNTCONTROLLER_H

#include "controller.h"

class Account;

class AccountController : public Controller
{
    Q_OBJECT
public:
    explicit AccountController(QObject* parent = nullptr);
    Account* account() const;
    Wallet* wallet() const override;
signals:
    void accountChanged(Account* account);
protected:
    Account* m_account{nullptr};
};

#endif // GREEN_ACCOUNTCONTROLLER_H
