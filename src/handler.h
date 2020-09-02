#ifndef GREEN_HANDLER_H
#define GREEN_HANDLER_H

#include <QtQml>
#include <QJsonObject>

struct GA_session;
struct GA_auth_handler;

class Controller;
class Handler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject result READ result NOTIFY resultChanged)
    QML_ELEMENT
    QML_UNCREATABLE("Handler is an abstract base class.")
    Q_ENUMS(Status)
public:
    enum class Status { INVALID, DONE, ERROR, CALL, RESOLVE_CODE, REQUEST_CODE };
    enum class Action { INVALID, CREATE_TRANSACTION, ENABLE_2FA, ENABLE_EMAIL, CHANGE_TX_LIMITS, GET_XPUBS, SIGN_MESSAGE, SIGN_TX, SEND_RAW_TX, };
    Handler(Controller* controller);
    virtual ~Handler();
    virtual void init() = 0;
    void exec();
    Status status() const { return m_status; }
    Action action() const { Q_ASSERT(m_status == Status::RESOLVE_CODE); return m_action; }
    const QJsonObject& result() const { Q_ASSERT(m_status != Status::INVALID); return m_result; }
public slots:
    void request(const QByteArray& method);
    void resolve(const QJsonObject& data);
    void resolve(const QByteArray& data);
signals:
    void done();
    void error();
    void requestCode();
    void resolveCode();
    void statusChanged(Status status);
    void resultChanged(const QJsonObject& result);
private:
    void setStatus(Status status);
    void setAction(Action action);
protected:
    Controller* const m_controller;
    GA_session* const m_session;
    GA_auth_handler* m_handler{nullptr};
    QJsonObject m_result;
    Status m_status{Status::INVALID};
    Action m_action{Action::INVALID};
public:
    QList<QVector<uint32_t>> m_paths;
    QJsonArray m_xpubs;
};

#endif // GREEN_HANDLER_H
