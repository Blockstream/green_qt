#ifndef GREEN_DEVICEMANAGER_H
#define GREEN_DEVICEMANAGER_H

#include <QObject>
#include <QSet>
#include <QtQml>
#include <QVector>

class Device;

class DeviceManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
public:
    virtual ~DeviceManager();
    static DeviceManager* instance();
    int count() const;
    QSet<Device*> devices() const;
    Device* deviceWithId(const QString& id);
public slots:
    void addDevice(Device* device);
    void removeDevice(Device* device);
signals:
    void countChanged();
    void deviceAdded(Device* device);
    void deviceRemoved(Device* device);
private:
    explicit DeviceManager(QObject* parent = nullptr);
    QSet<Device*> m_devices;
    QMap<QString, QSet<QByteArray>> m_xpubs;
};

#endif // GREEN_DEVICEMANAGER_H
