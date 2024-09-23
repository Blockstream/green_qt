#include "account.h"
#include "address.h"
#include "asset.h"
#include "context.h"
#include "convert.h"
#include "json.h"
#include "network.h"
#include "receiveaddresscontroller.h"
#include "resolver.h"
#include "task.h"

ReceiveAddressController::ReceiveAddressController(QObject *parent)
    : SessionController(parent)
    , m_convert(new Convert(this))
{
    connect(m_convert, &Convert::outputChanged, this, &ReceiveAddressController::changed);
}

ReceiveAddressController::~ReceiveAddressController()
{
    setAccount(nullptr);
}

Account *ReceiveAddressController::account() const
{
    return m_account;
}

void ReceiveAddressController::setAccount(Account *account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
    m_convert->setAccount(m_account);
    generate();
}

void ReceiveAddressController::setAsset(Asset* asset)
{
    if (m_asset == asset) return;
    m_asset = asset;
    emit assetChanged();
    emit changed();
    m_convert->setAsset(m_asset);
}

QString ReceiveAddressController::uri() const
{
    if (!m_account || m_generating) return {};
    const auto context = m_account->context();
    const auto network = m_account->network();
    const auto wallet = context->wallet();
    const auto bip21_prefix = network->data().value("bip21_prefix").toString();
    const auto amount = m_convert->output().value("bip21_amount").toString();
    if (QLocale::c().toDouble(amount) > 0) {
        if (network->isLiquid()) {
            const auto asset_id = m_asset ? m_asset->id() : network->policyAsset();
            return QString("%1:%2?assetid=%3&amount=%4")
                .arg(bip21_prefix, m_address->address(), asset_id, amount);
        } else {
            return QString("%1:%2?amount=%3")
                .arg(bip21_prefix, m_address->address(), amount);
        }
    } else if (network->isLiquid() && m_asset && m_asset->id() != network->policyAsset()) {
        const auto asset_id = m_asset->id();
        return QString("%1:%2?assetid=%3")
            .arg(bip21_prefix, m_address->address(), asset_id);
    } else {
        return m_address->address();
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
    if (!m_account) return; // || m_account->context()->isLocked()) return;

    if (m_generating) return;

    setGenerating(true);
    const auto get_receive_address = new GetReceiveAddressTask(m_account);
    connect(get_receive_address, &Task::finished, this, [=] {
        const auto data = get_receive_address->result().value("result").toObject();
        m_address = m_account->getOrCreateAddress(data);

        setGenerating(false);
        emit changed();
        emit m_account->addressGenerated();
    });

    auto group = new TaskGroup(this);
    group->add(get_receive_address);
    dispatcher()->add(group);
    monitor()->add(group);
}
