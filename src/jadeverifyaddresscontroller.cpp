#include "account.h"
#include "address.h"
#include "context.h"
#include "jadedevice.h"
#include "jadeverifyaddresscontroller.h"
#include "network.h"


#include <gdk.h>
#include <wally_wrapper.h>
#include "jadedevice.h"
#include "jadeapi.h"
#include "util.h"



JadeVerifyAddressController::JadeVerifyAddressController(QObject* parent)
    : Controller(parent)
{
}

JadeVerifyAddressController::~JadeVerifyAddressController()
{
}

void JadeVerifyAddressController::setAddress(Address* address)
{
    if (m_address == address) return;
    m_address = address;
    emit addressChanged();
}

void JadeVerifyAddressController::setAddressVerification(JadeVerifyAddressController::AddressVerification address_verification)
{
    if (m_address_verification == address_verification) return;
    m_address_verification = address_verification;
    emit addressVerificationChanged();

    if (m_address_verification == JadeVerifyAddressController::VerificationAccepted) {
        Q_ASSERT(m_address);
        m_address->setVerified(true);
    }
}

void JadeVerifyAddressController::verify()
{
    if (!m_address) return;

    // TODO move device to context, device details stay on wallet
    const auto account = m_address->account();
    const auto context = account->context();
    const auto network = account->network();
    auto device = qobject_cast<JadeDevice*>(context->device());
    Q_ASSERT(device);
    if (network->isElectrum()) {
        verifySinglesig();
    } else {
        verifyMultisig();
    }
}

void JadeVerifyAddressController::verifyMultisig() {
    Q_ASSERT(m_address_verification != VerificationPending);
    setAddressVerification(VerificationPending);
    const auto account = m_address->account();
    const auto network = account->network();
    auto device = qobject_cast<JadeDevice*>(m_context->device());
    Q_ASSERT(device);
    const auto account_recovery_xpub = account->json().value("recovery_xpub").toString().toUtf8();
    const quint32 subaccount = m_address->data().value("subaccount").toDouble();
    const quint32 branch = m_address->data().value("branch").toDouble();
    const quint32 pointer = m_address->data().value("pointer").toInteger();
    const quint32 subtype = m_address->data().value("subtype").toDouble();
    QByteArray recovery_xpub;

    // Jade expects any 'recoveryxpub' to be at the subact/branch level, consistent with tx outputs - but gdk
    // subaccount data has the base subaccount recovery xpub - so we apply the branch derivation here.
    if (!account_recovery_xpub.isEmpty()) {
        ext_key subactkey, branchkey;
        char* base58;
        bip32_key_from_base58(account_recovery_xpub.constData(), &subactkey);
        bip32_key_from_parent(&subactkey, branch, BIP32_FLAG_KEY_PUBLIC | BIP32_FLAG_SKIP_HASH, &branchkey);
        bip32_key_to_base58(&branchkey, BIP32_FLAG_KEY_PUBLIC, &base58);
        recovery_xpub = QByteArray(base58);
        wally_free_string(base58);
    }

    if (device->api()) {
        QPointer<JadeVerifyAddressController> self{this};
        device->api()->getReceiveAddress(network->canonicalId(), subaccount, branch, pointer, recovery_xpub, subtype, [=](const QVariantMap& msg) {
            qDebug() << "jade: verify result" << msg;
            if (self) self->setAddressVerification(msg.contains("error") ? VerificationRejected : VerificationAccepted);
        });
    }
}

void JadeVerifyAddressController::verifySinglesig()
{
    if (m_address_verification == VerificationPending) return;
    setAddressVerification(VerificationPending);
    const auto account = m_address->account();
    const auto network = account->network();
    auto device = qobject_cast<JadeDevice*>(m_context->device());
    Q_ASSERT(device);
    const auto type = account->type();
    const auto path = ParsePath(m_address->data().value("user_path"));

    QString variant;
    if (type == "p2pkh") variant = "pkh(k)";
    if (type == "p2wpkh") variant = "wpkh(k)";
    if (type == "p2sh-p2wpkh") variant = "sh(wpkh(k))";
    Q_ASSERT(!variant.isEmpty());

    if (device->api()) {
        QPointer<JadeVerifyAddressController> self{this};
        device->api()->getReceiveAddress(network->canonicalId(), variant, path, [=](const QVariantMap& msg) {
            if (self) self->setAddressVerification(msg.contains("error") ? VerificationRejected : VerificationAccepted);
        });
    }
}
