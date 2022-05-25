#ifndef GREEN_NETWORKMANAGER_H
#define GREEN_NETWORKMANAGER_H

#include <QObject>
#include <QQmlListProperty>

class Network;

class NetworkManager : public QObject
{
    Q_OBJECT
public:
    static NetworkManager* instance();

    QList<Network*> networks() const;

    Q_INVOKABLE Network* network(const QString& id) const;
    Q_INVOKABLE Network* networkWithServerType(const QString& key, const QString& server_type) const;

private:
    explicit NetworkManager();
    QList<Network*> m_networks;
};

#endif // GREEN_NETWORKMANAGER_H
