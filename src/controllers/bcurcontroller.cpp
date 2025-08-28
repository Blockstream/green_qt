#include "bcurcontroller.h"

#include "task.h"
#include "context.h"

BCURController::BCURController(QObject* parent)
    : Controller(parent)
{
}

void BCURController::setProgress(int progress)
{
    if (m_progress == progress) return;
    m_progress = progress;
    emit progressChanged();
}

void BCURController::process(const QString& data)
{
    if (!m_result.isEmpty()) return;

    if (m_seen.contains(data)) return;
    m_seen.insert(data);

    if (!data.startsWith("ur:", Qt::CaseInsensitive)) {
        emit dataDiscarded(data);
        if (m_task) {
            m_task->deleteLater();
            m_task = nullptr;
        }
        return;
    }

    if (!m_context) {
        setContext(new Context("mainnet", false, this));
    }

    if (!m_task) {
        auto session = m_context->primarySession();
        dispatcher()->add(new ConnectTask(session));

        m_task = new DecodeBCURTask(data, session);
        connect(m_task, &DecodeBCURTask::promptChanged, this, [=] {
            auto prompt = qobject_cast<CodePrompt*>(m_task->prompt());
            if (!prompt) return;

            connect(prompt, &CodePrompt::resultChanged, this, [=] {
                setProgress(prompt->result().value("auth_data").toObject().value("estimated_progress").toInt());
                next();
            });
            next();
        });
        connect(m_task, &DecodeBCURTask::resultChanged, this, [=] {
            next();
        });
        connect(m_task, &DecodeBCURTask::finished, this, [=] {
            m_result = m_task->decodedResult();
            emit resultDecoded(m_result);
            m_task->deleteLater();
            m_task = nullptr;
        });
        connect(m_task, &DecodeBCURTask::failed, this, [=] {
            emit dataDiscarded(data);
            m_task->deleteLater();
            m_task = nullptr;
        });
        dispatcher()->add(m_task);
    } else {
        m_pending.enqueue(data);
        next();
    }
}

void BCURController::next()
{
    if (!m_task) return;

    auto prompt = qobject_cast<CodePrompt*>(m_task->prompt());
    if (!prompt) return;

    if (m_pending.isEmpty()) return;

    const auto part = m_pending.dequeue();
    prompt->resolve(part);
}
