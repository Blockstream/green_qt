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
    QSet<Device*> devices() const;
public slots:
    void addDevice(Device* device);
    void removeDevice(Device* device);
signals:
    void deviceAdded(Device* device);
    void deviceRemoved(Device* device);
private:
    explicit DeviceManager(QObject* parent = nullptr);
    QSet<Device*> m_devices;
};

#endif // GREEN_DEVICEMANAGER_H
