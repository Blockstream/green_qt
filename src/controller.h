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
    QML_ELEMENT

public:
    explicit Controller(QObject* parent = nullptr);

    Context* context() const { return m_context; }
    void setContext(Context* context);

    TaskDispatcher* dispatcher() const;

public slots:
    void changeSettings(const QJsonObject& data);
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

    // TODO move to SetWatchOnlyController
    void setWatchOnly(const QString& username, const QString& password);
    void clearWatchOnly();

    bool setAccountName(Account* account, QString name, bool active_focus);
    void setAccountHidden(Account *account, bool hidden);

signals:
    void contextChanged();
    void resolver(Resolver* resolver);
    void finished();

    // TODO move to SetWatchOnlyController
    void watchOnlyUpdateSuccess();
    void watchOnlyUpdateFailure();

protected:
    Context* m_context{nullptr};
    QVariantMap m_errors;
};


class TwoFactorController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(bool done READ done NOTIFY doneChanged)
    QML_ELEMENT
public:
    explicit TwoFactorController(QObject* parent = nullptr);
    bool done() const { return m_done; }
public slots:
    void enable(const QString& method, const QString& data);
    void disable(const QString& method);
signals:
    void doneChanged();
private:
    void change(const QString& method, const QJsonObject& details);
private:
    bool m_done{false};
};

#endif // GREEN_CONTROLLER_H
