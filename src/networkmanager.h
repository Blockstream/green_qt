#ifndef GREEN_NETWORKMANAGER_H
#define GREEN_NETWORKMANAGER_H

#include <QObject>
#include <QQmlListProperty>
#include <QQmlEngine>

class Network;

class NetworkManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    static NetworkManager* instance();

    static NetworkManager *create(QQmlEngine *, QJSEngine *engine);

    QList<Network*> networks() const;

    Q_INVOKABLE Network* network(const QString& id) const;
    Q_INVOKABLE Network* networkWithServerType(const QString& deployment, const QString& key, const QString& server_type) const;
    Q_INVOKABLE Network* networkForDeployment(const QString& deployment);

private:
    explicit NetworkManager();
    QList<Network*> m_networks;
};

#endif // GREEN_NETWORKMANAGER_H
