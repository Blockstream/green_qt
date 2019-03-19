#include "wallet.h"

#include <gdk.h>

Wallet::Wallet(QObject *parent) : QObject(parent)
{
    m_context->moveToThread(m_thread);
    m_thread->start();

    GA_create_session(&m_session);
}

Wallet::~Wallet()
{
    GA_destroy_session(m_session);
}


void Wallet::connect()
{
    QMetaObject::invokeMethod(m_context, [this] {
        int res = GA_connect(m_session, "testnet", GA_DEBUG);
        m_connected = res == GA_OK;
        emit connectedChanged(true);
    });
}
