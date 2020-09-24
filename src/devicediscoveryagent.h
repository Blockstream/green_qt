#ifndef GREEN_DEVICEDISCOVERYAGENT_H
#define GREEN_DEVICEDISCOVERYAGENT_H

#include <QtQml>
#include <QObject>

class DeviceDiscoveryAgentPrivate;

class DeviceDiscoveryAgent : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit DeviceDiscoveryAgent(QObject* parent = nullptr);
    ~DeviceDiscoveryAgent();

    /*
    DeviceMacOs* deviceWithHandle(int32_t usage_page, IOHIDDeviceRef handle) const;

    void addDevice(Device* device);
    void removeDevice(Device* device);

    bool exchange(IOHIDDeviceRef device, Command* command);
    void readHIDReport(IOHIDDeviceRef device, const QByteArray& data);

    IOHIDManagerRef m_manager;
public:
    QMap<IOHIDDeviceRef, QQueue<Command*>> m_queues;
*/
private:
    DeviceDiscoveryAgentPrivate * const d;
};

#endif // GREEN_DEVICEDISCOVERYAGENT_H
