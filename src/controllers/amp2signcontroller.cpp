#include "account.h"
#include "context.h"
#include "controllers/amp2signcontroller.h"
#include "controllers/lwkamp2accountcontroller.h"
#include "lwk/lwk.hpp"
#include "network.h"

#include <QPointer>
#include <QtConcurrentRun>

Amp2SignController::Amp2SignController(QObject* parent)
    : Controller(parent)
{
}

void Amp2SignController::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
}

void Amp2SignController::setPset(const QString& pset)
{
    if (m_pset == pset) return;
    m_pset = pset;
    emit psetChanged();
}

void Amp2SignController::setBusy(bool busy)
{
    if (m_busy == busy) return;
    m_busy = busy;
    emit busyChanged();
}

void Amp2SignController::sign()
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

    const auto pset_base64 = m_pset;
    auto wollet = controller->wollet();
    const auto mnemonic = context()->credentials().value("mnemonic").toString();
    const auto amp2 = controller->amp2();
    qDebug() << Q_FUNC_INFO << "signing AMP2 pset, has signer:" << !mnemonic.isEmpty() << "has amp2 client:" << bool(amp2);

    if (pset_base64.isEmpty() || !wollet || !amp2) {
        m_error = "AMP2 wallet is not ready to sign.";
        emit errorChanged();
        emit failed(m_error);
        return;
    }
    if (mnemonic.isEmpty()) {
        m_error = "AMP2 signing requires a software signer.";
        emit errorChanged();
        emit failed(m_error);
        return;
    }
    auto mutex = controller->mutex();

    setBusy(true);

    struct Result {
        bool ok{false};
        QString error;
        QString txhash;
    };

    // controller (LwkAmp2AccountController) has no lifetime tie to this
    // controller — guard the continuation's use of it below, since a logout/
    // wallet-switch could destroy it in the window between the worker
    // finishing and this continuation actually running.
    QPointer<LwkAmp2AccountController> controller_guard(controller);

    auto future = QtConcurrent::run(controller->threadPool(), [=, this]() -> Result {
        Result result;
        std::lock_guard<std::mutex> lock(*mutex);
        try {
            // TODO: use the mainnet AMP2 network once mainnet support lands.
            auto network = lwk::Network::testnet();
            auto lwk_mnemonic = lwk::Mnemonic::init(mnemonic.toStdString());
            auto signer = lwk::Signer::init(lwk_mnemonic, network);

            qDebug() << "SIGN";
            auto pset = lwk::Pset::init(pset_base64.toStdString());
            // User signs the asset/L-BTC inputs.
            pset = signer->sign(pset);
            qDebug() << "COSIGN";
            // AMP2 server cosigns to enforce its authorization rules.
            pset = amp2->cosign(pset);

            // Finalize against the shared (synced) wollet, then broadcast.
            auto client = controller->getOrCreateWaterfallsClient();
            if (!client) {
                result.error = "Unable to reach the Waterfalls service.";
                return result;
            }
            auto update = client->full_scan(wollet);
            if (update) {
                wollet->apply_update(update);
            }

            auto final_pset = wollet->finalize(pset);
            auto tx = final_pset->extract_tx();
            auto txid = client->broadcast(tx);
            // The indexer may not have picked up the broadcast tx yet, so
            // apply it to the wollet directly for immediate local visibility
            // (balance/transactions) ahead of the next full_scan.
            wollet->apply_transaction(tx);
            result.txhash = QString::fromStdString(txid->to_string());
            result.ok = true;
        } catch (const lwk::lwk_error::Generic& error) {
            qWarning() << "Amp2SignController::sign: lwk error:" << error.msg;
            result.error = QString::fromStdString(error.msg);
        } catch (const lwk::lwk_error::Amp2HttpError& error) {
            qWarning() << "Amp2SignController::sign: amp2 error"
                       << error.url
                       << error.status
                       << (error.body.has_value() ? error.body.value().c_str() : "no body");
            result.error = "AMP Cosign Error.";
        } catch (...) {
            qWarning() << "Amp2SignController::sign: unexpected error";
            result.error = "Unexpected error signing AMP2 transaction.";
        }
        return result;
    });

    future.then(this, [=, this](Result result) {
        if (!result.ok) {
            setBusy(false);
            qDebug() << Q_FUNC_INFO << "failed:" << result.error;
            m_error = result.error;
            emit errorChanged();
            emit failed(m_error);
            return;
        }
        qDebug() << Q_FUNC_INFO << "broadcast ok, txhash" << result.txhash;
        if (!controller_guard) {
            // AMP2 controller torn down (logout/wallet-switch) while signing
            // was in flight. The broadcast itself already succeeded (it ran
            // before this continuation), just skip the now-impossible
            // account refresh instead of dereferencing a dangling pointer.
            qWarning() << Q_FUNC_INFO << "AMP2 controller gone, skipping account refresh";
            setBusy(false);
            emit completed(result.txhash);
            return;
        }
        // Refresh the account's transaction list so the new spend shows up,
        // then signal completion — the caller looks the tx up by hash to
        // show it, so it needs to already be in the account by that point.
        // Stay busy until then: the pset was already broadcast, so letting
        // the confirm button re-enable here would allow a re-sign of spent
        // inputs, turning a successful send into a failure page.
        // The callback outlives this controller's future tracking (it is
        // queued on the AMP2 controller, whose lifetime is independent), so
        // guard `this` — the page can be closed while the refresh runs.
        QPointer<Amp2SignController> self(this);
        // Force the rebuild: apply_transaction mutated the wollet outside
        // full_scan, so a scan returning no update must still refresh the
        // model for the just-broadcast tx to be visible.
        controller_guard->fetchAmp2Transactions([self, result] {
            if (!self) return;
            self->setBusy(false);
            emit self->completed(result.txhash);
        }, /*force*/ true);
    });

    // The worker captures `controller` (a different QObject, owned by
    // Context, with no lifetime tie to this one) and dereferences it
    // (getOrCreateWaterfallsClient()); track the future on both objects so
    // neither's destructor can free its state out from under the worker.
    controller->waitForFuture(future);
    waitForFuture(future);
}
