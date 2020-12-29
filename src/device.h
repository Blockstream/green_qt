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

struct Input {
    QByteArray value;
    QByteArray sequence;
    bool trusted;
    bool segwit;
};

class SignTransactionCommand : public DeviceCommand
{
public:
    SignTransactionCommand(Device* device, CommandBatch* batch = nullptr)
        : DeviceCommand(device, batch) {}
    virtual QByteArray payload() const override { return {}; };
    virtual bool parse(QDataStream& stream) override { return true; };
    int count{0};
    QList<QByteArray> signatures;
};

class GetBlindingKeyCommand : public DeviceCommand
{
    const QString m_script;
public:
    GetBlindingKeyCommand(Device* device, const QString& script, CommandBatch* batch = nullptr)
        : DeviceCommand(device, batch)
        , m_script(script)
    {}
    QByteArray payload() const override;
    bool parse(const QByteArray& data) override;
    QByteArray m_pubkey;
};

class GetBlindingNonceCommand : public DeviceCommand
{
    QByteArray m_pubkey;
    QByteArray m_script;
public:
    GetBlindingNonceCommand(Device* device, const QByteArray& pubkey, const QByteArray& script, CommandBatch* batch = nullptr)
        : DeviceCommand(device, batch)
        , m_pubkey(pubkey), m_script(script)
    {}
    QByteArray payload() const override;
    bool parse(const QByteArray& data) override;
    QByteArray m_nonce;
};

// TODO: this and SignTransactionCommands don't really write/read from the device
// should improve/clarify what commands are
class SignLiquidTransactionCommand : public DeviceCommand
{
    Q_OBJECT
public:
    // TODO these should be removed
    virtual QByteArray payload() const override { return {}; };

    SignLiquidTransactionCommand(Device* device, const QJsonObject& required_data, CommandBatch* batch = nullptr);

    void exec() override;
    void getLiquidCommitment(int output_index);

    DeviceCommand* exchange(const QByteArray& data);
    QJsonObject m_required_data;
    QJsonObject m_transaction;
    int64_t m_version;
    QList<quint64> m_values;
    QList<QByteArray> m_abfs;
    QList<QByteArray> m_vbfs;
    QJsonArray m_inputs;
    QJsonArray m_outputs;
    QList<QByteArray> m_hw_inputs;
    QList<QByteArray> m_hw_sequences;

    QList<QByteArray> m_commitments;

    QList<QByteArray> m_sigs;
    QList<QByteArray> m_asset_commitments;
    QList<QByteArray> m_value_commitments;

    QList<QPair<QJsonObject, QByteArray>> m_output_liquid_bytes;

    int count{0};
    void startUntrustedTransaction(bool new_transaction, int input_index, const QList<QByteArray> &inputs, const QList<QByteArray> &sequences, const QByteArray &redeem_script);
    void finalizeLiquidInputFull();
    QList<QPair<QJsonObject, QByteArray>> outputLiquidBytes();
    int exchange_count{0};
    int exchange_total{0};
    CommandBatch* m_batch;
signals:
    void progressChanged(int progress, int total);
    void message(const QJsonObject& message);
};

using GetWalletPublicKeyActivity = Command2<QString>;
using SignMessageActivity = Command2<QByteArray>;
using SignTransactionActivity = Command2<QList<QByteArray>>;

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
    virtual SignTransactionActivity* signTransaction(const QJsonObject& required_data) = 0;
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
    SignTransactionActivity* signTransaction(const QJsonObject& required_data) override;
    GetBlindingKeyCommand *getBlindingKey(const QString &script);
    GetBlindingNonceCommand *getBlindingNonce(const QByteArray& pubkey, const QByteArray& script);
private:
    DevicePrivate* const d;
};

#endif // GREEN_DEVICE_H
