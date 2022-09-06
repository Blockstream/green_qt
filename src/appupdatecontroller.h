#ifndef GREEN_APPUPDATECONTROLLER_H
#define GREEN_APPUPDATECONTROLLER_H

#include "httprequestactivity.h"

#include <QtQml>
#include <QObject>

class AppUpdateController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY latestVersionChanged)
    Q_PROPERTY(bool updateAvailable READ updateAvailable NOTIFY updateAvailableChanged)
    QML_ELEMENT
public:
    AppUpdateController(QObject* parent = nullptr);
    QString latestVersion() const { return m_latest_version; }
    bool updateAvailable() const { return m_update_available; }
public slots:
    void checkForUpdates();
signals:
    void latestVersionChanged(const QString& latest_version);
    void updateAvailableChanged(bool updateAvailable);
private:
    QString m_latest_version;
    bool m_update_available{false};
};

class CheckForUpdatesActivity : public HttpRequestActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    CheckForUpdatesActivity(QObject* parent);
    QString latestVersion() const;
};

#endif // GREEN_APPUPDATECONTROLLER_H
