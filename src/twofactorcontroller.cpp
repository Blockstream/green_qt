#include "twofactorcontroller.h"
#include "wallet.h"
#include "json.h"
#include "ga.h"


TwoFactorController::TwoFactorController(QObject *parent) : QObject(parent)
{

}

Wallet *TwoFactorController::wallet() const
{
    return m_wallet;
}

void TwoFactorController::setWallet(Wallet *wallet)
{
    if (m_wallet == wallet)
        return;

    m_wallet = wallet;
    emit walletChanged(m_wallet);
}

#include <QDebug>

void TwoFactorController::call()
{
    while (true) {
        QJsonObject result = GA::auth_handler_get_result(m_call);
        qDebug() << result;
        QString status = result.value("status").toString();

        if (status == "done") {
            //if (output) *output = Json::fromObject(result.value("result").toObject());
            break;
        }

        if (status == "error") {
            qDebug("see error above");
            break;
        }

        if (status == "request_code") {
            qDebug("see methods above");
            // result is like:
            // {"action":"disable_2fa","device":null,"methods":["sms"],"status":"request_code"}
            int res = GA_auth_handler_request_code(m_call, "sms");
            Q_ASSERT(res == GA_OK);
            //emit promptCode();
            GA_auth_handler_request_code(m_call, result.value("methods").toArray().first().toString().toLocal8Bit().data());
            //break;
        }

        if (status == "resolve_code") {
            qDebug("should call prompt code and send with GA_auth_handler_resolve_code");
            emit promptCode();
//                QMetaObject::invokeMethod(this, [this] {
//                   emit
//                });
            break;
        }

        if (status == "call") {
            GA_auth_handler_call(m_call);
        }
    }
}

void TwoFactorController::go()
{
    QMetaObject::invokeMethod(m_wallet->m_context, [this] {
        auto details = Json::fromObject({
            { "data", "TODO: prompt for phone" },
            { "enabled", true }
        });
        int res = GA_change_settings_twofactor(m_wallet->m_session, "sms", details, &m_call);
        Q_ASSERT(res == GA_OK);

        call();
    });
}

void TwoFactorController::enableEmail()
{
    QMetaObject::invokeMethod(m_wallet->m_context, [this] {
        auto details = Json::fromObject({
            { "data", "TODO: prompt for email" },
            { "enabled", true }
        });
        int res = GA_change_settings_twofactor(m_wallet->m_session, "email", details, &m_call);
        Q_ASSERT(res == GA_OK);

        call();
    });
}

void TwoFactorController::disable()
{
    QMetaObject::invokeMethod(m_wallet->m_context, [this] {
        auto details = Json::fromObject({
            { "enabled", false }
        });
        int res = GA_change_settings_twofactor(m_wallet->m_session, "sms", details, &m_call);
        Q_ASSERT(res == GA_OK);

        call();
    });
}

void TwoFactorController::resolveCode(const QByteArray& code)
{
    QMetaObject::invokeMethod(m_wallet->m_context, [this, code] {
        int res = GA_auth_handler_resolve_code(m_call, code.data());
        Q_ASSERT(res == GA_OK);
        qDebug() << "GA_auth_handler_resolve_code done";
        call();
    });
}
