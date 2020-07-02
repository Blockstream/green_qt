#ifndef GREEN_DEVICEMANAGER_H
#define GREEN_DEVICEMANAGER_H

#include <QtQml>
#include <QObject>
#include <QQmlListProperty>
#include <QVector>

class Device;

class DeviceManager : public QObject
{
    Q_OBJECT
public:
    virtual ~DeviceManager();
    static DeviceManager* instance();

    virtual QList<Device*> devices() const;

signals:
    void deviceAdded(Device* device);
    void deviceRemoved(Device* device);

protected:
    explicit DeviceManager(QObject* parent = nullptr);
};

#endif // GREEN_DEVICEMANAGER_H
