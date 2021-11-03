#ifndef GREEN_ACTIVITYMANAGER_H
#define GREEN_ACTIVITYMANAGER_H

#include <QMap>
#include <QObject>
#include <QStandardItemModel>

QT_FORWARD_DECLARE_CLASS(Activity)

class ActivityManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStandardItemModel* model READ model CONSTANT)
public:
    explicit ActivityManager(QObject *parent = nullptr);

    static ActivityManager* instance();

    QStandardItemModel* model() const { return m_model; }

    void exec(Activity* activity);

private:
    void insertActivity(Activity* activity);
    void removeActivity(Activity* activity);

private:
    QStandardItemModel* const m_model;
    QMap<Activity*, QStandardItem*> m_activities;
};

#endif // GREEN_ACTIVITYMANAGER_H
