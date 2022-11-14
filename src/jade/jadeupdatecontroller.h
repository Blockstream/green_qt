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
public:
    JadeHttpRequestActivity(const QString& path, QObject* parent);
};

class JadeBinaryRequestActivity : public JadeHttpRequestActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    JadeBinaryRequestActivity(const QString& path, QObject* parent);
};

class JadeUnlockActivity : public SessionActivity
{
    Q_OBJECT
    Q_PROPERTY(JadeDevice* device READ device CONSTANT)
    QML_ELEMENT
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

class JadeUpdateController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(JadeDevice* device READ device WRITE setDevice NOTIFY deviceChanged)
    Q_PROPERTY(QJsonObject index READ index WRITE setIndex NOTIFY indexChanged)
    Q_PROPERTY(QVariantList firmwares READ firmwares NOTIFY firmwaresChanged)
    Q_PROPERTY(QVariant firmwareAvailable READ firmwareAvailable NOTIFY firmwareAvailableChanged)
    Q_PROPERTY(bool fetching READ fetching NOTIFY fetchingChanged)
    Q_PROPERTY(bool updating READ updating NOTIFY updatingChanged)
    QML_ELEMENT
public:
    explicit JadeUpdateController(QObject *parent = nullptr);
    JadeDevice* device() const { return m_device; }
    void setDevice(JadeDevice* device);
    QJsonObject index() const { return m_index; }
    void setIndex(const QJsonObject& index);
    QVariantList firmwares() const { return m_firmwares; }
    QVariant firmwareAvailable() const { return m_firmware_available; }
    bool fetching() const { return m_fetching; }
    bool updating() const { return m_updating; }
    void install(const QVariantMap &firmware, const QByteArray &data);
public slots:
    void disconnectDevice();
    void check();
    void update(const QVariantMap& firmware);
    JadeUnlockActivity *unlock();
signals:
    void activityCreated(Activity* activity);
    void deviceChanged(JadeDevice* device);
    void indexChanged();
    void firmwaresChanged();
    void firmwareAvailableChanged();
    void fetchingChanged();
    void updatingChanged();
    void updateStarted();
    void updateCompleted();
protected:
    void pushActivity(Activity* activity);
    void popActivity();
private:
    JadeDevice* m_device{nullptr};
    QJsonObject m_index;
    QString m_channel;
    QString type;
    QVariantList m_firmwares;
    QMap<QString, QByteArray> m_firmware_data;
    QVariant m_firmware_available;
    bool m_fetching{false};
    bool m_updating{false};
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
