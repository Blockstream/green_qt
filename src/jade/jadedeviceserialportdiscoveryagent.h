#ifndef GREEN_JADEDEVICESERIALPORTDISCOVERYAGENT_H
#define GREEN_JADEDEVICESERIALPORTDISCOVERYAGENT_H

#include <QObject>
#include <QSet>
#include <QtQml/qqml.h>

class JadeDevice;

class JadeDeviceSerialPortDiscoveryAgent : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit JadeDeviceSerialPortDiscoveryAgent(QObject* parent = nullptr);
    void scan();
private:
    QMap<QString, JadeDevice*> m_devices;
    QSet<QString> m_failed_locations;
    int m_reset_countdown{0};
};

#endif // GREEN_JADEDEVICESERIALPORTDISCOVERYAGENT_H
