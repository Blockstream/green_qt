#ifndef GREEN_JADEUPDATECONTROLLER_H
#define GREEN_JADEUPDATECONTROLLER_H

#include "httprequestactivity.h"

#include <QtQml>
#include <QObject>

QT_FORWARD_DECLARE_CLASS(Activity)
QT_FORWARD_DECLARE_CLASS(JadeDevice)

class JadeHttpRequestActivity : public HttpRequestActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    JadeHttpRequestActivity(const QString& path, QObject* parent);
};

class JadeChannelRequestActivity : public JadeHttpRequestActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    JadeChannelRequestActivity(const QString& base, const QString& channel, QObject* parent);
    QVariantList firmwares() const;
private:
    const QString m_base;
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
    Q_PROPERTY(QString channel READ channel WRITE setChannel NOTIFY channelChanged)
    Q_PROPERTY(QVariantList firmwares READ firmwares NOTIFY firmwaresChanged)
    Q_PROPERTY(QVariant firmwareAvailable READ firmwareAvailable NOTIFY firmwareAvailableChanged)
    QML_ELEMENT
public:
    explicit JadeUpdateController(QObject *parent = nullptr);
    JadeDevice* device() const { return m_device; }
    void setDevice(JadeDevice* device);
    QString channel() const { return m_channel; }
    void setChannel(const QString& channel);
    QVariantList firmwares() const { return m_firmwares; }
    QVariant firmwareAvailable() const { return m_firmware_available; }
public slots:
    void disconnectDevice();
    void check();
    void update(const QVariantMap& firmware);
    JadeUnlockActivity *unlock();
signals:
    void activityCreated(Activity* activity);
    void deviceChanged(JadeDevice* device);
    void channelChanged(QString channel);
    void firmwaresChanged(const QVariantList& firmwares);
    void firmwareAvailableChanged();
protected:
    void pushActivity(Activity* activity);
    void popActivity();
private:
    JadeDevice* m_device{nullptr};
    QString m_channel;
    QVariantList m_firmwares;
    QMap<QString, QByteArray> m_firmware_data;
    QVariant m_firmware_available;
};

#endif // GREEN_JADEUPDATECONTROLLER_H
