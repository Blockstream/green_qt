#ifndef GREEN_DEVICEMANAGER_H
#define GREEN_DEVICEMANAGER_H

#include <QObject>
#include <QQmlListProperty>
#include <QVector>

class Device;

class DeviceManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QQmlListProperty<Device> devices READ devices NOTIFY devicesChanged)

public:
    explicit DeviceManager(QObject *parent = nullptr);

    QQmlListProperty<Device> devices();

    Device* findDevice(const QString& id) const;

signals:
    void devicesChanged();

public slots:

protected:
    QVector<Device*> m_devices;
};

#endif // GREEN_DEVICEMANAGER_H
