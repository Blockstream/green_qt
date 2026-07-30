#include "account.h"
#include "context.h"
#include "controllers/lwkamp2accountcontroller.h"
#include "lwk/lwk.hpp"
#include "network.h"
#include "networkmanager.h"
#include "transaction.h"

#include <QThread>
#include <QThreadPool>
#include <QtConcurrentRun>

#include <algorithm>
#include <atomic>

class LwkAmp2AccountControllerPrivate : public ControllerPrivate
{
public:
    Account* account{nullptr};
    std::shared_ptr<lwk::Amp2> amp2;
    std::shared_ptr<lwk::Wollet> wollet;
    std::shared_ptr<std::mutex> mutex{std::make_shared<std::mutex>()};
    // Guards waterfalls_subscription: written from the subscription-loop
    // worker thread, read (and closed) from the destructor on the main
    // thread.
    std::mutex subscription_mutex;
    std::shared_ptr<lwk::WaterfallsSubscription> waterfalls_subscription;
    QFuture<void> poll_subscription_future;
    std::shared_ptr<lwk::WaterfallsClient> waterfalls_client;
    std::mutex waterfalls_client_mutex;
    // Set by the destructor so runSubscriptionLoop() stops reconnecting and
    // any in-progress backoff wait returns promptly instead of blocking
    // teardown.
    std::atomic<bool> stopped{false};
    // Guards against piling up scans when a fetch outlasts the time between
    // subscription events; a fetch requested while one is already running is
    // coalesced into amp2_fetch_pending/amp2_fetch_pending_callbacks instead
    // of being dropped.
    bool amp2_fetching{false};
    bool amp2_fetch_pending{false};
    // True if the coalesced follow-up scan must do a full model rebuild even
    // when full_scan returns no update (see fetchAmp2Transactions' force).
    bool amp2_fetch_pending_force{false};
    // Set once the account model has been populated from the wollet; until
    // then a scan must rebuild the model even if full_scan returns no update
    // (the wollet may already be up to date, e.g. after
    // detectAndRegisterIfUsed(), while the model is still empty).
    bool amp2_model_populated{false};
    QList<std::function<void()>> amp2_fetch_callbacks;
    QList<std::function<void()>> amp2_fetch_pending_callbacks;
    // This controller's own AMP2 work pool (see threadPool()); sized in the
    // constructor since QThreadPool isn't copyable/movable.
    QThreadPool thread_pool;
};

namespace {
// Sleeps up to total_ms, waking early (in step_ms increments) if `stopped`
// flips true, so shutdown doesn't have to wait out a long backoff.
void SleepUnlessStopped(const std::atomic<bool>& stopped, int total_ms)
{
    constexpr int step_ms = 200;
    int waited = 0;
    while (waited < total_ms && !stopped) {
        const int chunk = std::min(step_ms, total_ms - waited);
        QThread::msleep(chunk);
        waited += chunk;
    }
}
} // namespace

Network* LwkAmp2AccountController::amp2Network()
{
    return NetworkManager::instance()->network("electrum-testnet-liquid");
}

QThreadPool* LwkAmp2AccountController::threadPool()
{
    Q_D(LwkAmp2AccountController);
    return &d->thread_pool;
}

LwkAmp2AccountController::LwkAmp2AccountController(QObject* parent)
    : Controller(new LwkAmp2AccountControllerPrivate, parent)
{
    Q_D(LwkAmp2AccountController);
    // runSubscriptionLoop() parks one worker here for the whole session
    // (it blocks in next_update() until the subscription closes), so bump
    // past the default ideal-thread-count sizing to guarantee headroom for
    // full scans/signing to still run concurrently even on 1-2 core boxes.
    d->thread_pool.setMaxThreadCount(d->thread_pool.maxThreadCount() + 1);
}

LwkAmp2AccountController::~LwkAmp2AccountController()
{
    Q_D(LwkAmp2AccountController);
    // Order matters: flip stopped before closing, so runSubscriptionLoop()
    // sees it (and gives up on reconnecting) as soon as close_subscription()
    // unblocks whatever next_update() call it's parked in.
    d->stopped = true;
    {
        std::lock_guard<std::mutex> lock(d->subscription_mutex);
        if (d->waterfalls_subscription) {
            d->waterfalls_subscription->close_subscription();
        }
    }
    d->poll_subscription_future.waitForFinished();
}

