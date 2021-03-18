#include "receiveaddresscontroller.h"
#include "account.h"
#include "handler.h"
#include "json.h"
#include "network.h"
#include "resolver.h"
#include "session.h"
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

#include "jadedevice.h"
#include "jadeapi.h"
void ReceiveAddressController::generate()
{
    if (!m_account || m_account->wallet()->isLocked()) return;

    if (m_generating) return;

    setGenerating(true);

    auto handler = new GetReceiveAddressHandler(m_account);
    connect(handler, &Handler::done, this, [this, handler] {
        const auto result = handler->result().value("result").toObject();
        m_address = result.value("address").toString();
        auto device = qobject_cast<JadeDevice*>(m_account->wallet()->device());
        if (device) {
            const quint32 subaccount = result.value("subaccount").toDouble();
            const quint32 branch = result.value("branch").toDouble();
            const quint32 pointer = result.value("pointer").toDouble();
            const quint32 subtype = result.value("subtype").toDouble();
            QByteArray recovery_xpub;
#if 0
            // Jade expects any 'recoveryxpub' to be at the subact/branch level, consistent with tx outputs - but gdk
            // subaccount data has the base subaccount chain code and pubkey - so we apply the branch derivation here.
            if (subaccount.getRecoveryChainCode() != null && subaccount.getRecoveryChainCode().length() > 0) {
                final Object subactkey = Wally.bip32_pub_key_init(
                    getNetwork().getVerPublic(), 0, 0,
                    subaccount.getRecoveryChainCodeAsBytes(), subaccount.getRecoveryPubKeyAsBytes());
                final Object branchkey = Wally.bip32_key_from_parent(subactkey, branch,
                                                                     Wally.BIP32_FLAG_KEY_PUBLIC |
                                                                     Wally.BIP32_FLAG_SKIP_HASH);
                recoveryxpub = Wally.bip32_key_to_base58(branchkey, Wally.BIP32_FLAG_KEY_PUBLIC);
                Wally.bip32_key_free(branchkey);
                Wally.bip32_key_free(subactkey);
            }
#endif
            device->m_jade->getReceiveAddress(m_account->wallet()->network()->id(), subaccount, branch, pointer, recovery_xpub, subtype, [](const QVariantMap& msg) {
                qDebug() << msg;
            });
        }
        setGenerating(false);
        emit changed();
    });
    connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    handler->exec();
}
