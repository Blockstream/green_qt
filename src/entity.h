#ifndef GREEN_ENTITY_H
#define GREEN_ENTITY_H

#include <QQmlListProperty>
#include <QtQml>

class Activity;

class Entity : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<Activity> activities READ activities NOTIFY activitiesChanged)
    QML_ELEMENT
public:
    Entity(QObject* parent = nullptr);
    QQmlListProperty<Activity> activities();
    bool hasActivities() const { return !m_activities.empty(); }
    void pushActivity(Activity* activity);
signals:
    void activitiesChanged();
    void activityCreated(Activity* activity);
private:
    QList<Activity*> m_activities;
};

#endif // GREEN_ENTITY_H
