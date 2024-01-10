#include "context.h"
#include "notification.h"

Notification::Notification(Context* context)
    : QObject{context}
    , m_context{context}
{
}

void Notification::setLevel(Notification::Level level)
{
    if (m_level == level) return;
    m_level = level;
    emit levelChanged();
}

void Notification::setSeen(bool seen)
{
    if (m_seen == seen) return;
    m_seen = seen;
    emit seenChanged();
}

void Notification::setBusy(bool busy)
{
    if (m_busy == busy) return;
    m_busy = busy;
    emit busyChanged();
}

void Notification::setDismissable(bool dismissable)
{
    if (m_dismissable == dismissable) return;
    m_dismissable = dismissable;
    emit dismissableChanged();
}

void Notification::dismiss()
{
    if (m_dismissable) {
        m_context->removeNotification(this);
    }
}

