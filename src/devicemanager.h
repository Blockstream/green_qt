#ifndef DEVICEMANAGER_H
#define DEVICEMANAGER_H

#include <QObject>
#include <QQmlListProperty>
#include <QVector>

class Device : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap properties READ properties NOTIFY propertiesChanged)

public:
    explicit Device(QObject *parent = nullptr) : QObject(parent) {}

    QString id;

    QVariantMap m_properties;
    QVariantMap properties() const { return m_properties; }

signals:
    void propertiesChanged();

};


class LedgerNanoXDevice : public Device
{
    Q_OBJECT

public:
    explicit LedgerNanoXDevice(QObject* parent = nullptr);

public:
};

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

#endif // DEVICEMANAGER_H
