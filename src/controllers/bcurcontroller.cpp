#include "bcurcontroller.h"
#include "context.h"
#include "task.h"

namespace {

// Time allowed to complete a multipart scan, counted from the first UR fragment
constexpr int BCUR_SCAN_TIMEOUT = 5 * 60 * 1000;

// Upper bound of distinct codes accepted in a single scan, so that an animated
// QR with endless unique payloads can't grow memory without bound. Jade loops
// a fixed set of frames and shows each one for at least 270ms, so a legitimate
// scan sees at most ~1100 distinct codes within BCUR_SCAN_TIMEOUT
constexpr int BCUR_MAX_SEEN_PARTS = 2000;

} // namespace

BCURController::BCURController(QObject* parent)
    : Controller(parent)
{
    m_timeout_timer.setSingleShot(true);
    m_timeout_timer.setInterval(BCUR_SCAN_TIMEOUT);
    connect(&m_timeout_timer, &QTimer::timeout, this, [this] {
        reset();
        setError("data", "timeout");
    });
}

void BCURController::setProgress(int progress)
{
    if (m_progress == progress) return;
    m_progress = progress;
    emit progressChanged();
}

void BCURController::reset()
{
    dropTask();
    m_result = {};
    m_seen.clear();
    m_pending.clear();
    setProgress(0);
    clearErrors();
}

void BCURController::dropTask()
{
    m_timeout_timer.stop();
    if (!m_task) return;
    // Queued GDK continuations may still emit after the task is dropped
    if (auto prompt = m_task->prompt()) disconnect(prompt, nullptr, this, nullptr);
    disconnect(m_task, nullptr, this, nullptr);
    m_task->deleteLater();
    m_task = nullptr;
}

void BCURController::process(const QString& data)
{
    if (!m_result.isEmpty()) return;
    if (!noErrors()) return;

    if (m_seen.contains(data)) return;
    if (m_seen.size() >= BCUR_MAX_SEEN_PARTS) {
        reset();
        setError("data", "too_many_parts");
        return;
    }
    m_seen.insert(data);

    if (!data.startsWith("ur:", Qt::CaseInsensitive)) {
        emit dataDiscarded(data);
        dropTask();
        return;
    }

    if (!m_timeout_timer.isActive()) m_timeout_timer.start();

    if (!context()) {
        setContext(ContextManager::instance()->create("mainnet", false));
    }

    if (!m_task) {
        auto session = context()->primarySession();
        dispatcher()->add(new ConnectTask(session));

        m_task = new DecodeBCURTask(data, session);
        connect(m_task, &DecodeBCURTask::promptChanged, this, [=, this] {
            auto prompt = qobject_cast<CodePrompt*>(m_task->prompt());
            if (!prompt) return;

            connect(prompt, &CodePrompt::resultChanged, this, [=, this] {
                setProgress(prompt->result().value("auth_data").toObject().value("estimated_progress").toInt());
                next();
            });
            next();
        });
        connect(m_task, &DecodeBCURTask::resultChanged, this, [=, this] {
            next();
        });
        connect(m_task, &DecodeBCURTask::finished, this, [=, this] {
            m_result = m_task->decodedResult();
            emit resultDecoded(m_result);
            dropTask();
        });
        connect(m_task, &DecodeBCURTask::failed, this, [=, this] {
            emit dataDiscarded(data);
            dropTask();
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
