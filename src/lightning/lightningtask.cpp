#include "context.h"
#include "lightningsession.h"
#include "lightningtask.h"

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
    if (!session) {
        setError(QStringLiteral("Lightning session is not available"));
        setStatus(Status::Failed);
        return;
    }

    const QPointer<LightningSession> session_guard(session);
    setStatus(Status::Active);

    auto future = session->connectNode(lightning_mnemonic).then(this, [=, this](const QString& error) {
        if (!session_guard) {
            setError(QStringLiteral("Lightning session is not available"));
            setStatus(Status::Failed);
            return;
        }
        if (!error.isEmpty()) {
            qWarning() << Q_FUNC_INFO << error;
            setError(error);
            setStatus(Status::Failed);
            return;
        }
        context()->setLightningEnabled(true);
        setStatus(Status::Finished);
    });

    waitForFuture(future);
}
