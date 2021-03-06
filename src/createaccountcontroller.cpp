#include "createaccountcontroller.h"
#include "handlers/createaccounthandler.h"
#include "json.h"
#include "wallet.h"

#include <gdk.h>

CreateAccountController::CreateAccountController(QObject *parent)
    : Controller(parent)
{
}

void CreateAccountController::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged(m_name);
}

void CreateAccountController::setType(const QString& type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged(m_type);
}

void CreateAccountController::create()
{
    auto details = QJsonObject{
        { "name", m_name },
        { "type", m_type }
    };
    auto handler = new CreateAccountHandler(details, wallet());
    connect(handler, &Handler::done, this, [this, handler] {
        // TODO switch to new account
        auto account = wallet()->getOrCreateAccount(handler->result());
        wallet()->reload();
        emit created(handler);
    });
    exec(handler);
}
