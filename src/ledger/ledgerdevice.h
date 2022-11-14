#ifndef GREEN_LEDGERDEVICE_H
#define GREEN_LEDGERDEVICE_H

#include "command.h"
#include "device.h"

class LedgerDevice;

#define BTCHIP_CLA              0xe0
#define BTCHIP_CLA_COMMON_SDK   0xb0

#define BTCHIP_INS_GET_APP_NAME_AND_VERSION         0x01
#define BTCHIP_INS_GET_LIQUID_BLINDING_KEY          0xe2
#define BTCHIP_INS_GET_TRUSTED_INPUT                0x42
#define BTCHIP_INS_HASH_INPUT_START                 0x44
#define BTCHIP_INS_HASH_INPUT_FINALIZE_FULL         0x4a
#define BTCHIP_INS_HASH_SIGN                        0x48
#define BTCHIP_INS_GET_WALLET_PUBLIC_KEY            0x40
#define BTCHIP_INS_GET_LIQUID_BLINDING_KEY          0xe2
#define BTCHIP_INS_GET_LIQUID_NONCE                 0xe4
#define BTCHIP_INS_GET_LIQUID_COMMITMENTS           0xe0
#define BTCHIP_INS_GET_LIQUID_BLINDING_FACTOR       0xe8
#define BTCHIP_INS_GET_LIQUID_ISSUANCE_INFORMATION  0xe6
#define BTCHIP_INS_GET_FIRMWARE_VERSION             0xc4
#define BTCHIP_INS_SIGN_MESSAGE                     0x4e

QByteArray apdu(uint8_t cla, uint8_t ins, uint8_t p1, uint8_t p2, const QByteArray& data = QByteArray());
QByteArray compressPublicKey(const QByteArray& pubkey);
QByteArray pathToData(const QVector<uint32_t>& path);
void varInt(QDataStream& stream, int64_t i);

template <typename T> struct Varint { T v; };
template <typename T> Varint<T> varint(T v) { return {v}; }
QDataStream& operator<<(QDataStream& out, const Varint<uint32_t>& v);

int varIntSize(int i);

class GetFirmwareActivity : public Activity
{
    LedgerDevice* const m_device;
    uint8_t m_features;
    uint8_t m_arch;
    uint8_t m_fw_major;
    uint8_t m_fw_minor;
    uint8_t m_fw_patch;
    uint8_t m_loader_major;
    uint8_t m_loader_minor;
public:
    GetFirmwareActivity(LedgerDevice* device);
    QVersionNumber version() const { return QVersionNumber{m_fw_major, m_fw_minor, m_fw_patch}; }
private:
    void exec() override;
};

class GetAppActivity : public Activity
{
    LedgerDevice* const m_device;
    QString m_name;
    QVersionNumber m_version;
public:
    GetAppActivity(LedgerDevice* device);
    QString name() const;
    QVersionNumber version() const;
private:
    void exec() override;
};

class LedgerGenericCommand : public GenericCommand
{
    LedgerDevice* const m_device;
public:
    LedgerGenericCommand(LedgerDevice* device, const QByteArray& data);
    void exec() override;
};

class DevicePrivate;
class LedgerDevice : public Device
{
    Q_OBJECT
    Q_PROPERTY(QString appVersion READ appVersion NOTIFY appVersionChanged)
    QML_ELEMENT
public:
    explicit LedgerDevice(DevicePrivate* d, QObject* parent = nullptr);
    ~LedgerDevice();
    Vendor vendor() const override { return Device::Ledger; }
    Transport transport() const override;
    Type type() const override;
    QString name() const override;
    QJsonObject details() const override;

    DeviceCommand* exchange(const QByteArray& data);

    GetWalletPublicKeyActivity* getWalletPublicKey(Network* network, const QVector<uint32_t>& path) override;
    SignMessageActivity* signMessage(const QString& message, const QVector<uint32_t>& path) override;
    SignMessageActivity* signMessage(const QString& message, const QVector<uint32_t>& path, const QByteArray& ae_host_commitment, const QByteArray& ae_host_entropy) override;
    SignTransactionActivity* signTransaction(Network* network, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions) override;
    GetBlindingKeyActivity* getBlindingKey(const QString& script) override;
    GetBlindingNonceActivity* getBlindingNonce(const QByteArray& pubkey, const QByteArray& script) override;
    SignLiquidTransactionActivity* signLiquidTransaction(Network* network, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs) override;
    GetMasterBlindingKeyActivity* getMasterBlindingKey() override;
    void ping() override;

    GetFirmwareActivity* getFirmware();
    GetAppActivity* getApp();

    QString appVersion() const { return m_app_version; }
    void setAppVersion(const QString& app_version);
signals:
    void appVersionChanged(const QString& app_version);

private:
    friend class DevicePrivate;
    DevicePrivate* const d;
    QString m_app_version;
};

#endif // GREEN_LEDGERDEVICE_H
