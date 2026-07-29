#include "account.h"
#include "asset.h"
#include "context.h"
#include "controllers/createpsetcontroller.h"
#include "controllers/lwkamp2accountcontroller.h"
#include "convert.h"
#include "lwk/lwk.hpp"
#include "network.h"

#include <QtConcurrentRun>

CreatePsetController::CreatePsetController(QObject* parent)
    : Controller(parent)
    , m_recipient(new Recipient(this))
{
    connect(m_recipient, &Recipient::addressChanged, this, &CreatePsetController::invalidate);
    connect(m_recipient, &Recipient::greedyChanged, this, &CreatePsetController::invalidate);
    // Deliberately not Recipient::changed: while greedy the amount is an output
    // of the build rather than an input, so the write-back in create() must not
    // schedule another build.
    connect(m_recipient->convert(), &Convert::resultChanged, this, [this] {
        if (!m_recipient->isGreedy()) invalidate();
    });
}

void CreatePsetController::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
    m_recipient->convert()->setAccount(account);
    invalidate();
}

void CreatePsetController::setAsset(Asset* asset)
{
    if (m_asset == asset) return;
    m_asset = asset;
    emit assetChanged();
    m_recipient->convert()->setAsset(asset);
    invalidate();
}

void CreatePsetController::setBusy(bool busy)
{
    if (m_busy == busy) return;
    m_busy = busy;
    emit busyChanged();
}

void CreatePsetController::setErrorMessage(const QString& error)
{
    if (m_error == error) return;
    m_error = error;
    emit errorChanged();
}

void CreatePsetController::clearTransaction()
{
    if (m_pset.isEmpty() && m_transaction.isEmpty()) return;
    m_pset.clear();
    m_transaction = {};
    emit transactionChanged();
}

void CreatePsetController::invalidate()
{
    // Drop the pset built from the previous inputs straight away, so the UI
    // can't act on a stale one during the debounce window.
    clearTransaction();
    if (m_update_timer != -1) killTimer(m_update_timer);
    m_update_timer = startTimer(5);
}

void CreatePsetController::timerEvent(QTimerEvent* event)
{
    Controller::timerEvent(event);
    if (event->timerId() == m_update_timer) {
        killTimer(m_update_timer);
        m_update_timer = -1;
        create();
    }
}

void CreatePsetController::create()
{
    // Bump before any early return: whatever is in flight was built from inputs
    // that no longer apply, so its result must be dropped either way.
    const auto seq = ++m_seq;

    // Clear any error left over from a previous attempt so the QML
    // ErrorPane doesn't keep showing it through this one.
    setErrorMessage({});
    clearTransaction();

    const auto address = m_recipient->address().trimmed();
    const auto greedy = m_recipient->isGreedy();
    const auto amount = m_recipient->convert()->satoshi().toLongLong();

    // Incomplete input is the normal state while the user is still filling the
    // form in. Since create() now runs on every change, stay quiet rather than
    // flashing an error at them.
    if (!context() || !m_account || address.isEmpty() || (!greedy && amount <= 0)) {
        setBusy(false);
        return;
    }

    auto controller = context()->amp2AccountController();
    // Fail unless the account is wollet-backed (i.e. an AMP2 account with its
    // lwk wollet built); the wollet is required to build the spend PSET.
    auto wollet = controller ? controller->wollet() : nullptr;
    if (!controller || !wollet) {
        setBusy(false);
        setErrorMessage("AMP2 wallet is not registered.");
        emit failed(m_error);
        return;
    }

    const auto asset_id = m_asset ? m_asset->id() : QString();
    // An empty asset id means the policy asset, matching the builder call below.
    const bool policy_asset = asset_id.isEmpty()
        || asset_id == m_account->network()->policyAsset();
    if (greedy && !policy_asset) {
        // lwk can only drain the policy asset; the send all button is hidden
        // for other assets, so this is a backstop.
        setBusy(false);
        setErrorMessage("Send all is only available for L-BTC.");
        emit failed(m_error);
        return;
    }

    qDebug() << Q_FUNC_INFO << "building AMP2 send pset to" << address << "amount" << (greedy ? QStringLiteral("all") : QString::number(amount)) << "asset" << asset_id;

    auto mutex = controller->mutex();

    setBusy(true);

    struct Result {
        bool ok{false};
        QString error;
        QString pset;
        qint64 fee{0};
        qint64 satoshi{0};
    };

    // The wollet is kept synced by LwkAmp2AccountController's own scan, so this
    // only reads it under the shared mutex; no full_scan here.
    auto future = QtConcurrent::run(controller->threadPool(), [wollet, mutex, address, amount, greedy, policy_asset, asset_id]() -> Result {
        Result result;
        std::lock_guard<std::mutex> lock(*mutex);
        try {
            // TODO: use the mainnet AMP2 network once mainnet support lands.
            auto network = lwk::Network::testnet();

            auto lwk_address = lwk::Address::init(address.toStdString());
            auto builder = network->tx_builder();
            // 0.1 sat/vbyte = 100 sat/kvb, the Liquid minimum relay fee.
            builder->fee_rate(100.0f);
            if (greedy) {
                builder->drain_lbtc_wallet();        // select every L-BTC input
                builder->drain_lbtc_to(lwk_address); // send the excess to the recipient
            } else if (policy_asset) {
                builder->add_lbtc_recipient(lwk_address, static_cast<uint64_t>(amount));
            } else {
                builder->add_recipient(lwk_address, static_cast<uint64_t>(amount), asset_id.toStdString());
            }

            auto pset = builder->finish(wollet);
            result.pset = QString::fromStdString(pset->to_string());

            const auto details = wollet->pset_details(pset);
            const auto balance = details->balance();
            result.fee = static_cast<qint64>(balance->fee());
            if (greedy) {
                for (const auto& output : pset->outputs()) {
                    if (!output->asset().has_value() || !output->amount().has_value()) continue;
                    if (output->asset().value() != network->policy_asset()) continue;
                    if (output->amount().value() == result.fee) continue;
                    result.satoshi = output->amount().value();
                    break;
                }
            } else {
                result.satoshi = amount;
            }
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
        // A later create() has superseded this one; its result is what the
        // inputs now describe, so drop this one entirely.
        if (seq != m_seq) return;
        setBusy(false);
        if (!result.ok) {
            qDebug() << Q_FUNC_INFO << "failed:" << result.error;
            setErrorMessage(result.error);
            emit failed(m_error);
            return;
        }
        qDebug() << Q_FUNC_INFO << "pset created, fee" << result.fee;
        if (greedy) {
            // Publish the amount the drain actually resolved to, so the amount
            // field reflects what is being sent. Safe against a rebuild loop:
            // the convert is not wired to invalidate() while greedy.
            m_recipient->convert()->setInput({{ "satoshi", result.satoshi }});
        }
        m_pset = result.pset;
        m_transaction = QJsonObject{
            { "address", address },
            { "satoshi", result.satoshi },
            { "fee", result.fee },
            { "asset_id", asset_id },
        };
        emit transactionChanged();
    });

    // The worker only captures shared_ptrs, but it runs on `controller`'s
    // thread pool — a different QObject, owned by Context, with no lifetime tie
    // to this one. Track the future on both so neither destructor can tear down
    // state the worker is still using; this controller finishing its own
    // teardown says nothing about whether `controller` is still alive.
    controller->waitForFuture(future);
    waitForFuture(future);
}
