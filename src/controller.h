#ifndef GREEN_CONTROLLER_H
#define GREEN_CONTROLLER_H

#include "green.h"
#include "controllers/abstractcontroller.h"

#include <QQmlEngine>

Q_MOC_INCLUDE("resolver.h")
Q_MOC_INCLUDE("task.h")
Q_MOC_INCLUDE("wallet.h")

class Controller : public AbstractController
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context WRITE setContext NOTIFY contextChanged)
    Q_PROPERTY(TaskGroupMonitor* monitor READ monitor NOTIFY monitorChanged)
    QML_ELEMENT

public:
    explicit Controller(QObject* parent = nullptr);

    Context* context() const { return m_context; }
    void setContext(Context* context);

    TaskDispatcher* dispatcher() const;
    TaskGroupMonitor* monitor() const { return m_monitor; }
    void setMonitor(TaskGroupMonitor* monitor);

public slots:
    void changeSettings(const QJsonObject& data);
    void changeSessionSettings(Session* session, const QJsonObject& data);
    void setRecoveryEmail(const QString& email);
    void deleteWallet();
    void disableAllPins();
    void changePin(const QString& pin);

    bool setAccountName(Account* account, QString name, bool active_focus);
    void setAccountHidden(Account *account, bool hidden);

signals:
    void contextChanged();
    void monitorChanged();
    void resolver(Resolver* resolver);
    void finished();

protected:
    Context* m_context{nullptr};
    TaskGroupMonitor* m_monitor{nullptr};
    QVariantMap m_errors;
};

#endif // GREEN_CONTROLLER_H