Account* LwkAmp2AccountController::account() const
{
    Q_D(const LwkAmp2AccountController);
    return d->account;
}

std::shared_ptr<lwk::Amp2> LwkAmp2AccountController::amp2() const
{
    Q_D(const LwkAmp2AccountController);
    return d->amp2;
}

std::shared_ptr<lwk::Wollet> LwkAmp2AccountController::wollet() const
{
    Q_D(const LwkAmp2AccountController);
    return d->wollet;
}

std::shared_ptr<std::mutex> LwkAmp2AccountController::mutex() const
{
    Q_D(const LwkAmp2AccountController);
    return d->mutex;
}

LwkAmp2AccountController::Amp2Derivation LwkAmp2AccountController::deriveAmp2() const
{
    Amp2Derivation result;
    const auto mnemonic = context()->credentials().value("mnemonic").toString();
    if (mnemonic.isEmpty()) {
        result.error = "AMP2 derivation requires a software signer.";
        return result;
    }
    try {
        auto lwk_mnemonic = lwk::Mnemonic::init(mnemonic.toStdString());
        // TODO: use the mainnet AMP2 client once a server key/url is available.
        auto network = lwk::Network::testnet();
        auto signer = lwk::Signer::init(lwk_mnemonic, network);

        const auto user_xpub = signer->keyorigin_xpub(lwk::Bip::new_bip87());

        const std::string server_key = "[b805d768/87h/1h/0h]tpubDCYEgnLyCH2okSittQNNB8JHLwPgmoEAoKcMrJDHP9dFVamsadPAFJQ77C1htgR8ksie3VksLXoryng9AUaPZSF8FwTwEv6CaHp8j2YCrds";
        const std::string url = "https://amp.enterprise.blockstream.com";

        result.amp2 = lwk::Amp2::init(server_key, url);
        result.amp2_desc = result.amp2->descriptor_from_str(user_xpub, signer->slip77_master_blinding_key());
        result.descriptor = QString::fromStdString(result.amp2_desc->descriptor()->to_string());
        // Build the wollet here (network-free); the caller sets it on the
        // controller via start() and triggers the full scan.
        result.wollet = lwk::Wollet::init(network, result.amp2_desc->descriptor(), std::nullopt);
        result.ok = true;
    } catch (const lwk::lwk_error::Generic& error) {
        result.error = QString::fromStdString(error.msg);
    } catch (...) {
        result.error = "Unexpected error deriving AMP2 account.";
    }
    return result;
}

std::shared_ptr<lwk::WaterfallsClient> LwkAmp2AccountController::getOrCreateWaterfallsClient()
{
    Q_D(LwkAmp2AccountController);
    std::lock_guard<std::mutex> lock(d->waterfalls_client_mutex);
    if (!d->waterfalls_client) {
        try {
            // TODO: use the mainnet AMP2 network/waterfalls endpoint once mainnet support lands.
            auto network = lwk::Network::testnet();
            const std::string waterfalls_url = "https://waterfalls-elements-testnet.esplora.staging.blockstream.io:17771";
            d->waterfalls_client = lwk::WaterfallsClient::from_builder({
                .base_url = waterfalls_url,
                .network = network,
                .concurrency = 4
            });
        } catch (const lwk::lwk_error::Generic& error) {
            qWarning() << Q_FUNC_INFO << "waterfalls client init error:" << error.msg;
        } catch (...) {
            qWarning() << Q_FUNC_INFO << "waterfalls client init unexpected error";
        }
    }
    return d->waterfalls_client;
}

void LwkAmp2AccountController::start(std::shared_ptr<lwk::Wollet> wollet, std::shared_ptr<lwk::Amp2> amp2)
{
    Q_D(LwkAmp2AccountController);
    d->wollet = wollet;
    d->amp2 = amp2;

    if (!d->account) {
        d->account = context()->getOrCreateAmp2Account(amp2Network());
    }

    fetchAmp2Transactions();

    // Subscribe to Waterfalls descriptor updates so runSubscriptionLoop()
    // keeps calling fetchAmp2Transactions() as new events arrive. The loop
    // owns retrying/reconnecting itself (see its doc comment), so this is a
    // fire-and-forget kick-off, not a one-shot attempt.
    if (!d->wollet) return;
    runSubscriptionLoop();
}

