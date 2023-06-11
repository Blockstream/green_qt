#include "systemmessagecontroller.h"
#include "context.h"
#include "session.h"
#include "task.h"
#include "wallet.h"

#include <gdk.h>

#include <QtConcurrentRun>

SystemMessageController::SystemMessageController(QObject* parent)
    : Controller(parent)
{
    connect(this, &Controller::contextChanged, this, &SystemMessageController::check);
}

void SystemMessageController::setMessage(const QString& message)
{
    if (m_message == message) return;
    m_message = message;
    emit messageChanged();
}

void SystemMessageController::check()
{
    if (!m_context) return;

    if (!m_message.isEmpty()) return;

    if (m_dispatcher->isBusy()) return;

    auto network = m_context->wallet()->network();
    auto session = m_context->getOrCreateSession(network);
    m_dispatcher->add(new GetSystemMessageTask(session, this));

//    // Don't fetch message if there's a pending message
//    if (m_accepted.size() < m_pending.size()) return;

//    char* raw;
//    int res = GA_get_system_message(m_context->session()->m_session, &raw);
//    if (res != GA_OK) return;
//    QString text = QString::fromUtf8(raw);
//    GA_destroy_string(raw);

//    if (text.isEmpty()) {
//        emit empty();
//        return;
//    }

//    m_pending.append(text);
//    emit message(text);
}

void SystemMessageController::ack()
{
    if (!m_context) return;
    if (m_message.isEmpty()) return;

    auto network = m_context->wallet()->network();
    auto session = m_context->getOrCreateSession(network);
    m_dispatcher->add(new AckSystemMessageTask(session, this));

//    if (m_pending.size() == m_accepted.size()) return;

//    auto text = m_pending.last();
//    auto handler = new AckSystemMessageTask(text.toLocal8Bit(), m_context->session());
//    connect(handler, &Handler::done, this, [=] {
//        m_accepted.append(text);
//        handler->deleteLater();
//        check();
//    });
//    connect(handler, &Handler::error, this, [handler] {
//        handler->deleteLater();
//        // TODO: handle failure to ack message
//    });
//    exec(handler);
}

GetSystemMessageTask::GetSystemMessageTask(Session* session, SystemMessageController* controller)
    : SessionTask(session)
    , m_controller(controller)
{
}

void GetSystemMessageTask::update()
{
    if (status() != Status::Ready) return;

    if (!m_session->m_ready) return;

    setStatus(Status::Active);

    QtConcurrent::run([=] {
        char* message_text;
        const auto rc = GA_get_system_message(m_session->m_session, &message_text);
        const auto message = QString::fromUtf8(message_text);
        GA_destroy_string(message_text);
        return message;

//        if (rc == GA_OK) {
//            return QString();
//        const auto params = get_params(session);
//        const auto rc = GA_connect(session->m_session, Json::fromObject(params).get());
//        if (rc == GA_OK) return QString();
//        const auto error = gdk::get_thread_error_details();
//        return error.value("details").toString();
    }).then(this, [=](const QString& message) {
        m_controller->setMessage(message);
        setStatus(Status::Finished);
    });
}

AckSystemMessageTask::AckSystemMessageTask(Session* session, SystemMessageController* controller)
    : AuthHandlerTask(session)
    , m_controller(controller)
    , m_message(controller->message())
{
}

bool AckSystemMessageTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    const auto rc = GA_ack_system_message(session, m_message.toUtf8().constData(), auth_handler);
    return rc == GA_OK;
}

void AckSystemMessageTask::handleDone(const QJsonObject& result)
{
    m_controller->setMessage({});
    m_controller->check();
    AuthHandlerTask::handleDone(result);
}
