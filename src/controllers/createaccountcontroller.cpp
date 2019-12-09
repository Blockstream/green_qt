#include "createaccountcontroller.h"
#include "../wallet.h"
#include "../json.h"

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

void CreateAccountController::reset()
{
    Controller::reset();
    m_name.clear();
}

void CreateAccountController::create()
{
    QMetaObject::invokeMethod(m_wallet->m_context, [this] {
        GA_json* details = Json::fromObject({
            { "name", m_name.toLocal8Bit().constData() },
            { "type", "2of2" }
        });

        int res = GA_create_subaccount(m_wallet->m_session, details, &m_auth_handler);
        Q_ASSERT(res == GA_OK);

        GA_destroy_json(details);

        process();

        m_wallet->reload();
    });
}
