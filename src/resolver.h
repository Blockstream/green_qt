#ifndef GREEN_RESOLVER_H
#define GREEN_RESOLVER_H

#include "green.h"

#include <QJsonArray>
#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>

class Activity;

Q_MOC_INCLUDE("activity.h")
Q_MOC_INCLUDE("device.h")

class Resolver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Session* session READ session CONSTANT)
    Q_PROPERTY(QJsonObject result READ result CONSTANT)
    Q_PROPERTY(Activity* activity READ activity NOTIFY activityChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    Resolver(const QJsonObject& result, Session* session);
    Session* session() const { return m_session; };
    QJsonObject result() const { return m_result; }
    Activity* activity() const { return m_activity; }
public slots:
    virtual void resolve() = 0;
signals:
    void failed();
    void resolved(const QJsonObject& data);
    void progress(int current, int total);
    void activityChanged(Activity* activity);
protected:
    void pushActivity(Activity* activity);
    QJsonObject const m_result;
private:
    Activity* m_activity{nullptr};
protected:
    Session* const m_session;
};

class TwoFactorResolver : public Resolver
{
    Q_OBJECT
    Q_PROPERTY(QString method READ method CONSTANT)
    Q_PROPERTY(int attemptsRemaining READ attemptsRemaining NOTIFY attemptsRemainingChanged)
    Q_PROPERTY(QString code READ code WRITE setCode NOTIFY codeChanged)
    Q_PROPERTY(QString telegramBrowserUrl READ telegramBrowserUrl CONSTANT)
    Q_PROPERTY(QString telegramAppUrl READ telegramAppUrl CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    TwoFactorResolver(const QJsonObject& result, Session* session);
    QString method() const { return m_method; }
    int attemptsRemaining() const { return m_attempts_remaining; }
    QString code() const { return m_code; }
    void setCode(const QString& code);
    void resolve() override;
    void retry(const QJsonObject& result);
    QString telegramBrowserUrl() const;
    QString telegramAppUrl() const;
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
    Q_PROPERTY(Device* device READ device CONSTANT)
    Q_PROPERTY(QJsonObject requiredData READ requiredData CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    DeviceResolver(Device* device, const QJsonObject& result, Session* session);
    Device* device() const { return m_device; }
    QJsonObject requiredData() const { return m_required_data; }
protected:
    Device* const m_device;
    QJsonObject const m_required_data;
};

class GetXPubsResolver : public DeviceResolver
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetXPubsResolver(Device* device, const QJsonObject& result, Session* session);
    void resolve() override;
protected:
    QList<QVector<uint32_t>> m_paths;
    QJsonArray m_xpubs;
};

class SignMessageResolver : public DeviceResolver
{
    Q_OBJECT
    Q_PROPERTY(QString message READ message CONSTANT)
    Q_PROPERTY(QString hash READ hash CONSTANT)
    Q_PROPERTY(QString path READ path CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SignMessageResolver(Device* device, const QJsonObject& result, Session* session);
    QString message() const { return m_message; }
    QString hash() const { return m_hash; }
    QString path() const;
    void resolve() override;
private:
    const QString m_message;
    const QString m_hash;
    const QVector<uint32_t> m_path;
    const bool m_use_ae_protocol;
    const QByteArray m_ae_host_commitment;
    const QByteArray m_ae_host_entropy;
};

class SignTransactionResolver : public DeviceResolver
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject transaction READ transaction CONSTANT)
    Q_PROPERTY(QJsonArray outputs READ outputs CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SignTransactionResolver(Device* device, const QJsonObject& result, Session* session);
    QJsonObject transaction() const { return m_transaction; }
    QJsonArray outputs() const { return m_outputs; }
    void resolve() override;
private:
    QJsonObject const m_transaction;
    QJsonArray const m_outputs;
};

class BlindingKeysResolver : public DeviceResolver
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    BlindingKeysResolver(Device* device, const QJsonObject& result, Session* session);
    void resolve() override;
protected:
    QJsonArray m_scripts;
    QJsonArray m_public_keys;
};

class BlindingNoncesResolver : public DeviceResolver
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    BlindingNoncesResolver(Device* device, const QJsonObject& result, Session* session);
    void resolve() override;
protected:
    bool m_blinding_keys_required;
    QJsonArray m_scripts;
    QJsonArray m_public_keys;
    QJsonArray m_nonces;
    QJsonArray m_blinding_keys;
};

class SignLiquidTransactionResolver : public DeviceResolver
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject transaction READ transaction CONSTANT)
    Q_PROPERTY(QJsonArray outputs READ outputs CONSTANT)
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QJsonObject message READ message NOTIFY messageChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SignLiquidTransactionResolver(Device* device, const QJsonObject& result, Session* session);
    QJsonObject transaction() const { return m_transaction; }
    QJsonArray outputs() const { return m_outputs; }
    qreal progress() const { return m_progress; };
    QJsonObject message() const { return m_message; };
    void resolve() override;
signals:
    void progressChanged(qreal progress);
    void messageChanged(const QJsonObject& message);
protected:
    QJsonObject const m_transaction;
    QJsonArray const m_outputs;
    qreal m_progress{0};
    QJsonObject m_message;
};

class GetMasterBlindingKeyResolver : public DeviceResolver
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetMasterBlindingKeyResolver(Device* device, const QJsonObject& result, Session* session);
    void resolve() override;
};

#endif // GREEN_RESOLVER_H
