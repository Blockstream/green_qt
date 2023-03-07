#include "ledgerdevice.h"

#include "activitymanager.h"
#include "command.h"
#include "device_p.h"
#include "ledgergetblindingkeyactivity.h"
#include "ledgergetblindingnonceactivity.h"
#include "ledgergetwalletpublickeyactivity.h"
#include "ledgersignliquidtransactionactivity.h"
#include "ledgersignmessageactivity.h"
#include "ledgersigntransactionactivity.h"
#include "network.h"

LedgerDevice::LedgerDevice(DevicePrivate* d, QObject* parent)
    : Device(parent)
    , d(d)
{
    d->q = this;

    QTimer::singleShot(1000, this, [=] {
        auto activity = getApp();
        QObject::connect(activity, &Activity::finished, this, [=] {
            activity->deleteLater();

            const auto app_name = activity->name();
            const auto app_version = activity->version();

//            qInfo() << "device:" << device->name()
//                    << "app_name:" << app_name
//                    << "app_version:" << app_version;

//            m_controller->setAppVersion(app_version);
            setAppVersion(app_version.toString());
            setAppName(app_name);
        });
//        QObject::connect(activity, &Activity::failed, this, [this, activity] {
//            activity->deleteLater();
//            m_controller->setStatus("error");
//            setStatus(Status::Failed);
//        });
        ActivityManager::instance()->exec(activity);
    });
}

LedgerDevice::~LedgerDevice()
{
    delete d;
}

Device::Type LedgerDevice::type() const
{
    return d->m_type;
}

Device::Transport LedgerDevice::transport() const
{
    return d->m_transport;
}

QString LedgerDevice::name() const
{
    switch (d->m_type) {
    case LedgerNanoS: return "Ledger Nano S";
    case LedgerNanoX: return "Ledger Nano X";
    default: Q_UNREACHABLE();
    }
}

QJsonObject LedgerDevice::details() const
{
    const QString type = d->m_type == LedgerNanoS ? "nanos" : "nanox";
    return {{"type", type}, {"version", m_app_version}, {"name", name()}};
}

DeviceCommand* LedgerDevice::exchange(const QByteArray& data) {
    auto command = new LedgerGenericCommand(this, data);
    command->exec();
    return command;
}

GetWalletPublicKeyActivity *LedgerDevice::getWalletPublicKey(Network* network, const QVector<uint32_t>& path)
{
    return new LedgerGetWalletPublicKeyActivity(network, path, this);
}

SignMessageActivity* LedgerDevice::signMessage(const QString& message, const QVector<uint32_t>& path)
{
    return new LedgerSignMessageActivity(message, path, this);
}

SignMessageActivity* LedgerDevice::signMessage(const QString& message, const QVector<uint32_t>& path, const QByteArray& ae_host_commitment, const QByteArray& ae_host_entropy)
{
    Q_UNREACHABLE();
}

SignTransactionActivity* LedgerDevice::signTransaction(Network* network, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions)
{
    Q_UNUSED(network);
    return new LedgerSignTransactionActivity(transaction, signing_inputs, transaction_outputs, signing_transactions, this);
}

SignLiquidTransactionActivity *LedgerDevice::signLiquidTransaction(Network* network, const QJsonObject &transaction, const QJsonArray &signing_inputs, const QJsonArray &outputs)
{
    Q_ASSERT(network->isLiquid() && network->isMainnet());
    return new LedgerSignLiquidTransactionActivity(transaction, signing_inputs, outputs, this);
}

GetMasterBlindingKeyActivity *LedgerDevice::getMasterBlindingKey()
{
    Q_UNREACHABLE();
}

void LedgerDevice::ping()
{
}

GetBlindingKeyActivity* LedgerDevice::getBlindingKey(const QString& script)
{
    return new LedgerGetBlindingKeyActivity(script, this);
}

GetBlindingNonceActivity* LedgerDevice::getBlindingNonce(const QByteArray& pubkey, const QByteArray& script)
{
    return new LedgerGetBlindingNonceActivity(pubkey, script, this);
}

QByteArray apdu(uint8_t cla, uint8_t ins, uint8_t p1, uint8_t p2, const QByteArray &data)
{
    QByteArray result;
    QDataStream stream(&result, QIODevice::WriteOnly);
    Q_ASSERT(data.length() < 256);
    stream << cla << ins << p1 << p2 << uint8_t(data.length());
    return result + data;
}

QByteArray compressPublicKey(const QByteArray& pubkey)
{
    Q_ASSERT(pubkey.size() > 0);
    switch (pubkey[0]) {
    case 0x04:
        Q_ASSERT(pubkey.size() == 65);
        break;
    case 0x02:
    case 0x03:
        Q_ASSERT(pubkey.size() == 33);
        return pubkey;
    default:
        Q_UNREACHABLE();
    }
    auto type = pubkey[64] & 0x01 ? 0x03 : 0x02;
    return pubkey.mid(1, 32).prepend(type);
}


