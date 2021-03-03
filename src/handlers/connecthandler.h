#ifndef GREEN_CONNECTHANDLER_H
#define GREEN_CONNECTHANDLER_H

#include <QtQml>
#include <QObject>
#include <QJsonObject>

QT_FORWARD_DECLARE_CLASS(Network)
QT_FORWARD_DECLARE_CLASS(Session)

QT_FORWARD_DECLARE_STRUCT(GA_session)

class ConnectHandler : public QObject
{
    Q_OBJECT
public:
    ConnectHandler(Session* session, Network* network, const QString& proxy, bool use_tor);
    void exec();
signals:
    void error();
    void done();
private:
    void call(GA_session* session);
private:
    Session* const m_session;
    Network* const m_network;
    const QJsonObject m_params;
};

#endif // GREEN_CONNECTHANDLER_H
