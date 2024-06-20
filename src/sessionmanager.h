#ifndef GREEN_SESSIONMANAGER_H
#define GREEN_SESSIONMANAGER_H

#include <QJsonObject>
#include <QObject>
#include <QtQml>

#include "green.h"
#include "notification.h"

class SessionManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject tor READ tor NOTIFY torChanged FINAL)
public:
    SessionManager();
    virtual ~SessionManager();
    static SessionManager* instance();
    QJsonObject tor() const { return m_tor; }
    void setTor(const QJsonObject& tor);
    Session* create(Network* network);
signals:
    void torChanged();
private:
    QJsonObject m_tor;
};

#endif // GREEN_SESSIONMANAGER_H
