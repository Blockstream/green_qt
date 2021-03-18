#include "activity.h"
#include "entity.h"

Entity::Entity(QObject* parent)
    : QObject(parent)
{
}

QQmlListProperty<Activity> Entity::activities()
{
    return { this, &m_activities };
}

void Entity::pushActivity(Activity* activity)
{
    connect(activity, &Activity::destroyed, this, [this, activity] {
        m_activities.removeOne(activity);
        emit activitiesChanged();
    });
    m_activities.append(activity);
    emit activitiesChanged();
    emit activityCreated(activity);
}
