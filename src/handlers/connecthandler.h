#ifndef GREEN_CONNECTHANDLER_H
#define GREEN_CONNECTHANDLER_H

#include <QtQml>
#include <QObject>
#include <QJsonObject>

QT_FORWARD_DECLARE_CLASS(Network)
QT_FORWARD_DECLARE_CLASS(Session)

QT_FORWARD_DECLARE_STRUCT(GA_session)

class ConnectHandler : public QFutureWatcher<int>
{
    Q_OBJECT
public:
    ConnectHandler(Session* session, Network* network, const QString& proxy, bool use_tor);
    virtual ~ConnectHandler();
    void exec();
    int attempts{0};
private:
    Session* const m_session;
    Network* const m_network;
    const QJsonObject m_params;
};

#endif // GREEN_CONNECTHANDLER_H