void LwkAmp2AccountController::load()
{
    auto future = QtConcurrent::run(threadPool(), [this] {
        return deriveAmp2();
    });

    future.then(this, [this](Amp2Derivation derivation) {
        if (!derivation.ok) {
            qWarning() << Q_FUNC_INFO << "failed to reload AMP2 account:" << derivation.error;
            return;
        }
        // No register_wallet here: the persisted wid already proves registration.
        start(derivation.wollet, derivation.amp2);
    });

    waitForFuture(future);
}

LwkAmp2AccountController::Amp2DetectResult LwkAmp2AccountController::detectAndRegisterIfUsed()
{
    Amp2DetectResult result;
    auto derivation = deriveAmp2();
    if (!derivation.ok) {
        result.error = derivation.error;
        return result;
    }

    try {
        auto client = getOrCreateWaterfallsClient();
        if (!client) {
            result.error = "Unable to reach the Waterfalls service.";
            return result;
        }
        auto update = client->full_scan(derivation.wollet);
        if (update) {
            derivation.wollet->apply_update(update);
        }
        // One page of one is enough to know whether the account was ever used.
        auto balance = derivation.wollet->balance();
        bool has_nonzero_balance = std::any_of(balance.begin(), balance.end(), [](const auto& entry) {
            return entry.second != 0;
        });
        result.has_history = has_nonzero_balance
            || !derivation.wollet->transactions_paginated(0, 1).empty();
    } catch (const lwk::lwk_error::Generic& error) {
        result.error = QString::fromStdString(error.msg);
        return result;
    } catch (...) {
        result.error = "Unexpected error scanning AMP2 account history.";
        return result;
    }

    if (!result.has_history) {
        result.ok = true;
        return result;
    }

    try {
        result.wid = QString::fromStdString(derivation.amp2->register_wallet(derivation.amp2_desc));
    } catch (const lwk::lwk_error::Generic& error) {
        result.error = QString::fromStdString(error.msg);
        return result;
    } catch (...) {
        result.error = "Unexpected error registering AMP2 account.";
        return result;
    }

    result.amp2 = derivation.amp2;
    result.wollet = derivation.wollet;
    result.ok = true;
    return result;
}

void LwkAmp2AccountController::runSubscriptionLoop()
{
    Q_D(LwkAmp2AccountController);
    auto wollet = d->wollet;
    if (!wollet) return;

    d->poll_subscription_future = QtConcurrent::run(threadPool(), [wollet, this, d] {
        // Capped exponential backoff between (re)connect attempts. Reset to
        // the initial value once a subscription is actually established, so
        // a later drop starts backing off from scratch again.
        constexpr int kInitialBackoffMs = 1000;
        constexpr int kMaxBackoffMs = 30000;
        int backoff_ms = kInitialBackoffMs;

        while (!d->stopped) {
            std::shared_ptr<lwk::WaterfallsSubscription> subscription;
            try {
                if (auto client = getOrCreateWaterfallsClient()) {
                    subscription = client->subscribe(wollet->descriptor());
                }
            } catch (const lwk::lwk_error::Generic& error) {
                qWarning() << Q_FUNC_INFO << "waterfalls subscribe error:" << error.msg;
            } catch (...) {
                qWarning() << Q_FUNC_INFO << "waterfalls subscribe unexpected error";
            }

            if (!subscription) {
                if (d->stopped) break;
                qWarning() << Q_FUNC_INFO << "AMP2 subscribe failed, retrying in" << backoff_ms << "ms";
                SleepUnlessStopped(d->stopped, backoff_ms);
                backoff_ms = std::min(backoff_ms * 2, kMaxBackoffMs);
                continue;
            }

            {
                std::lock_guard<std::mutex> lock(d->subscription_mutex);
                d->waterfalls_subscription = subscription;
            }
            backoff_ms = kInitialBackoffMs;

            // Drain events until the subscription closes/errors, then loop
            // back around to reconnect (unless we're shutting down).
            while (!d->stopped) {
                std::optional<lwk::WaterfallsSubscriptionEvent> event;
                try {
                    event = subscription->next_update();
                } catch (const lwk::lwk_error::Generic& error) {
                    qWarning() << Q_FUNC_INFO << "waterfalls subscription error:" << error.msg;
                    break;
                } catch (...) {
                    qWarning() << Q_FUNC_INFO << "waterfalls subscription unexpected error";
                    break;
                }
                if (!event) {
                    qDebug() << Q_FUNC_INFO << "waterfalls subscription closed";
                    break;
                }
                if (event->tip) {
                    qDebug() << Q_FUNC_INFO << "waterfalls subscription event:" << QString::fromStdString(event->kind)
                        << "tip height:" << event->tip->height
                        << "tip block hash:" << QString::fromStdString(event->tip->block_hash)
                        << "tip timestamp:" << event->tip->timestamp;
                } else {
                    qDebug() << Q_FUNC_INFO << "waterfalls subscription event:" << QString::fromStdString(event->kind);
                }
                QMetaObject::invokeMethod(this, [this] { fetchAmp2Transactions(); }, Qt::QueuedConnection);
            }

            {
                std::lock_guard<std::mutex> lock(d->subscription_mutex);
                if (d->waterfalls_subscription == subscription) {
                    d->waterfalls_subscription.reset();
                }
            }

            if (d->stopped) break;
            qWarning() << Q_FUNC_INFO << "AMP2 subscription dropped, reconnecting in" << backoff_ms << "ms";
            SleepUnlessStopped(d->stopped, backoff_ms);
            backoff_ms = std::min(backoff_ms * 2, kMaxBackoffMs);
        }
    });
}