GetFirmwareActivity::GetFirmwareActivity(LedgerDevice* device)
    : Activity(device)
    , m_device(device)
{
}

void GetFirmwareActivity::exec()
{
    auto command = m_device->exchange(apdu(BTCHIP_CLA, BTCHIP_INS_GET_FIRMWARE_VERSION, 0x00, 0x00));
    connect(command, &Command::finished, [this, command] {
        command->deleteLater();
        QDataStream stream(command->m_response);
        stream >> m_features >> m_arch >> m_fw_major >> m_fw_minor >> m_fw_patch >> m_loader_major >> m_loader_minor;
        Q_ASSERT(m_arch == 0x30);
        //    0x01 : public keys are compressed (otherwise not compressed)
        //    0x02 : implementation running with screen + buttons handled by the Secure Element
        //    0x04 : implementation running with screen + buttons handled externally
        //    0x08 : NFC transport and payment extensions supported
        //    0x10 : BLE transport and low power extensions supported
        //    0x20 : implementation running on a Trusted Execution Environment
        qDebug() << m_features << m_arch << m_fw_major << m_fw_minor << m_fw_patch << m_loader_major << m_loader_minor;
        finish();
    });
    connect(command, &Command::error, [this, command] {
        command->deleteLater();
        fail();
    });
}

GetAppActivity::GetAppActivity(LedgerDevice* device)
    : Activity(device)
    , m_device(device)
{
}

QString GetAppActivity::name() const
{
    return m_name;
}

QVersionNumber GetAppActivity::version() const
{
    return m_version;
}

void GetAppActivity::exec()
{
    auto command = m_device->exchange(apdu(BTCHIP_CLA_COMMON_SDK, BTCHIP_INS_GET_APP_NAME_AND_VERSION, 0x00, 0x00));
    connect(command, &Command::finished, [this, command] {
        command->deleteLater();

        QDataStream stream(command->m_response);
        uint8_t format;
        stream >> format;

        char* name = new char[256];
        char* version = new char[256];

        uint8_t name_length, version_length;

        stream >> name_length;
        stream.readRawData(name, name_length);
        stream >> version_length;
        stream.readRawData(version, version_length);

        m_name = QString::fromLocal8Bit(name, name[name_length - 1] ? name_length : name_length - 1);
        auto version_string = QString::fromLocal8Bit(version, version[version_length - 1] ? version_length : version_length - 1);
        if (version_string.startsWith('.')) version_string.prepend('1');

        m_version = QVersionNumber::fromString(version_string);

        finish();
    });
    connect(command, &Command::error, [this, command] {
        command->deleteLater();
        fail();
    });
}

GetFirmwareActivity *LedgerDevice::getFirmware()
{
    return new GetFirmwareActivity(this);
}

GetAppActivity* LedgerDevice::getApp()
{
    return new GetAppActivity(this);
}

void LedgerDevice::setAppVersion(const QString& app_version)
{
    if (m_app_version == app_version) return;
    m_app_version = app_version;
    emit appVersionChanged();
}

void LedgerDevice::setAppName(const QString& app_name)
{
    if (m_app_name == app_name) return;
    m_app_name= app_name;
    emit appNameChanged();
}

DevicePrivate* DevicePrivate::get(LedgerDevice* device)
{
    return device->d;
}

LedgerGenericCommand::LedgerGenericCommand(LedgerDevice *device, const QByteArray &data)
    : GenericCommand(device, data)
    , m_device(device)
{
}

void LedgerGenericCommand::exec()
{
    DevicePrivate::get(m_device)->exchange(this);
}

void varInt(QDataStream &stream, int64_t i)
{
    switch (varIntSize(i)) {
    case 1:
        stream << uint8_t(i);
        break;
    case 3:
        stream << uint8_t(253) << uint8_t(i & 0xff) << uint8_t((i >> 8) & 0xff);
        break;
    case 5:
        stream << uint8_t(254) << uint32_t(i);
        break;
    default:
        stream << uint8_t(255) << qint64(i);
    }
}

int varIntSize(int i) {
    // if negative, it's actually a very large unsigned long value
    if (i < 0) return 9; // 1 marker + 8 data bytes
    if (i< 253) return 1; // 1 data byte
    if (i <= 0xFFFF) return 3; // 1 marker + 2 data bytes
    if (i <= 0xFFFFFFFF) return 5; // 1 marker + 4 data bytes
    return 9; // 1 marker + 8 data bytes
}

QDataStream &operator<<(QDataStream &out, const Varint<uint32_t> &v)
{
    if (v.v < 0xfd) return out << uint8_t(v.v & 0xff);
    if (v.v < 0xffff) return out << uint8_t(0xfd) << uint8_t(v.v & 0xff) << uint8_t((v.v >> 8) & 0xff);
    return out << uint8_t(0xfe) << v.v;
}
