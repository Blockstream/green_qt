#include "ga.h"
#include "handler.h"

#include <gdk.h>

// TODO ditch controller, receive parent and session?
Handler::Handler(QObject* parent) : QObject(parent) { }

Handler::~Handler()
{
    if (m_handler) GA_destroy_auth_handler(m_handler);
}

void Handler::exec()
{
    Q_ASSERT(m_handler);
    for (;;) {
        const auto result = GA::auth_handler_get_result(m_handler);
        const auto status = result.value("status").toString();

        if (status == "call") {
            int res = GA_auth_handler_call(m_handler);
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
                int err = GA_auth_handler_request_code(m_handler, method.toLocal8Bit().constData());
                Q_ASSERT(err == GA_OK);
                continue;
            } else {
                setResult(result);
                return emit requestCode();
            }
        }

        if (status == "resolve_code") {
            const auto action = result.value("action").toString();
            if (action == "get_xpubs") {
                Q_ASSERT(m_paths.empty());
                for (auto path : result.value("required_data").toObject().value("paths").toArray()) {
                    QVector<uint32_t> p;
                    for (auto x : path.toArray()) {
                        p.append(x.toDouble());
                    }
                    m_paths.append(p);
                }

                setResult(result);
                return emit resolveCode();
            }

            // if (action == "enable_2fa" || action == "enable_sms" || action == "disable_2fa")
            {
                const auto current_method = result.value("method").toString();
                const auto previous_method = m_result.value("method").toString();
                setResult(result);
                if (previous_method == current_method) {
                    return emit invalidCode();
                } else {
                    return emit resolveCode();
                }
            }
        }

        qDebug() << result;
        Q_UNREACHABLE();
    }
}

void Handler::request(const QByteArray& method)
{
    Q_ASSERT(m_handler);
    Q_ASSERT(m_result.value("status").toString() == "request_code");
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
    Q_ASSERT(m_result.value("status").toString() == "resolve_code");
    int res = GA_auth_handler_resolve_code(m_handler, data.constData());
    Q_ASSERT(res == GA_OK);
    exec();
}

void Handler::setResult(const QJsonObject& result)
{
    m_result = result;
    emit resultChanged(m_result);
}
