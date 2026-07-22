#ifndef GREEN_CONTROLLER_H
#define GREEN_CONTROLLER_H

#include "green.h"

#include <QFutureSynchronizer>
#include <QQmlEngine>
#include <QVariantMap>

Q_MOC_INCLUDE("resolver.h")
Q_MOC_INCLUDE("task.h")
Q_MOC_INCLUDE("wallet.h")

class ControllerPrivate
{
public:
    virtual ~ControllerPrivate() = default;
    Context* context{nullptr};
    TaskGroupMonitor* monitor{nullptr};
    QFutureSynchronizer<void> future_synchronizer;
};

class Controller : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap errors READ errors NOTIFY errorsChanged)
    Q_PROPERTY(bool noErrors READ noErrors NOTIFY errorsChanged)
    Q_PROPERTY(Context* context READ context WRITE setContext NOTIFY contextChanged)
    Q_PROPERTY(TaskGroupMonitor* monitor READ monitor NOTIFY monitorChanged)
    Q_DECLARE_PRIVATE(Controller)
    QML_ELEMENT
public:
    explicit Controller(QObject* parent = nullptr);
    ~Controller();

    QVariantMap errors() const { return m_errors; }
    bool noErrors() const { return m_errors.isEmpty(); }

    Context* context() const;
    void setContext(Context* context);

    TaskDispatcher* dispatcher() const;
    TaskGroupMonitor* monitor() const;
    void setMonitor(TaskGroupMonitor* monitor);

public slots:
    void clearErrors();
    void changeSettings(const QJsonObject& data);
    void changeSessionSettings(Session* session, const QJsonObject& data);
    void setSessionRecoveryEmail(Session* session, const QString& email);
    void deleteWallet();
    void disableAllPins();
    void changePin(const QString& pin);

    bool setAccountName(Account* account, QString name);
    void setAccountHidden(Account *account, bool hidden);

protected:
    explicit Controller(ControllerPrivate* d, QObject* parent = nullptr);
    void waitForFuture(QFuture<void> future);
    void setError(const QString& key, const QVariant& value);
    void clearError(const QString& key);
    bool updateError(const QString& key, const QVariant& value, bool when);

signals:
    void errorsChanged();
    void contextChanged();
    void monitorChanged();
    void resolver(Resolver* resolver);
    void failed(const QString& error);
    void finished();

protected:
    ControllerPrivate* const d_ptr;

private:
    QVariantMap m_errors;
};

#endif // GREEN_CONTROLLER_H
