#ifndef GREEN_JADEDEVICESERIALPORTDISCOVERYAGENT_H
#define GREEN_JADEDEVICESERIALPORTDISCOVERYAGENT_H

#include <QObject>
#include <QSet>
#include <QtQml/qqml.h>

class JadeAPI;
class JadeDevice;

class JadeDeviceSerialPortDiscoveryAgent : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit JadeDeviceSerialPortDiscoveryAgent(QObject* parent = nullptr);
    void scan();
private:
    void remove(JadeAPI* backend);
    void probe(JadeAPI* backend);
    void updateLater(JadeAPI* backend);
    JadeDevice* deviceFromBackend(JadeAPI* backend);
private:
    QMap<QString, JadeAPI*> m_backends;
    QMap<JadeAPI*, int> m_attempts;
};

#endif // GREEN_JADEDEVICESERIALPORTDISCOVERYAGENT_H