void LwkAmp2AccountController::fetchAmp2Transactions(std::function<void()> on_done, bool force)
{
    Q_D(LwkAmp2AccountController);
    auto wollet = d->wollet;
    qDebug() << Q_FUNC_INFO << "fetching AMP2 transactions, wollet ready:" << bool(wollet);
    if (!wollet) {
        qWarning() << Q_FUNC_INFO << "no AMP2 wollet, skipping transaction fetch";
        if (on_done) on_done();
        return;
    }
    // A scan can outlast the time between subscription events. Rather than
    // dropping a request that arrives mid-scan (which could permanently miss
    // an incoming tx/confirmation if no later event ever arrives), coalesce
    // it into a single follow-up scan: on_done is queued for whichever scan
    // runs next, guaranteeing it only fires once a scan that started at or
    // after this call has completed.
    if (d->amp2_fetching) {
        d->amp2_fetch_pending = true;
        d->amp2_fetch_pending_force |= force;
        if (on_done) d->amp2_fetch_pending_callbacks.append(std::move(on_done));
        qDebug() << Q_FUNC_INFO << "AMP2 fetch already in progress, queuing follow-up scan";
        return;
    }
    d->amp2_fetching = true;
    if (on_done) d->amp2_fetch_callbacks.append(std::move(on_done));
    auto mutex = d->mutex;
    auto account = d->account;
    // Safe to snapshot here: amp2_model_populated is only touched on the main
    // thread. When the model already mirrors the wollet and the caller didn't
    // force a rebuild (the post-broadcast refresh does, because
    // apply_transaction mutates the wollet outside full_scan), a scan that
    // yields no update can skip re-reading the wollet entirely.
    const bool can_skip = d->amp2_model_populated && !force;

    // A single wollet scan feeds both the transaction list and the balance, so
    // the AMP2 account exposes satoshi/balance like the gdk-backed accounts.
    struct ScanResult {
        bool success;
        bool skipped{false};
        QList<QJsonObject> transactions;
        QJsonObject balance;
    };
    auto future = QtConcurrent::run(threadPool(), [wollet, mutex, can_skip, this]() -> ScanResult {
        ScanResult result;
        result.success = false;
        std::lock_guard<std::mutex> lock(*mutex);
        try {
            auto client = getOrCreateWaterfallsClient();
            if (!client) {
                return result;
            }

            // Sync the shared wollet against the chain so transactions_paginated
            // has data to return.
            auto update = client->full_scan(wollet);
            if (update) {
                wollet->apply_update(update);
            } else if (can_skip) {
                // No update and the model already mirrors the wollet: nothing
                // to rebuild, skip the balance read and pagination.
                result.success = true;
                result.skipped = true;
                return result;
            }

            // Balance is an assetId -> satoshi map, same shape as gdk's "satoshi".
            for (const auto& [asset_id, amount] : wollet->balance()) {
                result.balance.insert(QString::fromStdString(asset_id), static_cast<qint64>(amount));
            }

            // Page through the wallet transactions the same way the gdk-backed
            // accounts do (see fetchTransactions), accumulating gdk-shaped JSON.
            constexpr uint32_t page_size = 30;
            for (uint32_t offset = 0;; offset += page_size) {
                const auto page = wollet->transactions_paginated(offset, page_size);
                for (const auto& wallet_tx : page) {
                    QJsonObject tx;
                    tx.insert("txhash", QString::fromStdString(wallet_tx->txid()->to_string()));
                    tx.insert("type", QString::fromStdString(wallet_tx->type()));
                    tx.insert("block_height", static_cast<qint64>(wallet_tx->height().value_or(0)));
                    const auto fee = wallet_tx->fee();
                    tx.insert("fee", static_cast<qint64>(fee));
                    // fee_rate is satoshi per 1000 vbytes (gdk convention, see util.js
                    // formatFeeRate). Use the discounted vsize, the basis for Liquid fees.
                    const auto vsize = wallet_tx->tx()->discount_vsize();
                    tx.insert("vsize", static_cast<qint64>(vsize));
                    if (vsize > 0) {
                        tx.insert("fee_rate", static_cast<qint64>(fee * 1000 / vsize));
                    }
                    const auto timestamp = wallet_tx->timestamp();
                    if (timestamp.has_value()) {
                        // created_at_ts is microseconds (see AccountTransaction::timestamp).
                        tx.insert("created_at_ts", static_cast<qint64>(timestamp.value()) * 1000000);
                    } else {
                        tx.insert("created_at_ts", static_cast<qint64>(QDateTime::currentSecsSinceEpoch() * 1000000));
                    }
                    QJsonObject satoshi;
                    for (const auto& [asset_id, amount] : wallet_tx->balance()) {
                        satoshi.insert(QString::fromStdString(asset_id), static_cast<qint64>(amount));
                    }
                    tx.insert("satoshi", satoshi);
                    result.transactions.append(tx);
                }
                if (page.size() < page_size) {
                    result.success = true;
                    break;
                }
            }
        } catch (const lwk::lwk_error::Generic& error) {
            qWarning() << "fetchAmp2Transactions: lwk error:" << error.msg;
        } catch (...) {
            qWarning() << "fetchAmp2Transactions: unexpected error";
        }
        return result;
    });

    future.then(this, [=, this](ScanResult result) {
        if (result.success && result.skipped) {
            qDebug() << Q_FUNC_INFO << "AMP2 scan returned no update, model unchanged";
        } else if (result.success) {
            qDebug() << Q_FUNC_INFO << "AMP2 scan returned" << result.transactions.size()
                     << "transactions, balance" << result.balance;
            account->setBalanceData(result.balance);
            account->beginFetchTransactions();
            for (const auto& data : result.transactions) {
                auto transaction = account->getOrCreateTransaction(data);
                account->touchTransaction(transaction->hash());
            }
            account->endFetchTransactions();
            // The first successful scan means the AMP2 account has loaded its
            // data at least once, same as Account::setSynced(true) for
            // gdk-backed accounts (see Context::getOrCreateSession) — gates
            // the loading spinner in AccountDelegate.qml/WalletViewHeader.qml.
            account->setSynced(true);
            d->amp2_model_populated = true;
        }

        // Snapshot this scan's own waiters, then check whether a follow-up
        // scan is needed for anything that arrived while this one was
        // running (see the amp2_fetching branch above).
        auto callbacks = d->amp2_fetch_callbacks;
        d->amp2_fetch_callbacks.clear();
        d->amp2_fetching = false;

        if (d->amp2_fetch_pending) {
            d->amp2_fetch_pending = false;
            d->amp2_fetch_callbacks = d->amp2_fetch_pending_callbacks;
            d->amp2_fetch_pending_callbacks.clear();
            const bool pending_force = d->amp2_fetch_pending_force;
            d->amp2_fetch_pending_force = false;
            fetchAmp2Transactions(nullptr, pending_force);
        }

        for (auto& callback : callbacks) {
            callback();
        }
    });

    // The worker captures this/d (getOrCreateWaterfallsClient() touches d),
    // so this controller's own destructor must block on it before d is
    // freed — otherwise a scan outlasting a logout/wallet-switch is a UAF.
    waitForFuture(future);
}
