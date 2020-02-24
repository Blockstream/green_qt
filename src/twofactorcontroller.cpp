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

void TwoFactorController::enable(const QByteArray& data)
{
    QMetaObject::invokeMethod(wallet()->m_context, [this, data] {
        auto details = Json::fromObject({
            { "data", QString(data) },
            { "enabled", true }
        });
        int res = GA_change_settings_twofactor(wallet()->m_session, m_method.constData(), details, &m_auth_handler);
        Q_ASSERT(res == GA_OK);

        GA_destroy_json(details);

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

void TwoFactorController::changeLimit(bool is_fiat, const QString& limit)
{
    auto unit = wallet()->settings().value("unit").toString().toLower();
    dispatch([unit, is_fiat, limit] (GA_session* session, GA_auth_handler** call) {
        auto details = Json::fromObject({
            { "is_fiat", is_fiat },
            { is_fiat ? "fiat" : unit, limit }
        });
        int err = GA_twofactor_change_limits(session, details, call);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(details);
        Q_ASSERT(err == GA_OK);
    });
}

bool TwoFactorController::update(const QJsonObject& result)
{
    if (result.value("status").toString() == "done") {
        // Two factor configuration has changed, update it.
        wallet()->updateConfig();
    }
    return Controller::update(result);
}
