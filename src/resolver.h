#ifndef GREEN_RESOLVER_H
#define GREEN_RESOLVER_H

#include <QObject>
#include <QJsonObject>
#include <QtQml>

QT_FORWARD_DECLARE_CLASS(Activity)
QT_FORWARD_DECLARE_CLASS(Device)
QT_FORWARD_DECLARE_CLASS(Handler)
QT_FORWARD_DECLARE_CLASS(Network)
QT_FORWARD_DECLARE_CLASS(Wallet)

// TODO ensure Resolver::resolve isn't called incorrectly or more than possible
class Resolver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Handler* handler READ handler CONSTANT)
    Q_PROPERTY(QJsonObject result READ result CONSTANT)
    Q_PROPERTY(Activity* activity READ activity NOTIFY activityChanged)
    Q_PROPERTY(bool failed READ failed NOTIFY failedChanged)
    QML_ELEMENT
public:
    Resolver(Handler* handler, const QJsonObject& result);
    Handler* handler() const { return m_handler; }
    QJsonObject result() const { return m_result; }
    Network* network() const;
    Activity* activity() const { return m_activity; }
    bool failed() const { return m_failed; }
public slots:
    virtual void resolve() = 0;
signals:
    void failedChanged(bool failed);
    void progress(int current, int total);
    void activityChanged(Activity* activity);
protected:
    void pushActivity(Activity* activity);
    void setFailed(bool failed);
    Handler* const m_handler;
    QJsonObject const m_result;
private:
    bool m_failed{false};
    Activity* m_activity{nullptr};
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
public:
    TwoFactorResolver(Handler* handler, const QJsonObject& result);
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
public:
    DeviceResolver(Handler* handler, Device* device, const QJsonObject& result);
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
public:
    GetXPubsResolver(Handler* handler, Device* device, const QJsonObject& result);
    void resolve() override;
protected:
    QList<QVector<uint32_t>> m_paths;
    QJsonArray m_xpubs;
};

class SignTransactionResolver : public DeviceResolver
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject transaction READ transaction CONSTANT)
    Q_PROPERTY(QJsonArray outputs READ outputs CONSTANT)
    QML_ELEMENT
public:
    SignTransactionResolver(Handler* handler, Device* device, const QJsonObject& result);
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
public:
    BlindingKeysResolver(Handler* handler, Device* device, const QJsonObject& result);
    void resolve() override;
protected:
    QJsonArray m_scripts;
    QJsonArray m_public_keys;
};

class BlindingNoncesResolver : public DeviceResolver
{
    Q_OBJECT
    QML_ELEMENT
public:
    BlindingNoncesResolver(Handler* handler, Device* device, const QJsonObject& result);
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
public:
    SignLiquidTransactionResolver(Handler* handler, Device* device, const QJsonObject& result);
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
public:
    GetMasterBlindingKeyResolver(Handler* handler, Device* device, const QJsonObject& result);
    void resolve() override;
};

#endif // GREEN_RESOLVER_H
