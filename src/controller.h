#ifndef GREEN_CONTROLLER_H
#define GREEN_CONTROLLER_H

#include <QtQml>

#include "entity.h"
#include "ga.h"

class Handler;
class Resolver;
class Output;
class Wallet;

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
signals:
    void errorsChanged();
protected:
    void setError(const QString& key, const QVariant& value);
    void clearError(const QString& key);
    bool updateError(const QString &key, const QVariant &value, bool when);
    void clearErrors();
private:
    QVariantMap m_errors;
};

class Controller : public AbstractController
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    QML_ELEMENT
public:
    explicit Controller(QObject* parent = nullptr);

    void exec(Handler* handler);

    QObject* context() const;
    GA_session* session() const;

    Wallet* wallet() const;
    void setWallet(Wallet* wallet);

public slots:
    void changeSettings(const QJsonObject& data);
    void sendRecoveryTransactions();
    void enableTwoFactor(const QString& method, const QString& data);
    void disableTwoFactor(const QString& method);
    void changeTwoFactorLimit(bool is_fiat, const QString &limit);
    void requestTwoFactorReset(const QString& email);
    void cancelTwoFactorReset();
    void setRecoveryEmail(const QString& email);
    void setCsvTime(int value);
    void deleteWallet();
    void disableAllPins();
    void setUnspentOutputsStatus(const QVariantList &outputs, const QString &status);
    Handler* getCredentials();
signals:
    void walletChanged(Wallet* wallet);
    void finished(Handler* handler = nullptr);

    void resultChanged(Handler* handler, const QJsonObject& result);
    void done(Handler* handler);
    void error(Handler* handler);
    void requestCode(Handler* handler);
    void invalidCode(Handler* handler);
    void deviceRequested(Handler* handler);

    void resolver(Resolver* resolver);
protected:
    Wallet* m_wallet{nullptr};
    QVariantMap m_errors;
};

#include "handler.h"
class TwoFactorResetHandler : public Handler
{
    Q_OBJECT
    Q_PROPERTY(QString email READ email CONSTANT)
    QML_ELEMENT
    const QByteArray m_email;
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    TwoFactorResetHandler(const QByteArray& email, Session* session);
    QString email() const { return m_email; }
};

#endif // GREEN_CONTROLLER_H
