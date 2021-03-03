#ifndef GREEN_JADEDEVICESERIALPORTDISCOVERYAGENT_H
#define GREEN_JADEDEVICESERIALPORTDISCOVERYAGENT_H

#include <QtQml/qqml.h>
#include <QObject>
#include <QSet>

QT_FORWARD_DECLARE_CLASS(JadeDevice)

class JadeDeviceSerialPortDiscoveryAgent : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit JadeDeviceSerialPortDiscoveryAgent(QObject* parent = nullptr);
private:
    QMap<QString, JadeDevice*> m_devices;
    QSet<QString> m_failed_locations;
};

#endif // GREEN_JADEDEVICESERIALPORTDISCOVERYAGENT_H
