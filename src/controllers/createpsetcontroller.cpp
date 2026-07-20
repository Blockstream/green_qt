#include "account.h"
#include "context.h"
#include "controllers/createpsetcontroller.h"
#include "controllers/lwkamp2accountcontroller.h"
#include "lwk/lwk.hpp"
#include "network.h"

#include <QtConcurrentRun>

CreatePsetController::CreatePsetController(QObject* parent)
    : Controller(parent)
{
}

void CreatePsetController::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
}

void CreatePsetController::setAddress(const QString& address)
{
    if (m_address == address) return;
    m_address = address;
    emit addressChanged();
}

void CreatePsetController::setAmount(const QString& amount)
{
    if (m_amount == amount) return;
    m_amount = amount;
    emit amountChanged();
}

void CreatePsetController::setAssetId(const QString& asset_id)
{
    if (m_asset_id == asset_id) return;
    m_asset_id = asset_id;
    emit assetIdChanged();
}

void CreatePsetController::setBusy(bool busy)
{
    if (m_busy == busy) return;
    m_busy = busy;
    emit busyChanged();
}

void CreatePsetController::create()
{
    if (!context() || !m_account) {
        qWarning() << Q_FUNC_INFO << "missing context or account";
        return;
    }

    // Clear any error left over from a previous attempt so the QML
    // ErrorPane doesn't keep showing it through this one.
    m_error.clear();
    emit errorChanged();

    auto controller = context()->amp2AccountController();
    if (!controller) {
        m_error = "AMP2 wallet is not registered.";
        emit errorChanged();
        emit failed(m_error);
        return;
    }

    // Fail unless the account is wollet-backed (i.e. an AMP2 account with its
    // lwk wollet built); the wollet is required to build the spend PSET.
    auto wollet = controller->wollet();
    const auto address = m_address.trimmed();
    const auto amount = m_amount.toLongLong();
    const auto asset_id = m_asset_id;
    qDebug() << Q_FUNC_INFO << "building AMP2 send pset to" << address << "amount" << amount << "asset" << asset_id;

    if (!wollet) {
        m_error = "AMP2 wallet is not registered.";
        emit errorChanged();
        emit failed(m_error);
        return;
    }
    if (address.isEmpty() || amount <= 0) {
        m_error = "Invalid recipient or amount.";
        emit errorChanged();
        emit failed(m_error);
        return;
    }
    auto mutex = controller->mutex();

    setBusy(true);

    struct Result {
        bool ok{false};
        QString error;
        QString pset;
        qint64 fee{0};
        qint64 satoshi{0};
    };

    auto future = QtConcurrent::run(controller->threadPool(), [wollet, mutex, address, amount, asset_id, controller]() -> Result {
        Result result;
        std::lock_guard<std::mutex> lock(*mutex);
        try {
            // TODO: use the mainnet AMP2 network once mainnet support lands.
            auto network = lwk::Network::testnet();

            // Sync the shared wollet so the builder sees the wallet UTXOs.
            auto client = controller->getOrCreateWaterfallsClient();
            if (!client) {
                result.error = "Unable to reach the Waterfalls service.";
                return result;
            }
            auto update = client->full_scan(wollet);
            if (update) {
                wollet->apply_update(update);
            }

            auto lwk_address = lwk::Address::init(address.toStdString());
            auto builder = network->tx_builder();
            // 0.1 sat/vbyte = 100 sat/kvb, the Liquid minimum relay fee.
            builder->fee_rate(100.0f);
            const auto policy_asset = network->policy_asset();
            if (asset_id.isEmpty() || asset_id.toStdString() == policy_asset) {
                builder->add_lbtc_recipient(lwk_address, static_cast<uint64_t>(amount));
            } else {
                builder->add_recipient(lwk_address, static_cast<uint64_t>(amount), asset_id.toStdString());
            }

            auto pset = builder->finish(wollet);
            result.pset = QString::fromStdString(pset->to_string());

            const auto details = wollet->pset_details(pset);
            result.fee = static_cast<qint64>(details->balance()->fee());
            result.satoshi = amount;
            result.ok = true;
        } catch (const lwk::lwk_error::Generic& error) {
            qWarning() << "CreatePsetController::create: lwk error:" << error.msg;
            result.error = QString::fromStdString(error.msg);
        } catch (...) {
            qWarning() << "CreatePsetController::create: unexpected error";
            result.error = "Unexpected error creating AMP2 transaction.";
        }
        return result;
    });

    future.then(this, [=, this](Result result) {
        setBusy(false);
        if (!result.ok) {
            qDebug() << Q_FUNC_INFO << "failed:" << result.error;
            m_error = result.error;
            emit errorChanged();
            emit failed(m_error);
            return;
        }
        qDebug() << Q_FUNC_INFO << "pset created, fee" << result.fee;
        m_pset = result.pset;
        m_transaction = QJsonObject{
            { "address", address },
            { "satoshi", result.satoshi },
            { "fee", result.fee },
            { "asset_id", asset_id },
        };
        emit transactionChanged();
        emit created();
    });

    // The worker captures `controller` (a different QObject, owned by
    // Context, with no lifetime tie to this one) and dereferences it
    // (getOrCreateWaterfallsClient()); track the future on both objects so
    // neither's destructor can free its state out from under the worker —
    // this controller finishing its own teardown says nothing about whether
    // `controller` is still alive.
    controller->waitForFuture(future);
    waitForFuture(future);
}
