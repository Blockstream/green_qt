#include "context.h"
#include "lightningsession.h"
#include "lightningtask.h"
#include "wallet.h"

#include <QDebug>
#include <QPointer>

LightningConnectNodeTask::LightningConnectNodeTask(Context* context)
    : ContextTask(context)
{
}

void LightningConnectNodeTask::update()
{
    if (status() != Status::Ready) return;

    if (!context()->lightningEnabled()) {
        setStatus(Status::Finished);
        return;
    }

    const auto lightning_mnemonic = context()->lightningMnemonic().join(' ');
    if (lightning_mnemonic.trimmed().isEmpty()) {
        setStatus(Status::Finished);
        return;
    }

    auto session = context()->lightningSession();
    if (!session) {
        setStatus(Status::Finished);
        return;
    }

    const QPointer<LightningSession> session_guard(session);
    setStatus(Status::Active);

    auto future = session->connectNode(lightning_mnemonic).then(this, [=, this](const QString& error) {
        if (!session_guard) {
            setStatus(Status::Finished);
            return;
        }
        if (!error.isEmpty()) {
            qWarning() << Q_FUNC_INFO << error;
            setError(error);
        }
        // Lightning startup is best-effort: expose its error state without failing
        // the signup, restore, or wallet load task groups.
        setStatus(Status::Finished);
    });

    waitForFuture(future);
}

LightningEnableTask::LightningEnableTask(Context* context)
    : ContextTask(context)
{
}

void LightningEnableTask::update()
{
    setError({});

    if (status() != Status::Ready) return;

    if (context()->lightningEnabled()) {
        setStatus(Status::Finished);
        return;
    }

    const auto lightning_mnemonic = context()->lightningMnemonic().join(' ');
    if (lightning_mnemonic.trimmed().isEmpty()) {
        setError(QStringLiteral("Lightning mnemonic is not available"));
        setStatus(Status::Failed);
        return;
    }

    auto session = context()->lightningSession();
    auto wallet = context()->wallet();
    if (!session || !wallet) {
        setError(QStringLiteral("Lightning session is not available"));
        setStatus(Status::Failed);
        return;
    }

    const QPointer<LightningSession> session_guard(session);
    setStatus(Status::Active);

    // Gate registration of new nodes on LSP capacity; a cached true skips the network call.
    auto future = session->checkAvailability(lightning_mnemonic, wallet->lightningAvailable()).then(this, [=, this](const LightningValueResult<LightningAvailability>& result) {
        if (!session_guard) {
            setError(QStringLiteral("Lightning session is not available"));
            setStatus(Status::Failed);
            return;
        }
        if (!result) {
            qWarning() << Q_FUNC_INFO << result.error;
            setError(QStringLiteral("lightning_gate_failed"));
            setStatus(Status::Failed);
            return;
        }
        qInfo() << Q_FUNC_INFO << "node" << result.value->node_id << "available" << result.value->available;
        if (!result.value->available) {
            setError(QStringLiteral("lightning_at_capacity"));
            setStatus(Status::Failed);
            return;
        }
        connectNode(session, lightning_mnemonic, result.value->node_id);
    });

    waitForFuture(future);
}

void LightningEnableTask::connectNode(LightningSession* session, const QString& mnemonic, const QString& node_id)
{
    const QPointer<LightningSession> session_guard(session);
    auto future = session->connectNode(mnemonic).then(this, [=, this](const QString& error) {
        if (!session_guard) {
            setError(QStringLiteral("Lightning session is not available"));
            setStatus(Status::Failed);
            return;
        }
        if (session->state() != LightningSession::State::Connected) {
            qWarning() << Q_FUNC_INFO << error;
            setError(error);
            setStatus(Status::Failed);
            return;
        }
        // Connected with an error means listing payments failed, which is non-fatal.
        if (!error.isEmpty()) qWarning() << Q_FUNC_INFO << error;
        if (session->nodeInfo().value("id").toString().compare(node_id, Qt::CaseInsensitive) != 0) {
            session->disconnectNode();
            setError(QStringLiteral("Lightning node id mismatch"));
            setStatus(Status::Failed);
            return;
        }
        if (auto wallet = context()->wallet()) wallet->setLightningAvailable(true);
        context()->setLightningEnabled(true);
        setStatus(Status::Finished);
    });

    waitForFuture(future);
}
