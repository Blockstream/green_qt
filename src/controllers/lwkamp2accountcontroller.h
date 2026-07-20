#ifndef GREEN_LWKAMP2ACCOUNTCONTROLLER_H
#define GREEN_LWKAMP2ACCOUNTCONTROLLER_H

#include "controller.h"
#include "green.h"

#include <QFuture>
#include <QString>

#include <functional>
#include <memory>
#include <mutex>

class Account;
class LwkAmp2AccountControllerPrivate;
class QThreadPool;

namespace lwk {
struct Amp2;
struct Amp2Descriptor;
struct Wollet;
struct WaterfallsClient;
}

// Owns every lwk/AMP2 runtime object for one wallet: the wollet, the Waterfalls
// HTTP client, the descriptor subscription, and the background scan/poll loop
// that keeps the associated (synthetic) AMP2 Account's transactions/balance up
// to date. Account stays a plain data/model class; this is where all the lwk
// state and logic that used to live on it now lives instead.
//
// Instantiated lazily by Context::amp2AccountController() only once the wallet
// has a registered AMP2 wid (see Wallet::m_amp2_wid), mirroring the existing
// Context::lightningSession() lazy-accessor pattern. Parented to Context, so it
// is destroyed automatically with it. Extends Controller purely for its
// context()/setContext() property; it is never QML-instantiated.
class LwkAmp2AccountController : public Controller
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(LwkAmp2AccountController)
public:
    struct Amp2Derivation {
        bool ok{false};
        QString error;
        QString descriptor;
        std::shared_ptr<lwk::Amp2> amp2;
        std::shared_ptr<lwk::Amp2Descriptor> amp2_desc;
        // Wollet built from the descriptor (network-free); the caller hands it
        // to start() once registration/reload has produced it.
        std::shared_ptr<lwk::Wollet> wollet;
    };

    struct Amp2DetectResult {
        bool ok{false};
        QString error;
        // Whether the derived (unregistered) descriptor has any on-chain
        // balance/transaction history. amp2/wollet/wid are only set when true.
        bool has_history{false};
        QString wid;
        std::shared_ptr<lwk::Amp2> amp2;
        std::shared_ptr<lwk::Wollet> wollet;
    };

    // Network the AMP2 account lives on (matches the create button in QML).
    static Network* amp2Network();

    // This instance's dedicated pool for AMP2 lwk work: full scans, PSET
    // build/sign, and, in particular, the long-lived blocking Waterfalls
    // subscription loop in runSubscriptionLoop(). Kept off
    // QThreadPool::globalInstance() (and private to this controller, not
    // shared across AMP2 controllers) so a worker parked there for the whole
    // session (or a full scan) doesn't starve unrelated QtConcurrent work
    // elsewhere in the app. Every QtConcurrent::run() call touching this
    // controller's wollet/client should use it — see createpsetcontroller.cpp,
    // amp2signcontroller.cpp, createaccountcontroller.cpp and
    // loginwithpincontroller.cpp.
    QThreadPool* threadPool();

    explicit LwkAmp2AccountController(QObject* parent = nullptr);
    ~LwkAmp2AccountController() override;

    Account* account() const;
    std::shared_ptr<lwk::Amp2> amp2() const;

    // Pure lwk work (reads the mnemonic from context()->credentials()), safe
    // to run on a worker thread as long as context() has already been set.
    Amp2Derivation deriveAmp2() const;

    // lwk wollet backing the AMP2 account. Hand the returned shared_ptr to
    // worker threads — it keeps the wollet alive regardless of this
    // controller's lifetime. mutex() serialises the wollet ops
    // (full_scan/apply_update/finish/finalize) that mutate it.
    std::shared_ptr<lwk::Wollet> wollet() const;
    std::shared_ptr<std::mutex> mutex() const;

    // Waterfalls HTTP client. Lazily built on first use and cached here so
    // every AMP2 flow (transaction fetch, pset build/sign, descriptor
    // subscription) reuses one client instead of reconnecting every time.
    // Safe to call from any thread.
    std::shared_ptr<lwk::WaterfallsClient> getOrCreateWaterfallsClient();

    // Attaches a freshly derived (or reloaded) wollet/amp2 client, creates the
    // synthetic AMP2 Account if needed, triggers the first scan, and
    // subscribes to Waterfalls descriptor updates so fetchAmp2Transactions()
    // keeps re-scanning as new events arrive (the wollet has no gdk-style
    // chain notifications of its own).
    void start(std::shared_ptr<lwk::Wollet> wollet, std::shared_ptr<lwk::Amp2> amp2);

    // Reloads a previously-registered AMP2 account on login: derives the
    // wollet/amp2 client from the signer (the persisted wid already proves
    // registration, so no register_wallet call is needed) and start()s it.
    // See Context::amp2AccountController() / LoadController::loadAmp2().
    void load();

    // For a wallet with no persisted wid yet: derives the descriptor, scans
    // it (via Waterfalls) for any prior balance/transaction history, and
    // registers it with the AMP2 server (obtaining a wid) only if history is
    // found. Does NOT persist the wid or start() the account — the caller
    // does that, since it owns the Wallet/Context. Network I/O; call from a
    // worker thread. See LoadController::loadAmp2().
    Amp2DetectResult detectAndRegisterIfUsed();

    // Scans the wollet and refreshes the account's transactions/balance.
    // Called once up front by start() and then again every time
    // runSubscriptionLoop() receives a WaterfallsSubscriptionEvent. If a scan
    // is already running, this coalesces into a single follow-up scan rather
    // than dropping the request or piling up scans, so on_done (if given) is
    // only invoked once a scan that started at or after this call completes
    // — reliable for a caller that needs to look up a just-broadcast tx by
    // hash afterwards (see Amp2SignController::sign()). When full_scan
    // returns no update the model rebuild is skipped, unless `force` is set —
    // needed by callers that mutated the wollet outside full_scan (e.g.
    // apply_transaction after a broadcast) — or the model was never populated.
    void fetchAmp2Transactions(std::function<void()> on_done = nullptr, bool force = false);

private:
    // Subscribes to Waterfalls descriptor updates and drains events via
    // next_update(), calling fetchAmp2Transactions() for each one. Runs for
    // the controller's whole lifetime: on a failed subscribe, a thrown/closed
    // next_update(), it reconnects with a capped exponential backoff instead
    // of giving up, so a transient Waterfalls outage self-heals instead of
    // requiring a relogin. Stops for good only once the destructor sets
    // d->stopped (checked between/within backoff waits).
    void runSubscriptionLoop();
};

#endif // GREEN_LWKAMP2ACCOUNTCONTROLLER_H
