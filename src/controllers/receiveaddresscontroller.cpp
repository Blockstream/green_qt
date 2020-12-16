#include "receiveaddresscontroller.h"
#include "account.h"
#include "handler.h"
#include "json.h"
#include "network.h"
#include "resolver.h"
#include "wallet.h"

#include <gdk.h>

class GetReceiveAddressHandler : public Handler
{
    Account* const m_account;
    void call(GA_session* session, GA_auth_handler** auth_handler) override
    {
        auto address_details = Json::fromObject({
            { "subaccount", static_cast<qint64>(m_account->pointer()) },
        });

        int err = GA_get_receive_address(session, address_details.get(), auth_handler);
        Q_ASSERT(err == GA_OK);
    }
public:
    GetReceiveAddressHandler(Account* account)
        : Handler(account->wallet())
        , m_account(account)
    {
    }
};

ReceiveAddressController::ReceiveAddressController(QObject *parent) : QObject(parent)
{

}

ReceiveAddressController::~ReceiveAddressController()
{
    if (m_account) {
        QMetaObject::invokeMethod(m_account->wallet()->m_context, [] {}, Qt::BlockingQueuedConnection);
    }
}

Account *ReceiveAddressController::account() const
{
    return m_account;
}

void ReceiveAddressController::setAccount(Account *account)
{
    if (m_account == account) return;

    m_account = account;
    emit accountChanged(m_account);

    generate();
}

QString ReceiveAddressController::amount() const
{
    return m_amount;
}

void ReceiveAddressController::setAmount(const QString& amount)
{
    if (m_amount == amount) return;
    m_amount = amount;
    emit changed();
}

QString ReceiveAddressController::address() const
{
    return m_address;
}

QString ReceiveAddressController::uri() const
{
    if (!m_account || m_generating) return {};
    const auto wallet = m_account->wallet();
    auto unit = wallet->settings().value("unit").toString();
    unit = unit == "\u00B5BTC" ? "ubtc" : unit.toLower();
    auto amount = m_amount;
    amount.replace(',', '.');
    amount = wallet->convert({{ unit, amount }}).value("btc").toString();
    if (amount.toDouble() > 0) {
        return QString("%1:%2?amount=%3")
                .arg(wallet->network()->data().value("bip21_prefix").toString())
                .arg(m_address)
                .arg(amount);
    } else {
        return m_address;
    }
}

bool ReceiveAddressController::generating() const
{
    return m_generating;
}

void ReceiveAddressController::setGenerating(bool generating)
{
    if (m_generating == generating) return;
    m_generating = generating;
    emit generatingChanged(m_generating);
}

void ReceiveAddressController::generate()
{
    if (!m_account || m_account->wallet()->isLocked()) return;

    if (m_generating) return;

    setGenerating(true);

    auto handler = new GetReceiveAddressHandler(m_account);
    connect(handler, &Handler::done, this, [this, handler] {
        m_address = handler->result().value("result").toObject().value("address").toString();
        setGenerating(false);
        emit changed();
    });
    connect(handler, &Handler::resolver, [](Resolver* resolver) {
        resolver->resolve();
    });
    handler->exec();
}
