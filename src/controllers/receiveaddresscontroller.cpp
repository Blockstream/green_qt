#include "account.h"
#include "handler.h"
#include "jadedevice.h"
#include "jadeapi.h"
#include "json.h"
#include "network.h"
#include "receiveaddresscontroller.h"
#include "resolver.h"
#include "session.h"
#include "util.h"
#include "wallet.h"

#include <gdk.h>
#include <wally_bip32.h>

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
        : Handler(account->wallet()->session())
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

void ReceiveAddressController::setAddressVerification(ReceiveAddressController::AddressVerification address_verification)
{
    if (m_address_verification == address_verification) return;
    m_address_verification = address_verification;
    emit addressVerificationChanged(m_address_verification);
}

void ReceiveAddressController::generate()
{
    if (!m_account || m_account->wallet()->isLocked()) return;

    if (m_generating) return;

    setGenerating(true);

    auto handler = new GetReceiveAddressHandler(m_account);
    connect(handler, &Handler::done, this, [this, handler] {
        m_result = handler->result().value("result").toObject();
        m_address = m_result.value("address").toString();
        setGenerating(false);
        setAddressVerification(VerificationNone);
        emit changed();
    });
    connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    handler->exec();
}

void ReceiveAddressController::verify()
{
    auto device = qobject_cast<JadeDevice*>(m_account->wallet()->device());
    Q_ASSERT(device);
    const auto network = m_account->wallet()->network();
    if (network->isElectrum()) {
        verifySinglesig();
    } else {
        verifyMultisig();
    }
}

void ReceiveAddressController::verifyMultisig() {
    Q_ASSERT(!m_generating);
    Q_ASSERT(m_address_verification != VerificationPending);
    setAddressVerification(VerificationPending);
    auto device = qobject_cast<JadeDevice*>(m_account->wallet()->device());
    Q_ASSERT(device);
    const quint32 subaccount = m_result.value("subaccount").toDouble();
    const quint32 branch = m_result.value("branch").toDouble();
    const quint32 pointer = m_result.value("pointer").toDouble();
    const quint32 subtype = m_result.value("subtype").toDouble();
    QByteArray recovery_xpub;

    // Jade expects any 'recoveryxpub' to be at the subact/branch level, consistent with tx outputs - but gdk
    // subaccount data has the base subaccount chain code and pubkey - so we apply the branch derivation here.
    const auto recovery_chain_code = ParseByteArray(m_account->json().value("recovery_chain_code"));
    if (recovery_chain_code.length() > 0) {
        const auto recovery_pub_key = ParseByteArray(m_account->json().value("recovery_pub_key"));
        const auto version = m_account->wallet()->network()->isMainnet() ? BIP32_VER_MAIN_PUBLIC : BIP32_VER_TEST_PUBLIC;

        ext_key subactkey, branchkey;
        char* base58;

        bip32_key_init(
            version, 0, 0,
            (const unsigned char *) recovery_chain_code.constData(), recovery_chain_code.size(),
            (const unsigned char *) recovery_pub_key.constData(), recovery_pub_key.size(),
            nullptr, 0,
            nullptr, 0,
            nullptr, 0,
            &subactkey);

        bip32_key_from_parent(&subactkey, branch, BIP32_FLAG_KEY_PUBLIC | BIP32_FLAG_SKIP_HASH, &branchkey);

        bip32_key_to_base58(&branchkey, BIP32_FLAG_KEY_PUBLIC, &base58);
        recovery_xpub = QByteArray(base58);
        wally_free_string(base58);
    }

    device->api()->getReceiveAddress(m_account->wallet()->network()->canonicalId(), subaccount, branch, pointer, recovery_xpub, subtype, [this](const QVariantMap& msg) {
        qDebug() << "jade: verify result" << msg;
        setAddressVerification(msg.contains("error") ? VerificationRejected : VerificationAccepted);
    });
}

void ReceiveAddressController::verifySinglesig()
{
    Q_ASSERT(!m_generating);
    Q_ASSERT(m_address_verification != VerificationPending);
    setAddressVerification(VerificationPending);
    auto device = qobject_cast<JadeDevice*>(m_account->wallet()->device());
    Q_ASSERT(device);
    const auto type = m_account->type();
    const auto path = ParsePath(m_result.value("user_path"));

    QString variant;
    if (type == "p2pkh") variant = "pkh(k)";
    if (type == "p2wpkh") variant = "wpkh(k)";
    if (type == "p2sh-p2wpkh") variant = "sh(wpkh(k))";

    device->api()->getReceiveAddress(m_account->wallet()->network()->canonicalId(), variant, path, [this](const QVariantMap& msg) {
        setAddressVerification(msg.contains("error") ? VerificationRejected : VerificationAccepted);
    });
}
