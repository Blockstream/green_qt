#ifndef GREEN_DEVICE_H
#define GREEN_DEVICE_H

#include <QtQml>
#include <QObject>

#include <gdk.h>

#include "command.h"

#define LEDGER_VENDOR_ID 0x2c97
#define LEDGER_NANOS_ID 0x0001
#define LEDGER_NANOX_ID 0x0004

class Device;
class DevicePrivate;
class Handler;
class Network;
class Wallet;

class CommandBatch;

class Command : public QObject
{
    Q_OBJECT
public:
    Command(CommandBatch* batch = nullptr);
    virtual ~Command();
public slots:
    virtual void exec() = 0;
signals:
    void error();
    void finished();
};

class DeviceCommand : public Command
{
public:
    DeviceCommand(Device* device, CommandBatch* batch = nullptr)
        : Command(batch)
        , m_device(device)
    {
    }
    virtual QByteArray payload() const = 0;
    virtual bool parse(const QByteArray& data);
    virtual bool parse(QDataStream& stream) { Q_UNUSED(stream); Q_UNIMPLEMENTED(); Q_UNREACHABLE(); };
    int readHIDReport(Device* device, QDataStream& stream);
    bool readAPDUResponse(Device* device, int length, QDataStream& stream);

    virtual void exec() override;
    Device* const m_device;
    uint16_t length;
    uint16_t offset;
    QByteArray buf;
    QByteArray m_response;
};

class CommandBatch : public Command
{
    Q_OBJECT
public:
    void add(Command* command) { m_commands.append(command); }
    void exec() override {
        if (m_commands.isEmpty()) return emit finished();
        auto next = m_commands.takeFirst();
        connect(next, &Command::finished, this, &Command::exec, Qt::QueuedConnection);
        connect(next, &Command::error, this, &Command::error);
        next->exec();
    }
private:
    QList<Command*> m_commands;
};

class GenericCommand : public DeviceCommand
{
    const QByteArray m_data;
public:
    GenericCommand(Device* device, const QByteArray& data, CommandBatch* batch = nullptr)
        : DeviceCommand(device, batch)
        , m_data(data) {}
    QByteArray payload() const override { return m_data; }
    virtual bool parse(QDataStream& stream) override { return true; };
};

class GetAppNameCommand : public DeviceCommand
{
public:
    GetAppNameCommand(Device* device, CommandBatch* batch = nullptr)
        : DeviceCommand(device, batch)
    {}
    QByteArray payload() const override;
    bool parse(QDataStream& stream) override;
    QString m_name;
    QString m_version;
};

class GetFirmwareCommand : public DeviceCommand
{
public:
    GetFirmwareCommand(Device* device, CommandBatch* batch = nullptr)
        : DeviceCommand(device, batch)
    {}
    QByteArray payload() const override;
    bool parse(QDataStream& stream) override;
};


using GetWalletPublicKeyActivity = Command2<QString>;
using SignMessageActivity = Command2<QByteArray>;
using SignTransactionActivity = Command2<QList<QByteArray>>;
using GetBlindingKeyActivity = Command2<QByteArray>;
using GetBlindingNonceActivity = Command2<QByteArray>;
class SignLiquidTransactionActivity : public Activity
{
public:
    SignLiquidTransactionActivity(Device* device) : Activity(device) {}
    virtual QList<QByteArray> signatures() const = 0;
    virtual QList<QByteArray> assetCommitments() const = 0;
    virtual QList<QByteArray> valueCommitments() const = 0;
    virtual QList<QByteArray> assetBlinders() const = 0;
    virtual QList<QByteArray> amountBlinders() const = 0;
};

class AbstractDevice : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Transport transport READ transport CONSTANT)
    Q_PROPERTY(Type type READ type CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
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
    AbstractDevice(QObject* parent = nullptr);
    virtual Transport transport() const = 0;
    virtual Type type() const = 0;
    virtual QString name() const = 0;
    virtual GetWalletPublicKeyActivity* getWalletPublicKey(Network* network, const QVector<uint32_t>& path) = 0;
    virtual SignMessageActivity* signMessage(const QString& message, const QVector<uint32_t>& path) = 0;
    virtual SignTransactionActivity* signTransaction(uint32_t version, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, uint32_t locktime) = 0;
    virtual GetBlindingKeyActivity* getBlindingKey(const QString& script) = 0;
    virtual GetBlindingNonceActivity* getBlindingNonce(const QByteArray& pubkey, const QByteArray& script) = 0;
    virtual SignLiquidTransactionActivity* signLiquidTransaction(uint32_t version, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs) = 0;
};

class DevicePrivate;
class Device : public AbstractDevice
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Devices are instanced by DeviceDiscoveryAgent.")
public:
    explicit Device(DevicePrivate* d, QObject* parent = nullptr);
    ~Device();
    
    Transport transport() const override;
    Type type() const override;
    QString name() const override;

    static Type typefromVendorAndProduct(uint32_t vendor_id, uint32_t product_id);

    void exchange(DeviceCommand* command);
    DeviceCommand* exchange(const QByteArray& data);

    GetWalletPublicKeyActivity* getWalletPublicKey(Network* network, const QVector<uint32_t>& path) override;
    SignMessageActivity* signMessage(const QString& message, const QVector<uint32_t>& path) override;
    SignTransactionActivity* signTransaction(uint32_t version, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, uint32_t locktime) override;
    GetBlindingKeyActivity* getBlindingKey(const QString& script) override;
    GetBlindingNonceActivity* getBlindingNonce(const QByteArray& pubkey, const QByteArray& script) override;
    SignLiquidTransactionActivity* signLiquidTransaction(uint32_t version, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs) override;
private:
    DevicePrivate* const d;
};

#endif // GREEN_DEVICE_H
