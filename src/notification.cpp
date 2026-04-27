#include "account.h"
#include "context.h"
#include "notification.h"
#include "output.h"
#include "session.h"
#include "task.h"

Notification::Notification(QObject* parent)
    : QObject{parent}
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

void Notification::trigger()
{
    emit triggered();
}

void Notification::dismiss()
{
    if (m_dismissable && !m_dismissed) {
        m_dismissed = true;
        emit dismissedChanged();
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
    if (!m_context) return;

    connect(m_context, &Context::notificationAdded, this, [=, this](Notification* notification) {
        auto item = new QStandardItem();
        item->setData(QVariant::fromValue(notification));
        m_items.insert(notification, item);
        m_model->insertRow(0, item);
    });
    connect(m_context, &Context::notificationRemoved, this, [=, this](Notification* notification) {
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

    for (auto session : m_context->getSessions()) {
        auto task = new GetSystemMessageTask(session);
        connect(task, &Task::finished, [=, this] {
            task->deleteLater();
            if (!task->message().isEmpty()) {
                auto notification = new SystemNotification(task->message(), session->network(), m_context);
                m_context->addNotification(notification);
            }
        });
        connect(task, &Task::failed, [=, this] {
            task->deleteLater();
        });
        dispatcher()->add(task);
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
    : ContextNotification{context}
    , m_network{network}
{
}

SystemNotification::SystemNotification(const QString& message, Network* network, Context* context)
    : NetworkNotification{network, context}
    , m_message{message}
{
    setDismissable(true);
}

void SystemNotification::setAccepted(bool accepted)
{
    if (m_accepted == accepted) return;
    m_accepted = accepted;
    emit acceptedChanged();
    if (m_accepted) dismiss();
}

void SystemNotification::accept(TaskGroupMonitor* monitor)
{
    if (m_accepted || m_busy) return;
    setBusy(true);
    auto session = m_context->getOrCreateSession(m_network);
    auto ack = new AckSystemMessageTask(m_message, session);
    connect(ack, &Task::finished, this, [=, this] {
        ack->deleteLater();
        setAccepted(true);
        auto get = new GetSystemMessageTask(session);
        connect(get, &Task::failed, this, [=, this] {
            get->deleteLater();
            setBusy(false);
            setDismissable(true);
        });
        connect(get, &Task::finished, this, [=, this] {
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
    connect(ack, &Task::failed, this, [=, this] {
        ack->deleteLater();
        setBusy(false);
    });
    auto group = new TaskGroup(this);
    group->add(ack);
    context()->dispatcher()->add(group);
    monitor->add(group);
}

TwoFactorResetNotification::TwoFactorResetNotification(Network* network, Context* context)
    : NetworkNotification(network, context)
{
}

TwoFactorExpiredNotification::TwoFactorExpiredNotification(Context* context)
    : ContextNotification(context)
{
    setDismissable(true);
}

QQmlListProperty<Account> TwoFactorExpiredNotification::accounts()
{
    return { this, &m_accounts };
}

void TwoFactorExpiredNotification::add(Output* output)
{
    if (m_outputs.contains(output)) return;
    m_outputs.insert(output);
    if (!m_accounts.contains(output->account())) {
        m_accounts.append(output->account());
        emit accountsChanged();
    }
}

void TwoFactorExpiredNotification::remove(Output* output)
{
    m_outputs.remove(output);
    for (auto o : m_outputs) {
        if (o->account() == output->account()) return;
    }
    m_accounts.removeOne(output->account());
    emit accountsChanged();
}

ContextNotification::ContextNotification(Context* context)
    : Notification{context}
    , m_context{context}
{
}

OutageNotification::OutageNotification(Context* context)
    : ContextNotification(context)
{
}

void OutageNotification::add(Network* network)
{
    if (!m_networks.contains(network)) {
        m_networks.append(network);
    }
}

void OutageNotification::remove(Network* network)
{
    m_networks.removeOne(network);
}

WarningNotification::WarningNotification(const QString& title, const QString& message, Network* network, Context* context)
    : NetworkNotification{network, context}
    , m_title{title}
    , m_message{message}
{
    setDismissable(true);
}

BackupNotification::BackupNotification(Context *context)
    : ContextNotification(context)
{
}
