#ifndef GREEN_RESOLVER_H
#define GREEN_RESOLVER_H

#include <QObject>
#include <QJsonObject>
#include <QtQml>

class Device;
class Handler;
class Network;
class Wallet;

// TODO ensure Resolver::resolve isn't called incorrectly or more than possible
class Resolver : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    Resolver(Handler* handler, const QJsonObject& result);
    Handler* handler() const { return m_handler; }
    Wallet* wallet() const;
    Network* network() const;
public slots:
    virtual void resolve() = 0;
protected:
    Handler* const m_handler;
    QJsonObject const m_result;
};

class TwoFactorResolver : public Resolver
{
    Q_OBJECT
    Q_PROPERTY(QString method READ method CONSTANT)
    Q_PROPERTY(int attemptsRemaining READ attemptsRemaining NOTIFY attemptsRemainingChanged)
    Q_PROPERTY(QString code READ code WRITE setCode NOTIFY codeChanged)
    QML_ELEMENT
public:
    TwoFactorResolver(Handler* handler, const QJsonObject& result);
    QString method() const { return m_method; }
    int attemptsRemaining() const { return m_attempts_remaining; }
    QString code() const { return m_code; }
    void setCode(const QString& code);
    void resolve() override;
    void retry(const QJsonObject& result);
signals:
    void invalidCode();
    void codeChanged(const QString& code);
    void attemptsRemainingChanged();
protected:
    const QString m_method;
    int m_attempts_remaining;
    QString m_code;
};

class DeviceResolver : public Resolver
{
    Q_OBJECT
    QML_ELEMENT
public:
    DeviceResolver(Handler* handler, const QJsonObject& result);
    Device* device() const;
protected:
    QJsonObject const m_required_data;
};

class GetXPubsResolver : public DeviceResolver
{
    Q_OBJECT
    QML_ELEMENT
public:
    GetXPubsResolver(Handler* handler, const QJsonObject& result);
    void resolve() override;
protected:
    QList<QVector<uint32_t>> m_paths;
    QJsonArray m_xpubs;
};

class SignTransactionResolver : public DeviceResolver
{
    Q_OBJECT
    QML_ELEMENT
public:
    SignTransactionResolver(Handler* handler, const QJsonObject& result);
    void resolve() override;
protected:
    QJsonArray m_signatures;
};

#endif // GREEN_RESOLVER_H
