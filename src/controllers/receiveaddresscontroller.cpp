#include "account.h"
#include "address.h"
#include "asset.h"
#include "context.h"
#include "controllers/lwkamp2accountcontroller.h"
#include "convert.h"
#include "json.h"
#include "lwk/lwk.hpp"
#include "network.h"
#include "receiveaddresscontroller.h"
#include "resolver.h"
#include "task.h"

#include <QtConcurrentRun>

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

void ReceiveAddressController::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
    if (account) {
        setContext(account->context());
    }
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
    if (!m_account || m_generating || !m_address) return {};
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
    if (!context()) return;

    if (!m_account) return;

    if (m_generating) return;

    m_error.clear();
    emit errorChanged();

    setGenerating(true);

    if (m_account->isAmp2()) {
        generateAmp2();
        return;
    }

    const auto get_receive_address = new GetReceiveAddressTask(m_account);
    connect(get_receive_address, &Task::finished, this, [=, this] {
        const auto data = get_receive_address->result().value("result").toObject();
        m_address = m_account->getOrCreateAddress(data);

        setGenerating(false);
        emit changed();
        emit m_account->addressGenerated();
        get_receive_address->deleteLater();
    });
    connect(get_receive_address, &Task::failed, this, [=, this](const QString& error) {
        setGenerating(false);
        m_address = nullptr;
        m_error = error;
        emit errorChanged();
        emit changed();
        get_receive_address->deleteLater();
    });

    auto group = new TaskGroup(this);
    group->add(get_receive_address);
    dispatcher()->add(group);
    monitor()->add(group);
}

void ReceiveAddressController::generateAmp2()
{
    // Never derive addresses for an unregistered wallet: the AMP2 server is the
    // cosigner/watcher, so a wid (proof of registration) is required. The
    // wollet is owned by LwkAmp2AccountController and shared across the AMP2
    // flows.
    auto controller = context()->amp2AccountController();
    auto wollet = controller ? controller->wollet() : nullptr;
    if (!wollet) {
        setGenerating(false);
        m_address = nullptr;
        m_error = "AMP2 wallet is not registered.";
        emit errorChanged();
        emit changed();
        return;
    }
    auto mutex = controller->mutex();

    struct Result {
        bool ok{false};
        QString error;
        QString address;
        quint32 index{0};
    };

    auto future = QtConcurrent::run([wollet, mutex]() -> Result {
        Result result;
        std::lock_guard<std::mutex> lock(*mutex);
        try {
            // Returns the last unused address; whatever sync state the shared
            // wollet has (from a scan elsewhere) is reflected here.
            auto address_result = wollet->address(std::nullopt);
            result.address = QString::fromStdString(address_result->address()->to_string());
            result.index = address_result->index();
            result.ok = true;
        } catch (const lwk::lwk_error::Generic& error) {
            result.error = QString::fromStdString(error.msg);
        } catch (...) {
            result.error = "Unexpected error generating AMP2 address.";
        }
        return result;
    });

    future.then(this, [=, this](Result result) {
        setGenerating(false);
        if (!result.ok) {
            m_address = nullptr;
            m_error = result.error;
            emit errorChanged();
            emit changed();
            return;
        }
        m_address = m_account->getOrCreateAddress(QJsonObject{
            { "address", result.address },
            { "pointer", static_cast<qint64>(result.index) },
        });
        emit changed();
        emit m_account->addressGenerated();
    });

    waitForFuture(future);
}
