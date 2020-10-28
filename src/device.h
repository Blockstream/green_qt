#ifndef GREEN_DEVICE_H
#define GREEN_DEVICE_H

#include <QtQml>
#include <QObject>

#include <gdk.h>

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
        connect(next, &Command::finished, this, &Command::exec);
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

class GetWalletPublicKeyCommand : public DeviceCommand
{
    Network* const m_network;
    const QVector<uint32_t> m_path;
    const bool m_show_on_screen;
    const bool m_segwit;
    const bool m_segwit_native;
    const bool m_cash_addr;
public:
    GetWalletPublicKeyCommand(Device* device, Network* network, const QVector<uint32_t>& path, bool show_on_screen = false, bool segwit = false, bool segwit_native = false, bool cash_addr = false, CommandBatch* batch = nullptr)
        : DeviceCommand(device, batch)
        , m_network(network)
        , m_path(path)
        , m_show_on_screen(show_on_screen)
        , m_segwit(segwit)
        , m_segwit_native(segwit_native)
        , m_cash_addr(cash_addr)
    {}
    QByteArray payload() const override;
    bool parse(QDataStream& stream) override;
    QString m_xpub;
};

class SignMessageCommand : public DeviceCommand
{
    const QVector<uint32_t> m_path;
    const QByteArray m_message;
public:
    SignMessageCommand(Device* device) : DeviceCommand(device) {}
    SignMessageCommand(Device* device, const QVector<uint32_t>& path, const QByteArray& message, CommandBatch* batch = nullptr)
        : DeviceCommand(device, batch)
        , m_path(path)
        , m_message(message)
    {}
    QByteArray payload() const override;
    bool parse(QDataStream& stream) override;
    QByteArray signature;
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


class DevicePrivate;
class Device : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString interface READ interface NOTIFY interfaceChanged)
    Q_PROPERTY(QString vendor READ vendor NOTIFY vendorChanged)
    Q_PROPERTY(QString product READ product NOTIFY productChanged)
    Q_PROPERTY(QString version READ version NOTIFY versionChanged)

    Q_PROPERTY(Type type READ type CONSTANT)
    Q_PROPERTY(bool busy READ isBusy NOTIFY busyChanged)
    Q_PROPERTY(QString appName READ appName WRITE setAppName NOTIFY appNameChanged)
    QML_ELEMENT
    QML_UNCREATABLE("Devices are instanced by DeviceDiscoveryAgent.")
public:
    enum Type {
        Unknown,
        LedgerNanoS,
        LedgerNanoX
    };
    Q_ENUM(Type)

    explicit Device(DevicePrivate* d, QObject* parent = nullptr);
    ~Device();
    
    Type type() const;
    bool isBusy() const;
    QString appName() const;
    void setAppName(const QString& app_name);

    static Type typefromVendorAndProduct(uint32_t vendor_id, uint32_t product_id);

    void exchange(DeviceCommand* command);
    DeviceCommand* exchange(const QByteArray& data);

    GetWalletPublicKeyCommand* getWalletPublicKey(Network* network, const QVector<uint32_t>& path);
    SignTransactionCommand* signTransaction(const QJsonObject& required_data);
    void startUntrustedTransaction(uint32_t tx_version, bool new_transaction, int64_t input_index, const QList<Input>& used_input, const QByteArray& redeemScript, bool segwit);
    void hashInputs(const QList<Input>& used_inputs, int64_t input_index, const QByteArray& redeem_script);
    void hashInput(const Input& input, const QByteArray& script);
    void finalizeInputFull(const QByteArray& data);
    void signSWInputs(SignTransactionCommand* command, const QList<Input>& hwInputs, const QJsonArray& inputs, uint32_t version, uint32_t locktime);
    void signSWInput(SignTransactionCommand* command, const Input& hwInput, const QJsonObject& input, uint32_t version, uint32_t locktime);
    void untrustedHashSign(SignTransactionCommand* command, const QVector<uint32_t> &private_key_path, QString pin, uint32_t locktime, uint8_t sig_hash_type);

    QString interface() const { return m_interface; }
    QString vendor() const { return m_vendor; }
    QString product() const { return m_product; }
    QString version() const { return m_version; }

signals:
    void appNameChanged();
    void busyChanged();

    void interfaceChanged(const QString& interface);
    void vendorChanged(const QString& vendor);
    void productChanged(const QString& product);
    void versionChanged(const QString& version);

public:
    void setInterface(const QString& interface) { if (m_interface == interface) return; m_interface = interface; emit interfaceChanged(m_interface); }
    void setVendor(const QString& vendor) { if (m_vendor == vendor) return; m_vendor = vendor; emit vendorChanged(m_vendor); }
    void setProduct(const QString& product) { if (m_product == product) return; m_product = product; emit productChanged(m_product); }
    void setVersion(const QString& version) { if (m_version == version) return; m_version = version; emit versionChanged(m_version); }

private:
    DevicePrivate* const d;
    QString m_interface;
    QString m_vendor;
    QString m_product;
    QString m_version;
};

class LedgerLoginController : public QObject
{
    Q_OBJECT
public:
    LedgerLoginController(Device* device, Network* network);
    void login();
    void login2();
private:
    Device* const m_device;
    Network* const m_network;
    GA_json* hw_device;
    Wallet* m_wallet{nullptr};
    GA_auth_handler* m_register_handler;
    GA_auth_handler* m_login_handler;
    QJsonArray m_paths;
    QJsonArray m_xpubs;
};

#endif // GREEN_DEVICE_H
