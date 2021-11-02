#include "network.h"
#include "device.h"
#include "devicemanager.h"
#include "ga.h"
#include "handler.h"
#include "json.h"
#include "resolver.h"
#include "resolvers/signmessageresolver.h"
#include "session.h"
#include "wallet.h"

#include <gdk.h>

#include <QtConcurrentRun>


static Connection* SessionConnection(Session* session)
{
    Q_ASSERT(session);
    Q_ASSERT(session->connection());
    return session->connection();
}

static Connection* WalletConnection(Wallet* wallet)
{
    Q_ASSERT(wallet);
    Q_ASSERT(wallet->session());
    Q_ASSERT(wallet->session()->connection());
    return wallet->session()->connection();
}

Handler::Handler(Wallet* wallet)
    : QFutureWatcher<void>(WalletConnection(wallet))
    , m_session(wallet->session())
    , m_wallet(wallet)
{
    connect(this, &Handler::finished, this, [this] {
        step();
    });
}

Handler::Handler(Session* session)
    : QFutureWatcher<void>(SessionConnection(session))
    , m_session(session)
    , m_wallet(nullptr)
{
    connect(this, &Handler::finished, this, [this] {
        step();
    });
}

Handler::~Handler()
{
    waitForFinished();
    if (m_auth_handler) GA_destroy_auth_handler(m_auth_handler);
}

Wallet* Handler::wallet() const
{
    Q_ASSERT(m_wallet);
    return m_wallet;
}

static QJsonObject getErrorDetails()
{
    GA_json* output;
    GA_get_thread_error_details(&output);
    const auto result = Json::toObject(output);
    GA_destroy_json(output);
    return result;
}

void Handler::exec()
{
    Q_ASSERT(!m_already_exec);
    m_already_exec = true;

    Q_ASSERT(!m_auth_handler);
    setFuture(QtConcurrent::run([this] {
        call(m_session->m_session, &m_auth_handler);
        m_error_details = getErrorDetails();
        if (!m_error_details.isEmpty()) {
            qDebug() << m_error_details;
        }
    }));
}

void Handler::fail()
{
    setResult({{ "status", "error" }});
    emit error();
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
    if (m_error_details.contains("details")) {
        setResult({
            { "status", "error" },
            { "error", m_error_details.value("details") }
        });
        return emit error();
    }

    if (!m_auth_handler) {
        return emit done();
    }

    for (;;) {
        const auto result = getResult(m_auth_handler);
        const auto status = result.value("status").toString();
        qDebug() << result;
        if (status == "call") {
            setFuture(QtConcurrent::run([this] {
                int res = GA_auth_handler_call(m_auth_handler);
                Q_ASSERT(res == GA_OK);
            }));
            return;
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
            auto instance = createResolver(result);
            if (instance) emit resolver(instance);
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
    step();
}

static Device* GetDeviceFromRequiredData(const QJsonObject& required_data)
{
    const auto device = required_data.value("device").toObject();
    const auto device_type = device.value("device_type").toString();
    Q_ASSERT(device_type == "hardware");
    const auto id = device.value("name").toString();
    return DeviceManager::instance()->deviceWithId(id);
}

Resolver* Handler::createResolver(const QJsonObject& result)
{
    if (result.contains("required_data")) {
        const auto required_data = result.value("required_data").toObject();
        auto device = GetDeviceFromRequiredData(required_data);
        Q_ASSERT(device);
        const auto action = required_data.value("action").toString();
        if (action == "get_xpubs") {
            return new GetXPubsResolver(this, device, result);
        }
        if (action == "get_blinding_public_keys") {
            return new BlindingKeysResolver(this, device, result);
        }
        if (action == "get_blinding_nonces") {
            return new BlindingNoncesResolver(this, device, result);
        }
        if (action =="sign_tx") {
            if (m_session->network()->isLiquid()) {
                return new SignLiquidTransactionResolver(this, device, result);
            } else {
                return new SignTransactionResolver(this, device, result);
            }
        }
        if (action == "sign_message") {
            return new SignMessageResolver(this, device, result);
        }
        if (action == "get_master_blinding_key") {
            return new GetMasterBlindingKeyResolver(this, device, result);
        }
        Q_UNREACHABLE();
    }
    const auto method = result.value("method").toString();
    if (m_two_factor_resolver && m_two_factor_resolver->method() == method) {
        m_two_factor_resolver->retry(result);
        return nullptr;
    }
    m_two_factor_resolver = new TwoFactorResolver(this, result);
    return m_two_factor_resolver;
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
    step();
}

void Handler::setResult(const QJsonObject& result)
{
    m_result = result;
    emit resultChanged(m_result);
}
