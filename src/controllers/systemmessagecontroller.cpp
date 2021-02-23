#include "systemmessagecontroller.h"
#include "resolver.h"
#include "resolvers/signmessageresolver.h"
#include "handler.h"
#include "wallet.h"
#include <gdk.h>

class AckSystemMessageHandler : public Handler
{
    QByteArray m_message;
    void call(GA_session* session, GA_auth_handler** auth_handler) override
    {
        int res = GA_ack_system_message(session, m_message.constData(), auth_handler);
        Q_ASSERT(res == GA_OK);
    }
public:
    AckSystemMessageHandler(Wallet* wallet, const QByteArray& message)
        : Handler(wallet)
        , m_message(message)
    {
    }
};

SystemMessageController::SystemMessageController(QObject *parent)
    : Controller(parent)
{
    connect(this, &Controller::walletChanged, this, [this](Wallet* wallet) {
        check();
        if (wallet) connect(wallet, &Wallet::authenticationChanged, this, &SystemMessageController::check);
    });
}

void SystemMessageController::clear()
{
    m_pending.clear();
    m_accepted.clear();
}

void SystemMessageController::check()
{
    if (!m_wallet) return;
    if (m_wallet->authentication() != Wallet::Authenticated) {
        clear();
        return;
    }
    // Don't fetch message if there's a pending message
    if (m_accepted.size() < m_pending.size()) return;

    char* raw;
    int res = GA_get_system_message(session(), &raw);
    if (res != GA_OK) return;
    QString text = QString::fromLocal8Bit(raw);
    GA_destroy_string(raw);

    if (text.isEmpty()) {
        emit empty();
        return;
    }

    m_pending.append(text);
    emit message(text);
}

void SystemMessageController::ack()
{
    if (!m_wallet) return;
    if (m_pending.size() == m_accepted.size()) return;

    auto text = m_pending.last();
    auto handler = new AckSystemMessageHandler(m_wallet, text.toLocal8Bit());
    connect(handler, &Handler::done, this, [this, handler, text] {
        m_accepted.append(text);
        handler->deleteLater();
        check();
    });
    connect(handler, &Handler::error, this, [handler] {
        handler->deleteLater();
        // TODO: handle failure to ack message
    });
    exec(handler);
}
