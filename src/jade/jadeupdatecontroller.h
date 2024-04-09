#ifndef GREEN_JADEUPDATECONTROLLER_H
#define GREEN_JADEUPDATECONTROLLER_H

#include "httprequestactivity.h"

#include <QtQml>
#include <QObject>

class Activity;
class JadeDevice;

class JadeHttpRequestActivity : public HttpRequestActivity
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeHttpRequestActivity(const QString& path, QObject* parent);
};

class JadeBinaryRequestActivity : public JadeHttpRequestActivity
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeBinaryRequestActivity(const QString& path, QObject* parent);
};

class JadeUnlockActivity : public SessionActivity
{
    Q_OBJECT
    Q_PROPERTY(JadeDevice* device READ device CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeUnlockActivity(JadeDevice* device, QObject* parent);
    JadeDevice* device() const { return m_device; }
private:
    void exec() override;
private:
    JadeDevice* const m_device;
};

class JadeUpdateActivity : public Activity
{
    Q_OBJECT
    Q_PROPERTY(JadeDevice* device READ device CONSTANT)
    Q_PROPERTY(QVariantMap firmware READ firmware CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeUpdateActivity(const QVariantMap& firmware, const QByteArray& data, JadeDevice* device);
    JadeDevice* device() const { return m_device; }
    QVariantMap firmware() const { return m_firmware; }
    void exec() override;
signals:
    void locked();
private:
    JadeDevice* const m_device;
    QVariantMap m_firmware;
    const QByteArray m_data;
    qlonglong m_uploaded{0};
};

class JadeFirmwareCheckController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(JadeDevice* device READ device WRITE setDevice NOTIFY deviceChanged)
    Q_PROPERTY(QJsonObject index READ index WRITE setIndex NOTIFY indexChanged)
    Q_PROPERTY(QVariantList firmwares READ firmwares NOTIFY firmwaresChanged)
    Q_PROPERTY(QVariant firmwareAvailable READ firmwareAvailable NOTIFY firmwareAvailableChanged)
    Q_PROPERTY(bool fetching READ fetching NOTIFY fetchingChanged)
    QML_ELEMENT
public:
    explicit JadeFirmwareCheckController(QObject *parent = nullptr);
    JadeDevice* device() const { return m_device; }
    void setDevice(JadeDevice* device);
    QJsonObject index() const { return m_index; }
    void setIndex(const QJsonObject& index);
    QVariantList firmwares() const { return m_firmwares; }
    QVariant firmwareAvailable() const { return m_firmware_available; }
    bool fetching() const { return m_fetching; }
    QVariant firmwareSelected() const { return m_firmware_selected; }
public slots:
    void check();
signals:
    void deviceChanged();
    void deviceDisconnected();
    void indexChanged();
    void firmwaresChanged();
    void firmwareAvailableChanged();
    void fetchingChanged();
    void updateStarted();
    void updateCompleted();
    void unlockRequired();
    void activityCreated(Activity* activity);
protected:
    void pushActivity(Activity* activity);
    void popActivity();
private:
    JadeDevice* m_device{nullptr};
    QJsonObject m_index;
    QString m_channel;
    QVariantList m_firmwares;
    QMap<QString, QByteArray> m_firmware_data;
    QVariant m_firmware_available;
    bool m_fetching{false};
    QVariant m_firmware_selected;
};


class JadeFirmwareUpdateController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(JadeDevice* device READ device WRITE setDevice NOTIFY deviceChanged)
    Q_PROPERTY(bool fetching READ fetching NOTIFY fetchingChanged)
    Q_PROPERTY(bool updating READ updating NOTIFY updatingChanged)
    Q_PROPERTY(float progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QVariantMap firmware READ firmware WRITE setFirmware NOTIFY firmwareChanged)
    QML_ELEMENT
public:
    explicit JadeFirmwareUpdateController(QObject* parent = nullptr);
    JadeDevice* device() const { return m_device; }
    void setDevice(JadeDevice* device);
    QVariantMap firmware() const { return m_firmware; }
    void setFirmware(const QVariantMap& firmware);
    bool fetching() const { return m_fetching; }
    bool updating() const { return m_updating; }
    float progress() const;
    void install(const QByteArray &data);
public slots:
    void update();
signals:
    void deviceChanged();
    void deviceDisconnected();
    void firmwareChanged();
    void fetchingChanged();
    void updatingChanged();
    void progressChanged();
    void updateStarted();
    void updateFinished();
    void updateFailed();
    void unlockRequired();
    void activityCreated(Activity* activity);
private:
    JadeDevice* m_device{nullptr};
    bool m_fetching{false};
    bool m_updating{false};
    bool m_started{false};
    float m_progress{0};
    QVariantMap m_firmware;
};

class JadeFirmwareController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool fetching READ fetching NOTIFY fetchingChanged)
    Q_PROPERTY(QJsonObject index READ index NOTIFY indexChanged)
    QML_ELEMENT
public:
    explicit JadeFirmwareController(QObject* parent = nullptr);
    bool isEnabled() const { return m_enabled; }
    void setEnabled(bool enabled);
    bool fetching() const { return m_fetching > 0; }
    QJsonObject index() const { return m_index; }
signals:
    void enabledChanged();
    void fetchingChanged();
    void indexChanged();
private:
    void check();
    void fetch(const QString& path);
    bool m_enabled{false};
    int m_fetching{0};
    QJsonObject m_index;
};

#endif // GREEN_JADEUPDATECONTROLLER_H
