#ifndef GREEN_CONNECTHANDLER_H
#define GREEN_CONNECTHANDLER_H

#include <QJsonObject>
#include <QObject>
#include <QtQml>

QT_FORWARD_DECLARE_CLASS(Network)
QT_FORWARD_DECLARE_CLASS(Session)

QT_FORWARD_DECLARE_STRUCT(GA_session)

class ConnectHandler : public QFutureWatcher<int>
{
    Q_OBJECT
public:
    ConnectHandler(Session* session);
    virtual ~ConnectHandler();
    void exec();
private:
    Session* const m_session;
};

#endif // GREEN_CONNECTHANDLER_H
