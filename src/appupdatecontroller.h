#ifndef GREEN_APPUPDATECONTROLLER_H
#define GREEN_APPUPDATECONTROLLER_H

#include <QObject>
#include <QtQml>

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
private slots:
    void checkForUpdates();
    void checkNow();
signals:
    void latestVersionChanged();
    void updateAvailableChanged();
private:
    QTimer* const m_timer;
    QString m_latest_version;
    bool m_update_available{false};
};

#endif // GREEN_APPUPDATECONTROLLER_H
