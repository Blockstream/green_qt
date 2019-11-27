#include "controller.h"
#include "../json.h"
#include "../wallet.h"
#include <QDebug>

Controller::Controller(QObject* parent)
    : QObject(parent)
{
}

QString Controller::state() const
{
    return m_state;
}

void Controller::setState(const QString &state)
{
    if (m_state == state) return;
    m_state = state;
    emit stateChanged(state);
}

Wallet *Controller::wallet() const
{
    return m_wallet;
}

void Controller::setWallet(Wallet *wallet)
{
    if (m_wallet == wallet)
        return;

    m_wallet = wallet;
    emit walletChanged(m_wallet);
}


void Controller::process(GA_json** output)
{
    while (true) {
        m_result = GA::auth_handler_get_result(m_auth_handler);
        emit resultChanged(m_result);

        QString status = m_result.value("status").toString();

        if (status == "done") {
            emit enterDone(m_result);
            if (output) *output = Json::fromObject(m_result.value("result").toObject());
            break;
        }

        if (status == "error") {
            qDebug("see error above");
            break;
        }

        if (status == "request_code") {
            emit codeRequested(result);
//            QJsonArray methods = result.value("methods").toArray();

//            Q_ASSERT(methods.size() > 0);

//            emit requestCode(result);
//            if (methods.size() == 1) {

//            } else for (auto method : methods) {
//                qDebug() << "METHODS: " << method.toString();
//            }
            break;
        }

        if (status == "resolve_code") {
            emit enterResolveCode();
            qDebug("should call prompt code and send with GA_auth_handler_resolve_code");
            break;
        }

        if (status == "call") {
            GA_auth_handler_call(m_auth_handler);
        }
    }
}

void Controller::reset()
{

}

void Controller::requestCode(const QByteArray& method)
{
    QMetaObject::invokeMethod(m_wallet->m_context, [this, method] {
        int res = GA_auth_handler_request_code(m_auth_handler, method.data());
        process(nullptr);
    });
    //QJsonObject result = GA::auth_handler_get_result(auth_handler);
}

void Controller::resolveCode(const QByteArray& code)
{
    QMetaObject::invokeMethod(m_wallet->m_context, [this, code] {
        int res = GA_auth_handler_resolve_code(m_auth_handler, code.data());
        Q_ASSERT(res == GA_OK);
        process(nullptr);
    });
}

void Controller::incrementBusy()
{
    m_busy ++;
    if (m_busy == 1) {
        emit busyChanged(true);
    }
}

void Controller::decrementBusy()
{
    Q_ASSERT(m_busy > 0);
    m_busy --;
    if (m_busy == 0) {
        emit busyChanged(false);
    }
}
