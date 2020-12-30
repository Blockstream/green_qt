#ifndef GREEN_DEVICE_H
#define GREEN_DEVICE_H

#include <QtQml>
#include <QObject>

#include "activity.h"

#define LEDGER_VENDOR_ID 0x2c97
#define LEDGER_NANOS_ID 0x0001
#define LEDGER_NANOX_ID 0x0004

QT_FORWARD_DECLARE_CLASS(DeviceCommand);
QT_FORWARD_DECLARE_CLASS(Network);

class GetWalletPublicKeyActivity : public Activity
{
public:
    GetWalletPublicKeyActivity(QObject* parent) : Activity(parent) {}
    virtual QByteArray publicKey() const = 0;
};

class SignMessageActivity : public Activity
{
public:
    SignMessageActivity(QObject* parent) : Activity(parent) {}
    virtual QByteArray signature() const = 0;
};

class SignTransactionActivity : public Activity
{
public:
    SignTransactionActivity(QObject* parent) : Activity(parent) {}
    virtual QList<QByteArray> signatures() const = 0;
};

class GetBlindingKeyActivity : public Activity
{
public:
    GetBlindingKeyActivity(QObject* parent) : Activity(parent) {}
    virtual QByteArray publicKey() const = 0;
};

class GetBlindingNonceActivity : public Activity
{
public:
    GetBlindingNonceActivity(QObject* parent) : Activity(parent) {}
    virtual QByteArray nonce() const = 0;
};

class SignLiquidTransactionActivity : public Activity
{
public:
    SignLiquidTransactionActivity(QObject* parent) : Activity(parent) {}
    virtual QList<QByteArray> signatures() const = 0;
    virtual QList<QByteArray> assetCommitments() const = 0;
    virtual QList<QByteArray> valueCommitments() const = 0;
    virtual QList<QByteArray> assetBlinders() const = 0;
    virtual QList<QByteArray> amountBlinders() const = 0;
};

class Device : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Transport transport READ transport CONSTANT)
    Q_PROPERTY(Type type READ type CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("Devices are instanced by DeviceDiscoveryAgent.")
public:
    enum Transport {
        USB,
    };
    enum Type {
        Unknown,
        LedgerNanoS,
        LedgerNanoX,
    };
    Q_ENUM(Transport)
    Q_ENUM(Type)
    Device(QObject* parent = nullptr);
    virtual Transport transport() const = 0;
    virtual Type type() const = 0;
    virtual QString name() const = 0;
    virtual GetWalletPublicKeyActivity* getWalletPublicKey(Network* network, const QVector<uint32_t>& path) = 0;
    virtual SignMessageActivity* signMessage(const QString& message, const QVector<uint32_t>& path) = 0;
    virtual SignTransactionActivity* signTransaction(uint32_t version, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, uint32_t locktime) = 0;
    virtual GetBlindingKeyActivity* getBlindingKey(const QString& script) = 0;
    virtual GetBlindingNonceActivity* getBlindingNonce(const QByteArray& pubkey, const QByteArray& script) = 0;
    virtual SignLiquidTransactionActivity* signLiquidTransaction(uint32_t version, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs) = 0;

    static Type typefromVendorAndProduct(uint32_t vendor_id, uint32_t product_id);
};

QT_FORWARD_DECLARE_CLASS(LedgerDevice);

#endif // GREEN_DEVICE_H
