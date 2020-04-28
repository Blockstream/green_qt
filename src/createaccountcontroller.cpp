#include "createaccountcontroller.h"
#include "json.h"
#include "wallet.h"

CreateAccountController::CreateAccountController(QObject *parent) : Controller(parent)
{

}

QString CreateAccountController::name() const
{
    return m_name;
}

void CreateAccountController::setName(const QString &name)
{
    if (m_name == name)
        return;

    m_name = name;
    emit nameChanged(m_name);
}

void CreateAccountController::create()
{
    dispatch([this](GA_session* session, GA_auth_handler** auth_handler) {
        GA_json* details = Json::fromObject({
            { "name", m_name.toLocal8Bit().constData() },
            { "type", m_type.toLocal8Bit().constData() }
        });
        int res = GA_create_subaccount(session, details, auth_handler);
        Q_ASSERT(res == GA_OK);
        GA_destroy_json(details);
    });
}

bool CreateAccountController::update(const QJsonObject &result)
{
    auto status = result.value("status").toString();
    if (status == "done") {
        int pointer = result.value("result").toObject().value("pointer").toInt();
        auto account = wallet()->getOrCreateAccount(pointer);
        emit accountCreated(account);
        wallet()->reload();
        wallet()->setCurrentAccount(account);
    }
    return Controller::update(result);
}

void CreateAccountController::setType(const QString& type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged(m_type);
}
