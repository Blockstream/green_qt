#include "createaccountcontroller.h"
#include "handler.h"
#include "json.h"
#include "wallet.h"

#include <gdk.h>

class CreateAccountHandler : public Handler
{
    QJsonObject m_details;
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        auto details = Json::fromObject(m_details);
        int res = GA_create_subaccount(session, details, auth_handler);
        Q_ASSERT(res == GA_OK);
        GA_destroy_json(details);
    }
public:
    CreateAccountHandler(const QJsonObject& details, Wallet* wallet)
        : Handler(wallet)
        , m_details(details)
    {
    }
    int pointer() const {
        Q_ASSERT(result().value("status").toString() == "done");
        return result().value("result").toObject().value("pointer").toInt();
    }
};

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
        auto account = wallet()->getOrCreateAccount(handler->pointer());
        wallet()->reload();
        emit created(handler);
    });
    exec(handler);
}
