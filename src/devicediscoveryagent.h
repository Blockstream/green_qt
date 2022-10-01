#ifndef GREEN_DEVICEDISCOVERYAGENT_H
#define GREEN_DEVICEDISCOVERYAGENT_H

#include <QObject>
#include <QtQml>

QT_FORWARD_DECLARE_CLASS(Device)
QT_FORWARD_DECLARE_CLASS(DeviceDiscoveryAgentPrivate)

class DeviceDiscoveryAgent : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit DeviceDiscoveryAgent(QObject* parent = nullptr);
    ~DeviceDiscoveryAgent();
signals:
    void deviceConnected(Device* device);
private:
    DeviceDiscoveryAgentPrivate * const d;
};

#endif // GREEN_DEVICEDISCOVERYAGENT_H
