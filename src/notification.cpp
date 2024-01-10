#include "context.h"
#include "notification.h"
#include "task.h"

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
    setMonitor(new TaskGroupMonitor(this));
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

NetworkNotification::NetworkNotification(Network* network, Context* context)
    : Notification{context}
    , m_network{network}
{
}

SystemNotification::SystemNotification(const QString& message, Network* network, Context* context)
    : NetworkNotification{network, context}
    , m_message{message}
{
    setDismissable(false);
}

void SystemNotification::setAccepted(bool accepted)
{
    if (m_accepted == accepted) return;
    m_accepted = accepted;
    emit acceptedChanged();
}

void SystemNotification::accept(TaskGroupMonitor* monitor)
{
    if (m_accepted || m_busy) return;
    setBusy(true);
    auto session = m_context->getOrCreateSession(m_network);
    auto ack = new AckSystemMessageTask(m_message, session);
    connect(ack, &Task::finished, this, [=] {
        ack->deleteLater();
        setAccepted(true);
        auto get = new GetSystemMessageTask(session);
        connect(get, &Task::failed, this, [=] {
            get->deleteLater();
            setBusy(false);
            setDismissable(true);
        });
        connect(get, &Task::finished, this, [=] {
            get->deleteLater();
            const auto message = get->message();
            if (!message.isEmpty()) {
                auto notification = new SystemNotification(message, m_network, m_context);
                m_context->addNotification(notification);
            }
            setBusy(false);
            setDismissable(true);
        });
        auto group = new TaskGroup(this);
        group->add(get);
        context()->dispatcher()->add(group);
        monitor->add(group);
    });
    connect(ack, &Task::failed, this, [=] {
        ack->deleteLater();
        setBusy(false);
    });
    auto group = new TaskGroup(this);
    group->add(ack);
    context()->dispatcher()->add(group);
    monitor->add(group);
}
