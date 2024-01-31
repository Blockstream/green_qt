#ifndef GREEN_CONTROLLER_H
#define GREEN_CONTROLLER_H

#include "green.h"

#include <QQmlEngine>

#include "entity.h"
#include "ga.h"

Q_MOC_INCLUDE("resolver.h")
Q_MOC_INCLUDE("task.h")
Q_MOC_INCLUDE("wallet.h")

class AbstractController : public Entity
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap errors READ errors NOTIFY errorsChanged)
    Q_PROPERTY(bool noErrors READ noErrors NOTIFY errorsChanged)
    QML_ELEMENT
public:
    AbstractController(QObject* parent = nullptr);
    QVariantMap errors() const { return m_errors; }
    bool noErrors() const { return m_errors.isEmpty(); }
public slots:
    void clearErrors();
signals:
    void errorsChanged();
protected:
    void setError(const QString& key, const QVariant& value);
    void clearError(const QString& key);
    bool updateError(const QString &key, const QVariant &value, bool when);
private:
    QVariantMap m_errors;
};

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
    void sendRecoveryTransactions();
    void changeTwoFactorLimit(bool is_fiat, const QString &limit);
    void requestTwoFactorReset(const QString& email);
    void cancelTwoFactorReset();
    void setRecoveryEmail(const QString& email);
    void setCsvTime(int value);
    void deleteWallet();
    void disableAllPins();
    void setUnspentOutputsStatus(Account* account, const QVariantList &outputs, const QString &status);
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

class SessionController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Session* session READ session WRITE setSession NOTIFY sessionChanged)
    QML_ELEMENT
public:
    SessionController(QObject* parent = nullptr);
    Session* session() const { return m_session; }
    void setSession(Session* session);
signals:
    void sessionChanged();
protected:
    Session* m_session{nullptr};
};

class WatchOnlyController : public SessionController
{
    Q_OBJECT
    QML_ELEMENT
public:
    WatchOnlyController(QObject* parent = nullptr);
public slots:
    void update(const QString& username, const QString& password);
    void clear();
signals:
    void failed(const QString& error);
};

class TwoFactorController : public SessionController
{
    Q_OBJECT
    Q_PROPERTY(QString method READ method WRITE setMethod NOTIFY methodChanged)
    QML_ELEMENT
public:
    explicit TwoFactorController(QObject* parent = nullptr);
    QString method() const { return m_method; }
    void setMethod(const QString& method);
public slots:
    void enable(const QString& data);
    void disable();
signals:
    void methodChanged();
    void failed(const QString& error);
private:
    void change(const QJsonObject& details);
    QString m_method;
};

class SignMessageController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Address* address READ address WRITE setAddress NOTIFY addressChanged)
    Q_PROPERTY(QString message READ message WRITE setMessage NOTIFY messageChanged)
    Q_PROPERTY(bool valid READ isValid NOTIFY validChanged)
    Q_PROPERTY(QString signature READ signature NOTIFY signatureChanged)
    QML_ELEMENT
public:
    explicit SignMessageController(QObject* parent = nullptr);
    Address* address() const { return m_address; }
    void setAddress(Address* address);
    QString message() const { return m_message; }
    void setMessage(const QString& message);
    bool isValid() const { return m_valid; }
    QString signature() const { return m_signature; }
public slots:
    void sign();
signals:
    void addressChanged();
    void messageChanged();
    void validChanged();
    void signatureChanged();
    void cleared();
    void accepted(const QString& signature);
    void rejected();
private:
    void updateValid();
    void setSignature(const QString& signature);
    void clearSignature();
private:
    Address* m_address{nullptr};
    QString m_message;
    bool m_valid{false};
    QString m_signature;
};

#endif // GREEN_CONTROLLER_H
