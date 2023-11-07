#ifndef GREEN_DEVICE_H
#define GREEN_DEVICE_H

#include <QObject>
#include <QtQml>

#include "activity.h"

#define LEDGER_VENDOR_ID 0x2c97
#define LEDGER_NANOS_ID 0x0001
#define LEDGER_NANOX_ID 0x0004

class Device;
class DeviceCommand;
class Network;

class GetWalletPublicKeyActivity : public Activity
{
public:
    GetWalletPublicKeyActivity(Network* network, const QVector<uint32_t>& path, Device* device);
    Device* device() const { return m_device; }
    Network* network() const { return m_network; }
    QVector<uint32_t> path() const { return m_path; }
    QByteArray publicKey() const { return m_public_key; }
    void setPublicKey(const QByteArray& public_key);
    void exec() override;
    virtual void fetch() = 0;
protected:
    Device* const m_device;
    Network* const m_network;
    const QVector<uint32_t> m_path;
    QByteArray m_public_key;
};

class SignMessageActivity : public Activity
{
public:
    SignMessageActivity(QObject* parent) : Activity(parent) {}
    virtual QByteArray signature() const = 0;
    virtual QByteArray signerCommitment() const { return {}; }
};

class SignTransactionActivity : public Activity
{
public:
    SignTransactionActivity(QObject* parent) : Activity(parent) {}
    virtual QList<QByteArray> signatures() const = 0;
    virtual QList<QByteArray> signerCommitments() const = 0;
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
    virtual QList<QByteArray> signerCommitments() const = 0;
    virtual QList<QByteArray> assetCommitments() const = 0;
    virtual QList<QByteArray> valueCommitments() const = 0;
    virtual QList<QByteArray> assetBlinders() const = 0;
    virtual QList<QByteArray> amountBlinders() const = 0;
};

class GetMasterBlindingKeyActivity : public Activity
{
public:
    GetMasterBlindingKeyActivity(QObject* parent) : Activity(parent) {}
    virtual QByteArray masterBlindingKey() const = 0;
};

class LogoutActivity : public Activity
{
public:
    LogoutActivity(QObject* parent) : Activity(parent) {}
};

class Device : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString uuid READ uuid CONSTANT)
    Q_PROPERTY(Vendor vendor READ vendor CONSTANT)
    Q_PROPERTY(Transport transport READ transport CONSTANT)
    Q_PROPERTY(Type type READ type CONSTANT)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(QJsonObject details READ details NOTIFY detailsChanged)
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)
    QML_ELEMENT
    QML_UNCREATABLE("Devices are instanced by DeviceDiscoveryAgent.")
public:
    enum Transport {
        USB,
    };
    enum Vendor {
        NoVendor,
        Blockstream,
        Ledger
    };
    enum Type {
        NoType,
        BlockstreamJade,
        LedgerNanoS,
        LedgerNanoX,
    };
    Q_ENUM(Transport)
    Q_ENUM(Vendor)
    Q_ENUM(Type)
    Device(QObject* parent = nullptr);
    QString uuid() const { return m_uuid; }
    virtual Transport transport() const = 0;
    virtual Vendor vendor() const = 0;
    virtual Type type() const = 0;
    virtual QString name() const = 0;
    virtual QJsonObject details() const = 0;
    virtual GetWalletPublicKeyActivity* getWalletPublicKey(Network* network, const QVector<uint32_t>& path) = 0;
    virtual SignMessageActivity* signMessage(const QString& message, const QVector<uint32_t>& path) = 0;
    virtual SignMessageActivity* signMessage(const QString& message, const QVector<uint32_t>& path, const QByteArray& ae_host_commitment, const QByteArray& ae_host_entropy) = 0;
    virtual SignTransactionActivity* signTransaction(Network* network, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions) = 0;
    virtual GetBlindingKeyActivity* getBlindingKey(const QString& script) = 0;
    virtual GetBlindingNonceActivity* getBlindingNonce(const QByteArray& pubkey, const QByteArray& script) = 0;
    virtual SignLiquidTransactionActivity* signLiquidTransaction(Network* network, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs) = 0;
    virtual GetMasterBlindingKeyActivity* getMasterBlindingKey() = 0;
    virtual LogoutActivity* logout() = 0;
    static Type typefromVendorAndProduct(uint32_t vendor_id, uint32_t product_id);
    QByteArray masterPublicKey(Network* network) const;
    void setMasterPublicKey(Network* network, const QByteArray& master_public_key);
    bool isConnected() const { return m_connected; }
    void setConnected(bool connected);
signals:
    void nameChanged();
    void detailsChanged();
    void connectedChanged();
private:
    const QString m_uuid;
    bool m_connected{false};
    QMap<Network*, QByteArray> m_master_public_key;
};

class LedgerDevice;

#endif // GREEN_DEVICE_H
