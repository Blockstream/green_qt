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

NotificationsController::NotificationsController(QObject* parent)
    : Controller{parent}
    , m_model{new QStandardItemModel(this)}
{
    connect(this, &Controller::contextChanged, this, &NotificationsController::reset);
    m_model->setItemRoleNames({{ Qt::UserRole + 1, "notification" }});
}

void NotificationsController::reset()
{
    m_model->clear();
    while (!m_items.isEmpty()) {
        delete m_items.take(m_items.firstKey());
    }
    if (m_context) {
        connect(m_context, &Context::notificationAdded, this, [=](Notification* notification) {
            auto item = new QStandardItem();
            item->setData(QVariant::fromValue(notification));
            m_items.insert(notification, item);
            m_model->insertRow(0, item);
        });
        connect(m_context, &Context::notificationRemoved, this, [=](Notification* notification) {
            auto item = m_items.take(notification);
            if (!item) return;
            m_model->takeRow(item->row());
            delete item;
        });
        for (auto notification : m_context->getNotifications()) {
            auto item = new QStandardItem();
            item->setData(QVariant::fromValue(notification));
            m_items.insert(notification, item);
            m_model->insertRow(0, item);
        }
    }
}

void NotificationsController::updateSeen()
{
    for (auto notification : m_items.keys()) {
        notification->setSeen(true);
    }
}

NotificationsModel::NotificationsModel(QObject* parent)
    : QSortFilterProxyModel{parent}
{
}

void NotificationsModel::setSource(QStandardItemModel* source)
{
    if (m_source == source) return;
    m_source = source;
    emit sourceChanged();
    setSourceModel(source);
}

