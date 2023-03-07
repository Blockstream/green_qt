#ifndef GREEN_SYSTEMMESSAGECONTROLLER_H
#define GREEN_SYSTEMMESSAGECONTROLLER_H

#include "controller.h"
#include "task.h"

class SystemMessageController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QString message READ message NOTIFY messageChanged)
    QML_ELEMENT
public:
    explicit SystemMessageController(QObject* parent = nullptr);

    QString message() const { return m_message; }
    void setMessage(const QString& message);

public slots:
    void ack();
    void check();

signals:
    void messageChanged();
    void message(const QString& text);
    void empty();

private:
    QString m_message;
//    QStringList m_pending;
//    QStringList m_accepted;
};

class GetSystemMessageTask : public ContextTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    GetSystemMessageTask(SystemMessageController* controller);
private:
    void update() override;
private:
    SystemMessageController* const m_controller;
};

class AckSystemMessageTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    AckSystemMessageTask(SystemMessageController* controller);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    SystemMessageController* const m_controller;
    const QString m_message;
};

#endif // GREEN_SYSTEMMESSAGECONTROLLER_H
