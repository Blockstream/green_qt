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
    Q_PROPERTY(Handler* handler READ handler CONSTANT)
    Q_PROPERTY(bool failed READ failed NOTIFY failedChanged)
    QML_ELEMENT
public:
    Resolver(Handler* handler, const QJsonObject& result);
    Handler* handler() const { return m_handler; }
    Wallet* wallet() const;
    Network* network() const;
    bool failed() const { return m_failed; }
public slots:
    virtual void resolve() = 0;
signals:
    void failedChanged(bool failed);
    void progress(int current, int total);
protected:
    void setFailed(bool failed);
    Handler* const m_handler;
    QJsonObject const m_result;
private:
    bool m_failed{false};
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

class BlindingKeysResolver : public DeviceResolver
{
    Q_OBJECT
    QML_ELEMENT
public:
    BlindingKeysResolver(Handler* handler, const QJsonObject& result);
    void resolve() override;
protected:
    QStringList m_keys;
    QStringList m_scripts;
    QJsonObject m_blinding_keys;
};

class BlindingKeyResolver : public DeviceResolver
{
    Q_OBJECT
    QML_ELEMENT
public:
    BlindingKeyResolver(Handler* handler, const QJsonObject& result);
    void resolve() override;
protected:
    QString m_script;
};

class BlindingNoncesResolver : public DeviceResolver
{
    Q_OBJECT
    QML_ELEMENT
public:
    BlindingNoncesResolver(Handler* handler, const QJsonObject& result);
    void resolve() override;
protected:
    QStringList m_pubkeys;
    QStringList m_scripts;
    QJsonArray m_nonces;
};

class SignLiquidTransactionResolver : public DeviceResolver
{
    Q_OBJECT
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QJsonObject message READ message NOTIFY messageChanged)
    QML_ELEMENT
public:
    SignLiquidTransactionResolver(Handler* handler, const QJsonObject& result);
    qreal progress() const { return m_progress; };
    QJsonObject message() const { return m_message; };
    void resolve() override;
signals:
    void progressChanged(qreal progress);
    void messageChanged(const QJsonObject& message);
protected:
    qreal m_progress{0};
    QJsonObject m_message;
};

#endif // GREEN_RESOLVER_H
