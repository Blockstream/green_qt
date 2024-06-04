#ifndef GREEN_APPUPDATECONTROLLER_H
#define GREEN_APPUPDATECONTROLLER_H

#include <QObject>
#include <QtQml>

#include "notification.h"

class UpdateNotification : public Notification
{
    Q_OBJECT
    Q_PROPERTY(QString version READ version CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    UpdateNotification(const QString& version, QObject* parent);
    QString version() const { return m_version; }
private:
    QString m_version;
};

class AppUpdateController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(UpdateNotification* notification READ notification NOTIFY notificationChanged)
    QML_ELEMENT
public:
    AppUpdateController(QObject* parent = nullptr);
    UpdateNotification* notification() const { return m_notification; }
private slots:
    void checkForUpdates();
    void checkNow();
signals:
    void notificationChanged();
private:
    QTimer* const m_timer;
    UpdateNotification* m_notification{nullptr};
};

#endif // GREEN_APPUPDATECONTROLLER_H
