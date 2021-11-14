#ifndef GREEN_CONTROLLER_H
#define GREEN_CONTROLLER_H

#include <QtQml>
#include <QObject>

#include "ga.h"

class Handler;
class Resolver;
class Output;
class Wallet;

class Controller : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    Q_PROPERTY(QVariantMap errors READ errors NOTIFY errorsChanged)
    Q_PROPERTY(bool noErrors READ noErrors NOTIFY errorsChanged)
    QML_ELEMENT
public:
    explicit Controller(QObject* parent = nullptr);

    void exec(Handler* handler);

    QObject* context() const;
    GA_session* session() const;

    Wallet* wallet() const;
    void setWallet(Wallet* wallet);

    QVariantMap errors() const { return m_errors; }
    bool noErrors() const { return m_errors.isEmpty(); }
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
protected:
    void setError(const QString& key, const QVariant& value);
    void clearError(const QString& key);
    void updateError(const QString &key, const QVariant &value, bool when);
    void clearErrors();
signals:
    void walletChanged(Wallet* wallet);
    void finished();

    void resultChanged(Handler* handler, const QJsonObject& result);
    void done(Handler* handler);
    void error(Handler* handler);
    void requestCode(Handler* handler);
    void invalidCode(Handler* handler);
    void deviceRequested(Handler* handler);

    void resolver(Resolver* resolver);
    void errorsChanged();
protected:
    Wallet* m_wallet{nullptr};
    QVariantMap m_errors;
};

#endif // GREEN_CONTROLLER_H
