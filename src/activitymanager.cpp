#include "activity.h"
#include "activitymanager.h"

ActivityManager::ActivityManager(QObject *parent)
    : QObject(parent)
    , m_model(new QStandardItemModel(this))
{
    m_model->setItemRoleNames({
        { Qt::UserRole + 1, QByteArrayLiteral("activity") }
    });
}

ActivityManager* ActivityManager::instance()
{
    static ActivityManager manager;
    return &manager;
}

void ActivityManager::exec(Activity *activity)
{
    insertActivity(activity);
    connect(activity, &Activity::destroyed, [=] {
       removeActivity(activity);
    });
    activity->exec();
}

void ActivityManager::insertActivity(Activity* activity)
{
    auto item = new QStandardItem;
    item->setData(QVariant::fromValue(activity));
    m_activities.insert(activity, item);
    m_model->appendRow(item);
}

void ActivityManager::removeActivity(Activity* activity)
{
    auto item = m_activities.take(activity);
    Q_ASSERT(item);
    m_model->takeRow(item->row());
    delete item;
}
