#ifndef GREEN_DEVICE_H
#define GREEN_DEVICE_H

#include <QObject>
#include <QtQml>

#include "deviceactivities.h"
#include "devicesession.h"

#define LEDGER_VENDOR_ID 0x2c97
#define LEDGER_NANOS_ID 0x0001
#define LEDGER_NANOX_ID 0x0004

class Device;
class DeviceCommand;
class Network;

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
    Q_PROPERTY(DeviceSession* session READ session NOTIFY sessionChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
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
    virtual SignTransactionActivity* signTransaction(Network* network, const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions) = 0;
    virtual GetBlindingKeyActivity* getBlindingKey(const QString& script) = 0;
    virtual GetBlindingNonceActivity* getBlindingNonce(const QByteArray& pubkey, const QByteArray& script) = 0;
    virtual SignLiquidTransactionActivity* signLiquidTransaction(Network* network, const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs) = 0;
    virtual GetMasterBlindingKeyActivity* getMasterBlindingKey() = 0;
    virtual GetBlindingFactorsActivity* getBlindingFactors(const QJsonArray& inputs, const QJsonArray& outputs) = 0;
    virtual LogoutActivity* logout() = 0;
    static Type typefromVendorAndProduct(uint32_t vendor_id, uint32_t product_id);
    bool isConnected() const { return m_connected; }
    void setConnected(bool connected);
    DeviceSession* session() const { return m_session; }
    void createSession(const QString& xpub_hash_id);
    void clearSession();

    virtual bool supportsNetwork(Network* network) = 0;
private:
    void setSession(DeviceSession* session);
signals:
    void nameChanged();
    void detailsChanged();
    void connectedChanged();
    void sessionChanged();
private:
    const QString m_uuid;
    bool m_connected{false};
    DeviceSession* m_session{nullptr};
};

#endif // GREEN_DEVICE_H
