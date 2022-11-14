#ifndef GREEN_DEVICEDISCOVERYAGENT_H
#define GREEN_DEVICEDISCOVERYAGENT_H

#include <QObject>
#include <QtQml>

class Device;
class DeviceDiscoveryAgentPrivate;

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
