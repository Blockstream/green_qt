#include "twofactorcontroller.h"
#include "wallet.h"
#include "json.h"
#include "ga.h"

TwoFactorController::TwoFactorController(QObject *parent)
    : Controller(parent)
{
}

QByteArray TwoFactorController::method() const
{
    return m_method;
}

void TwoFactorController::setMethod(const QByteArray& method)
{
    if (m_method == method) return;
    m_method = method;
    emit methodChanged(m_method);
}

void TwoFactorController::enable(const QByteArray& number)
{
    QMetaObject::invokeMethod(wallet()->m_context, [this, number] {
        auto details = Json::fromObject({
            { "data", QString(number) },
            { "enabled", true }
        });
        int res = GA_change_settings_twofactor(wallet()->m_session, m_method.constData(), details, &m_auth_handler);
        Q_ASSERT(res == GA_OK);

        QMetaObject::invokeMethod(this, [this] {
            process();
        });
    });
}


void TwoFactorController::disable()
{
    QMetaObject::invokeMethod(wallet()->m_context, [this] {
        auto details = Json::fromObject({
            { "enabled", false }
        });
        int res = GA_change_settings_twofactor(wallet()->m_session, m_method.constData(), details, &m_auth_handler);
        Q_ASSERT(res == GA_OK);

        QMetaObject::invokeMethod(this, [this] {
            process();
        });
    });
}
