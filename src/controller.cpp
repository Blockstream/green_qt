#include "controller.h"
#include "json.h"
#include "wallet.h"

#include <QQmlContext>
#include <QQmlEngine>

#include <gdk.h>

Controller::Controller(QObject* parent)
    : QObject(parent)
{
}

QObject* Controller::context() const
{
    Wallet* w = wallet();
    return w ? w->m_context : nullptr;
}

GA_session* Controller::session() const
{
    Wallet* w = wallet();
    return w ? w->m_session : nullptr;
}

void Controller::setStatus(const QString &status)
{
    if (m_status == status) return;
    m_status = status;
    emit statusChanged(m_status);
}

void Controller::setResult(const QJsonObject &result)
{
    if (m_result == result) return;
    m_result = result;
    emit resultChanged(m_result);
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
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged(m_wallet);
}

void Controller::process()
{
    Q_ASSERT(thread() == QThread::currentThread());
    Q_ASSERT(m_auth_handler != nullptr);
    const auto result = GA::auth_handler_get_result(m_auth_handler);
    const auto status = result.value("status").toString();

    if (status == "done") {
        int err = GA_destroy_auth_handler(m_auth_handler);
        Q_ASSERT(err == GA_OK);
        m_auth_handler = nullptr;
    }

    // Update the controller with the new result
    const bool update_result = update(result);
    setStatus(status);
    if (update_result) setResult(result);
}

bool Controller::update(const QJsonObject& result)
{
    Q_ASSERT(thread() == QThread::currentThread());
    auto status = result.value("status").toString();

    if (status == "done") {
        return true;
    }

    if (status == "error") {
        return true;
    }

    Q_ASSERT(m_auth_handler);

    if (status == "call") {
        int err = GA_auth_handler_call(m_auth_handler);
        Q_ASSERT(err == GA_OK);
        QMetaObject::invokeMethod(this, [this] { process(); }, Qt::QueuedConnection);
        //process();
        return false;
    }

    if (status == "resolve_code") {
        if (m_status == status) {
            emit invalidCode();
        }
        return true;
    }

    if (status == "request_code") {
        QJsonArray methods = result.value("methods").toArray();
        Q_ASSERT(methods.size() > 0);

        if (methods.size() == 1) {
            int err = GA_auth_handler_request_code(m_auth_handler, methods.first().toString().toLatin1().constData());
            Q_ASSERT(err == GA_OK);
            QMetaObject::invokeMethod(this, [this] { process(); }, Qt::QueuedConnection);
            return false;
        }

        return true;
    }

    Q_UNREACHABLE();
}

void Controller::requestCode(const QByteArray& method)
{
    if (!context()) return;
    int res = GA_auth_handler_request_code(m_auth_handler, method.data());
    Q_ASSERT(res == GA_OK);
    process();
}

void Controller::resolveCode(const QByteArray& code)
{
    if (!context()) return;
    int res = GA_auth_handler_resolve_code(m_auth_handler, code.data());
    Q_ASSERT(res == GA_OK);
    process();
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
