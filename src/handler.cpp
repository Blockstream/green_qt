#include "ga.h"
#include "handler.h"
#include "controller.h"

#include <gdk.h>

namespace {
    const QMap<QString, Handler::Status> STATUS{
        { "done", Handler::Status::DONE },
        { "error", Handler::Status::ERROR },
        { "call", Handler::Status::CALL },
        { "request_code", Handler::Status::REQUEST_CODE },
        { "resolve_code", Handler::Status::RESOLVE_CODE },
    };
    const QMap<QString, Handler::Action> ACTION{
        { "create_transaction", Handler::Action::CREATE_TRANSACTION },
        { "get_xpubs", Handler::Action::GET_XPUBS },
        { "sign_tx", Handler::Action::SIGN_TX },
        { "sign_message", Handler::Action::SIGN_MESSAGE },
        { "enable_2fa", Handler::Action::ENABLE_2FA },
        { "enable_email", Handler::Action::ENABLE_EMAIL },
        { "change_tx_limits", Handler::Action::CHANGE_TX_LIMITS },
        { "send_raw_tx", Handler::Action::SEND_RAW_TX },
    };
}

Handler::Handler(Controller *controller)
    : QObject(controller)
    , m_controller(controller)
    , m_session(controller->session())
{
}

Handler::~Handler()
{
    if (m_handler) GA_destroy_auth_handler(m_handler);
}

void Handler::exec()
{
    Q_ASSERT(m_handler);
    for (;;) {
        m_result = GA::auth_handler_get_result(m_handler);
        emit resultChanged(m_result);

        setStatus(STATUS.value(m_result.value("status").toString(), Status::INVALID));
        setAction(ACTION.value(m_result.value("action").toString(), Action::INVALID));

        if (m_status == Status::DONE) {
            return emit done();
        }
        if (m_status == Status::ERROR) {
            return emit error();
        }
        if (m_status == Status::CALL) {
            int res = GA_auth_handler_call(m_handler);
            Q_ASSERT(res == GA_OK);
            continue;
        }
        if (m_status == Status::REQUEST_CODE) {
            QJsonArray methods = m_result.value("methods").toArray();
            Q_ASSERT(methods.size() > 0);
            if (methods.size() == 1) {
                const auto method = methods.first().toString();
                int err = GA_auth_handler_request_code(m_handler, method.toLocal8Bit().constData());
                Q_ASSERT(err == GA_OK);
                continue;
            } else {
                emit requestCode();
                return;
            }
        }
        if (m_status == Status::RESOLVE_CODE) {
            if (m_action == Action::GET_XPUBS) {
                Q_ASSERT(m_paths.empty());
                for (auto path : m_result.value("required_data").toObject().value("paths").toArray()) {
                    QVector<uint32_t> p;
                    for (auto x : path.toArray()) {
                        p.append(x.toDouble());
                    }
                    m_paths.append(p);
                }
            }
            emit resolveCode();
            return;
        }
        Q_UNREACHABLE();
    }
}

void Handler::request(const QByteArray& method)
{
    Q_ASSERT(m_handler);
    Q_ASSERT(m_status == Status::REQUEST_CODE);
    int res = GA_auth_handler_request_code(m_handler, method.data());
    Q_ASSERT(res == GA_OK);
    exec();
}

void Handler::resolve(const QJsonObject& data)
{
    resolve(QJsonDocument(data).toJson(QJsonDocument::Compact));
}

void Handler::resolve(const QByteArray& data)
{
    Q_ASSERT(m_handler);
    Q_ASSERT(m_status == Status::RESOLVE_CODE);
    int res = GA_auth_handler_resolve_code(m_handler, data.constData());
    Q_ASSERT(res == GA_OK);
    exec();
}

void Handler::setStatus(Handler::Status status)
{
    Q_ASSERT(status != Status::INVALID);
    if (m_status == status) return;
    m_status = status;
    emit statusChanged(m_status);
}

void Handler::setAction(Handler::Action action)
{
    Q_ASSERT(action != Action::INVALID);
    m_action = action;
}
