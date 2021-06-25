#ifndef GREEN_NETWORKMANAGER_H
#define GREEN_NETWORKMANAGER_H

#include <QObject>
#include <QQmlListProperty>

class Network;

class NetworkManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<Network> networks READ networks CONSTANT)
public:
    static NetworkManager* instance();

    QQmlListProperty<Network> networks();

    Q_INVOKABLE Network* network(const QString& id) const;
    Q_INVOKABLE Network* networkWithServerType(const QString& key, const QString& server_type) const;

private:
    explicit NetworkManager();
    QList<Network*> m_networks;
};

#endif // GREEN_NETWORKMANAGER_H
