#ifndef GREEN_DEVICESESSION_H
#define GREEN_DEVICESESSION_H

#include <QObject>
#include <QQmlEngine>

class Device;

class DeviceSession : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Device* device READ device CONSTANT)
    Q_PROPERTY(QString xpubHashId READ xpubHashId CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    DeviceSession(const QString& xpub_hash_id, Device* device);
    Device* device() const { return m_device; }
    QString xpubHashId() const { return m_xpub_hash_id; }
private:
    Device* const m_device;
    const QString m_xpub_hash_id;
};

#endif // GREEN_DEVICESESSION_H
