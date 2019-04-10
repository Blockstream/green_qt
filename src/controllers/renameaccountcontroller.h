#ifndef GREEN_RENAMEACCOUNTCONTROLLER_H
#define GREEN_RENAMEACCOUNTCONTROLLER_H

#include "accountcontroller.h"

class RenameAccountController : public AccountController
{
    Q_OBJECT

public:
    RenameAccountController(QObject* parent = nullptr);

    void reset();

public slots:
    void rename();

signals:
    void nameChanged(QString name);

private:
    QString m_name;
};

#endif // GREEN_RENAMEACCOUNTCONTROLLER_H
