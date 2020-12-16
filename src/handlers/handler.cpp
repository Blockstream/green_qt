#include "network.h"
#include "device.h"
#include "ga.h"
#include "handler.h"
#include "json.h"
#include "resolver.h"
#include "resolvers/signmessageresolver.h"
#include "wallet.h"

#include <gdk.h>

Handler::Handler(Wallet* wallet)
    : QObject(wallet)
    , m_wallet(wallet)
{
}

Handler::~Handler()
{
    if (m_auth_handler) GA_destroy_auth_handler(m_auth_handler);
}

Wallet* Handler::wallet() const
{
    return m_wallet;
}

void Handler::exec()
{
    Q_ASSERT(!m_auth_handler);
    QMetaObject::invokeMethod(m_wallet->m_context, [this] {
        call(m_wallet->m_session, &m_auth_handler);
        if (m_auth_handler) {
            step();
        } else {
            emit done();
        }
    }, Qt::QueuedConnection);
}

const QJsonObject& Handler::result() const
{
    Q_ASSERT(!m_result.empty());
    return m_result;
}

static QJsonObject getResult(GA_auth_handler* auth_handler)
{
    GA_json* output;
    int err = GA_auth_handler_get_status(auth_handler, &output);
    Q_ASSERT(err == GA_OK);
    const auto result = Json::toObject(output);
    err = GA_destroy_json(output);
    Q_ASSERT(err == GA_OK);
    return result;
}

void Handler::step()
{
    Q_ASSERT(m_auth_handler);
    for (;;) {
        const auto result = getResult(m_auth_handler);
        const auto status = result.value("status").toString();

        if (status == "call") {
            int res = GA_auth_handler_call(m_auth_handler);
            Q_ASSERT(res == GA_OK);
            continue;
        }

        if (status == "done") {
            setResult(result);
            return emit done();
        }

        if (status == "error") {
            setResult(result);
            return emit error();
        }

        if (status == "request_code") {
            const auto methods = result.value("methods").toArray();
            Q_ASSERT(methods.size() > 0);
            if (methods.size() == 1) {
                const auto method = methods.first().toString();
                int err = GA_auth_handler_request_code(m_auth_handler, method.toLocal8Bit().constData());
                Q_ASSERT(err == GA_OK);
                continue;
            } else {
                setResult(result);
                return emit requestCode();
            }
        }

        if (status == "resolve_code") {
            QMetaObject::invokeMethod(this, [this, result] {
                auto instance = createResolver(result);
                if (instance) emit resolver(instance);
            }, Qt::QueuedConnection);
            return;
        }

        qDebug() << result;
        Q_UNREACHABLE();
    }
}

void Handler::request(const QByteArray& method)
{
    Q_ASSERT(m_auth_handler);
    Q_ASSERT(m_result.value("status").toString() == "request_code");
    int res = GA_auth_handler_request_code(m_auth_handler, method.data());
    Q_ASSERT(res == GA_OK);
    QMetaObject::invokeMethod(m_wallet->m_context, [this] {
        step();
    });
}

Resolver* Handler::createResolver(const QJsonObject& result)
{
    const auto action = result.value("action").toString();
    if (action == "get_xpubs") {
        return new GetXPubsResolver(this, result);
    }
    if (action == "create_transaction") {
        return new BlindingKeysResolver(this, result);
    }
    if (action == "get_receive_address") {
        return new BlindingKeyResolver(this, result);
    }

    if (action == "get_balance" || action == "get_subaccounts" || action == "get_transactions") {
        return new BlindingNoncesResolver(this, result);
    }

    if (action =="sign_tx") {
        if (m_wallet->network()->isLiquid()) {
            return new SignLiquidTransactionResolver(this, result);
        } else {
            return new SignTransactionResolver(this, result);
        }
    }

    if (action == "sign_message") {
        return new SignMessageResolver(this, result);
    }

    const auto method = result.value("method");
    if (method == "email" || method == "sms" || method == "phone" || method == "gauth") {
        if (m_two_factor_resolver) {
            if (m_two_factor_resolver->method() == result.value("method").toString()) {
                m_two_factor_resolver->retry(result);
                return nullptr;
            }
        }
        m_two_factor_resolver = new TwoFactorResolver(this, result);
        return m_two_factor_resolver;
    }

    Q_UNREACHABLE();
}

void Handler::resolve(const QJsonObject& data)
{
    resolve(QJsonDocument(data).toJson(QJsonDocument::Compact));
}

void Handler::resolve(const QByteArray& data)
{
    Q_ASSERT(m_auth_handler);
    int res = GA_auth_handler_resolve_code(m_auth_handler, data.constData());
    Q_ASSERT(res == GA_OK);
    QMetaObject::invokeMethod(m_wallet->m_context, [this] {
        step();
    });
}

void Handler::setResult(const QJsonObject& result)
{
    m_result = result;
    emit resultChanged(m_result);
}
