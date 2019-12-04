#include "controller.h"
#include "../json.h"
#include "../wallet.h"
#include <QDebug>
#include <QQmlContext>
#include <QQmlEngine>

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
    if (m_wallet) return m_wallet;
    auto context = qmlContext(this);
    if (!context) return nullptr;
    return qobject_cast<Wallet*>(context->contextProperty("wallet").value<QObject*>());
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

        setState(status.toUpper());

        if (status == "done") {
            if (output) *output = Json::fromObject(m_result.value("result").toObject());
            break;
        }

        if (status == "error") {
            break;
        }

        if (status == "request_code") {
            QJsonArray methods = m_result.value("methods").toArray();
            Q_ASSERT(methods.size() > 0);
            if (methods.size() == 1) {
                int err = GA_auth_handler_request_code(m_auth_handler, methods.first().toString().toLatin1().constData());
                Q_ASSERT(err == GA_OK);
                continue;
            } else {
//                emit requestCode(result);
//                qDebug() << "METHODS: " << method.toString();
                break;
            }
        }

        if (status == "resolve_code") {
            qDebug("should call prompt code and send with GA_auth_handler_resolve_code");
            break;
        }

        if (status == "call") {
            GA_auth_handler_call(m_auth_handler);
            continue;
        }


        qDebug() << "UNHANDLED STATUS" << m_result;
        break;
    }
}

void Controller::reset()
{

}

void Controller::cancel()
{
    Q_ASSERT(m_auth_handler);
    int err = GA_destroy_auth_handler(m_auth_handler);
    Q_ASSERT(err == GA_OK);
    m_auth_handler = nullptr;
    setState({});
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
    QMetaObject::invokeMethod(wallet()->m_context, [this, code] {
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
