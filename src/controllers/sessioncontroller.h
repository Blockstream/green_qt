#ifndef GREEN_SESSIONCONTROLLER_H
#define GREEN_SESSIONCONTROLLER_H

#include "../controller.h"

#include <QQmlEngine>

class SessionController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Session* session READ session WRITE setSession NOTIFY sessionChanged)
    QML_ELEMENT
public:
    SessionController(QObject* parent = nullptr);
    Session* session() const { return m_session; }
    void setSession(Session* session);
public slots:
    void requestTwoFactorReset(const QString& email);
    void cancelTwoFactorReset();
    void setUnspentOutputsStatus(Account* account, const QVariantList &outputs, const QString &status);
    void sendRecoveryTransactions();
signals:
    void sessionChanged();
    void failed(const QString& error);
protected:
    Session* m_session{nullptr};
};

#endif // GREEN_SESSIONCONTROLLER_H
