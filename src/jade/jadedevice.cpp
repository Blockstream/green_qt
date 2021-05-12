/***************************************************************************
**
** Copyright (C) 2013 BlackBerry Limited. All rights reserved.
** Copyright (C) 2017 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the QtBluetooth module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include "jadedevice.h"

#include <qbluetoothaddress.h>
#include <qbluetoothdevicediscoveryagent.h>
#include <qbluetoothlocaldevice.h>
#include <qbluetoothdeviceinfo.h>
#include <qbluetoothservicediscoveryagent.h>
#include <QDebug>
#include <QList>
#include <QMetaEnum>
#include <QTimer>
#include <QSerialPortInfo>
#include <QNetworkAccessManager>

#include "jadeapi.h"

#include <wally_crypto.h>
#include <wally_elements.h>

JadeDeviceSerialPortDiscoveryAgent2::JadeDeviceSerialPortDiscoveryAgent2(QObject* parent)
    : QObject(parent)
    , m_jade(nullptr)
{
    //! [les-devicediscovery-1]
    discoveryAgent = new QBluetoothDeviceDiscoveryAgent(this);
    discoveryAgent->setLowEnergyDiscoveryTimeout(5000);
    localDevice = new QBluetoothLocalDevice(this);

    connect(discoveryAgent, QOverload<QBluetoothDeviceDiscoveryAgent::Error>::of(&QBluetoothDeviceDiscoveryAgent::error),
            this, &JadeDeviceSerialPortDiscoveryAgent2::deviceScanError);
    connect(discoveryAgent, &QBluetoothDeviceDiscoveryAgent::finished, this, &JadeDeviceSerialPortDiscoveryAgent2::deviceScanFinished);

    connect(localDevice, SIGNAL(error(QBluetoothLocalDevice::Error))
            , this, SLOT(pairingError(QBluetoothLocalDevice::Error)));
    connect(localDevice, SIGNAL(pairingFinished(QBluetoothAddress,QBluetoothLocalDevice::Pairing))
            , this, SLOT(pairingDone(QBluetoothAddress,QBluetoothLocalDevice::Pairing)));

    setUpdate("Search");
}

JadeDeviceSerialPortDiscoveryAgent2::~JadeDeviceSerialPortDiscoveryAgent2()
{
    qDeleteAll(m_devices);
    m_devices.clear();
}

bool JadeDeviceSerialPortDiscoveryAgent2::state()
{
    return m_deviceScanState;
}

QVariant JadeDeviceSerialPortDiscoveryAgent2::getDevices()
{
    return QVariant::fromValue(m_devices);
}

QVariant JadeDeviceSerialPortDiscoveryAgent2::getServices()
{
    return QVariant::fromValue(m_services);
}

QString JadeDeviceSerialPortDiscoveryAgent2::getUpdate()
{
    return m_message;
}

void JadeDeviceSerialPortDiscoveryAgent2::setUpdate(const QString &message)
{
    m_message = message;
    emit updateChanged();
}

void JadeDeviceSerialPortDiscoveryAgent2::disconnectFromDevice()
{
    disconnectJade();
}

void JadeDeviceSerialPortDiscoveryAgent2::startDeviceDiscovery()
{
    qDeleteAll(m_devices);
    m_devices.clear();
    emit devicesUpdated();

    setUpdate("Scanning for devices ...");
    return deviceScanFinished();

    //! [les-devicediscovery-2]
    discoveryAgent->start(QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
    //! [les-devicediscovery-2]

    if (discoveryAgent->isActive()) {
        m_deviceScanState = true;
        Q_EMIT stateChanged();
    }
}

void JadeDeviceSerialPortDiscoveryAgent2::deviceScanError(QBluetoothDeviceDiscoveryAgent::Error error)
{
    if (error == QBluetoothDeviceDiscoveryAgent::PoweredOffError)
        setUpdate("The Bluetooth adaptor is powered off, power it on before doing discovery.");
    else if (error == QBluetoothDeviceDiscoveryAgent::InputOutputError)
        setUpdate("The Bluetooth adapter is in airplane mode, please power it on before doing discovery");
    // FIXME: detect this and allow the user to continue without BLE
    else {
        static QMetaEnum qme = discoveryAgent->metaObject()->enumerator(
                    discoveryAgent->metaObject()->indexOfEnumerator("Error"));
        setUpdate("Error: " + QLatin1String(qme.valueToKey(error)));
    }

    m_deviceScanState = false;
    emit devicesUpdated();
    emit stateChanged();
}

void JadeDeviceSerialPortDiscoveryAgent2::deviceScanFinished()
{
    qDebug() << "Finished scanning for devices";

    const QList<QBluetoothDeviceInfo> foundDevices = discoveryAgent->discoveredDevices();
    for (auto nextDevice : foundDevices) {
        const QString name = nextDevice.name();
        // FIXME: use serviceUuids() here, once Jade fixed to publish correct uuid in advertising packet
        if (name.startsWith("Jade ") && name.size() == 11 && nextDevice.coreConfigurations() & QBluetoothDeviceInfo::LowEnergyCoreConfiguration)
            m_devices.append(new DeviceInfo(nextDevice));
    }

    const auto serialPortInfos = QSerialPortInfo::availablePorts();
    QString description;
    QString manufacturer;
    QString vendorId;
    QString productId;

    for (const auto &serialPortInfo : serialPortInfos) {
        description = serialPortInfo.description();
        manufacturer = serialPortInfo.manufacturer();
        vendorId = QByteArray::number(serialPortInfo.vendorIdentifier(), 16);
        productId = QByteArray::number(serialPortInfo.productIdentifier(), 16);

        if (productId == "ea60" && vendorId == "10c4" && description == "CP2104 USB to UART Bridge Controller" && manufacturer == "Silicon Labs" && !serialPortInfo.isBusy()) {
            m_devices.append(new DeviceInfo(serialPortInfo));

        }
    }

    emit devicesUpdated();
    m_deviceScanState = false;
    emit stateChanged();
    if (m_devices.isEmpty())
        setUpdate("No Jade found...");
    else
        setUpdate("Done! Scan Again!");
    qWarning() << "deviceScanFinished";

}

void JadeDeviceSerialPortDiscoveryAgent2::scanServices(const QString &address)
{
    qWarning() << "scanServices invoked with address" << address;
    // hack, clean up
    if (address.contains(":")) {
        // BLE _ have to request pairing before we can create a JadeAPI
        const QBluetoothAddress jade = QBluetoothAddress(address);
        localDevice->requestPairing(jade, QBluetoothLocalDevice::AuthorizedPaired);
        qWarning() << "Pairing requested ..";
    } else {
        // Serial - can create new JadeAPI instance immediately

        // We need the current device for service discovery.
        for (auto d: qAsConst(m_devices)) {
            if (auto device = qobject_cast<DeviceInfo *>(d)) {
                if (device->getAddress() == address) {
                    currentDevice.setSerialDevice(device->getSerialDevice());
                    break;
                }
            }
        }

        // Create new JadeAPI on thi serial device
        const QSerialPortInfo dev = currentDevice.getSerialDevice();
        connectJade(new JadeAPI(dev, this));
    }
}

void JadeDeviceSerialPortDiscoveryAgent2::pairingError(QBluetoothLocalDevice::Error error)
{
    qWarning() << "Pairing failed" << error;
    deviceDisconnected();
}

void JadeDeviceSerialPortDiscoveryAgent2::pairingDone(const QBluetoothAddress &address, QBluetoothLocalDevice::Pairing pairing)
{
    qWarning() << "pairing done " << address.toString() << pairing;
    if (pairing == QBluetoothLocalDevice::AuthorizedPaired) {
        qWarning() << "Pairing successfull";

        // We need the current device for service discovery.
        for (auto d: qAsConst(m_devices)) {
            if (auto device = qobject_cast<DeviceInfo *>(d)) {
                if (device->getAddress() == address.toString()) {
                    currentDevice.setBluetoothDevice(device->getBluetoothDevice());
                    break;
                }
            }
        }

        if (!currentDevice.getBluetoothDevice().isValid()) {
            qWarning() << "Not a valid ble device " << address;
            return;
        }

        // Create new JadeAPI on this BLE device
        const QBluetoothDeviceInfo dev = currentDevice.getBluetoothDevice();
        connectJade(new JadeAPI(dev, this));

        setUpdate("Back\n(Connecting to device...)");
    } else {
        qWarning() << "Pairing failed";
    }
    qWarning() << "pairingDone finished";
}

void JadeDeviceSerialPortDiscoveryAgent2::deviceDisconnected()
{
    qWarning() << "Disconnect from device";
    resetJadePtr();
    m_services.clear();
    m_compressed_fw.clear();
    emit disconnected();
}

// Start process to update jade firmware
// Downloads firmware if need be, then starts ota process
void JadeDeviceSerialPortDiscoveryAgent2::updateJadeFirmware()
{
    // If no firmware downloaded, fetch firmwares available,
    // then the fw variant of choice, and then call start_ota().
    if (m_compressed_fw.size() == 0) {
        QNetworkAccessManager *nam = new QNetworkAccessManager(this);
        connect(nam, &QNetworkAccessManager::finished,
                [nam, this](QNetworkReply *reply) {
            onFirmwareIndexResult(reply);
            reply->deleteLater();
            nam->deleteLater();
        });

        const QUrl url("https://jadefw.blockstream.com/bin/LATEST");
        nam->get(QNetworkRequest(url));
    }
    else
    {
        // Already loaded firmware, start the OTA immediately
        startOTA();
    }
}

// Download LATEST file, and then start downloading the latest firmware
void JadeDeviceSerialPortDiscoveryAgent2::onFirmwareIndexResult(QNetworkReply *reply) {

    if(reply->error() == QNetworkReply::NoError) {

        const QString strReply = static_cast<QString>(reply->readAll());
        QString fw_to_download;
        qDebug() << strReply;
        if (!strReply.isEmpty()) {

            const QStringList splits = strReply.trimmed().split("\n");
            QString variant = qgetenv("JADE_VARIANT");

            if (variant.isEmpty()) {
                variant = m_version["JADE_CONFIG"].toString().toLower();
            }

            QString version;
            for (const QString& split : splits) {
                if (split.contains(variant)) {
                    version = split;
                    break;
                }
            }

            if (!version.isEmpty()) {
                // also http://vgza7wu4h7osixmrx6e4op5r72okqpagr3w6oupgsvmim4cz3wzdgrad.onion/
                fw_to_download = "https://jadefw.blockstream.com/bin/" + version;
                m_uncompressed_fw_size = version.split("_")[2].toInt();
                m_fw_name = version;

                qWarning() << "Downloading" << fw_to_download;

                QNetworkAccessManager *nam = new QNetworkAccessManager(this);
                connect(nam, &QNetworkAccessManager::finished,
                        [nam, this](QNetworkReply *reply) {
                    onFirmwareDownloaded(reply);
                    reply->deleteLater();
                    nam->deleteLater();
                });

                nam->get(QNetworkRequest(fw_to_download));
            } else {
                // show error
                qWarning() << "bad variant" << variant;
            }
        } else {
            qWarning() << "ERROR 1 onFirmwareIndexResult";
        }

    } else {
        qWarning() << "ERROR 2 onFirmwareIndexResult";

        // FIXME: user can't continue without ota, show them a retry/error msg
        m_devices.clear();
        setUpdate("Error: Couldn't download latest firmware" + reply->errorString());
        m_deviceScanState = false;
        emit devicesUpdated();
        emit stateChanged();
    }
}

// Firmware downloaded - start OTA upload process
void JadeDeviceSerialPortDiscoveryAgent2::onFirmwareDownloaded(QNetworkReply *reply) {

    if(reply->error() == QNetworkReply::NoError) {
        m_compressed_fw = reply->readAll();
        qDebug() << "FW downloaded" << reply->url() << "uncompressed " << m_uncompressed_fw_size << "compressed" << m_compressed_fw.size();
        startOTA();
    } else {
        qDebug() << "ERROR onFirmwareDownloaded";
        // FIXME: user can't continue without ota, show them a retry/error msg
        m_devices.clear();
        setUpdate("Error: Couldn't download latest firmware" + reply->errorString());
        m_deviceScanState = false;
        emit devicesUpdated();
        emit stateChanged();
    }
}

// Function to start the OTA upload process
void JadeDeviceSerialPortDiscoveryAgent2::startOTA() {
    Q_ASSERT(!m_compressed_fw.isEmpty());
    Q_ASSERT(!m_version.isEmpty());

    if (!m_jade || !m_jade->isConnected())
    {
        qWarning() << "start_ota() called but no connected Jade";
        disconnectJade();
        return;
    }
}

void JadeDeviceSerialPortDiscoveryAgent2::resetJadePtr(JadeAPI *jade)
{
    // Disconnect/free prior jade device
    if (m_jade) {
        disconnect(m_jade, nullptr, this, nullptr);
        m_jade->disconnectDevice();
        m_jade->deleteLater();
    }

    // Set new jade device
    m_jade = jade;

    // Hook up on-connected and on-disconnected signal callbacks
    if (m_jade)
    {
        connect(m_jade, &JadeAPI::onConnected,
                this, &JadeDeviceSerialPortDiscoveryAgent2::onJadeConnected);
        connect(m_jade, &JadeAPI::onDisconnected,
                this, &JadeDeviceSerialPortDiscoveryAgent2::onJadeDisconnected);
    }
}

void JadeDeviceSerialPortDiscoveryAgent2::connectJade(JadeAPI *jade)
{
    Q_ASSERT(jade);
    resetJadePtr(jade);
    m_jade->connectDevice();
}

void JadeDeviceSerialPortDiscoveryAgent2::onJadeConnected()
{
    if (!m_jade || m_jade != sender())
    {
        qWarning() << "Unexpected call to onJadeConnected()";
        return;
    }

#ifndef QT_NO_DEBUG
    // Maybe run tests rather than OTA
    if(false)
    {
//        TestJade *tester = new TestJade(m_jade);
//        connect(tester, &TestJade::testComplete,
//                [](const QString& name)
//                {
//                    qInfo() << name << "ok";
//                });
//        connect(tester, &TestJade::allTestsComplete,
//                [this](const int ntests)
//                {
//                    qInfo() << "Completed" << ntests << "tests, disconnecting Jade";
//                    disconnectJade();
//                });

//        // Kick off the tests, and that's all
//        tester->runAllTests();
//        return;
    }
#endif

    m_jade->getVersionInfo([this](const QVariantMap& msg) {
        if (!msg.contains("result"))
        {
            qWarning() << "Error fetching version info";
            disconnectJade();
        }

        // Attach a new 'service info' object
        m_services.append(new ServiceInfo(new JadeDevice2()));
        emit servicesUpdated();

        // Store version info
        m_version = msg["result"].toMap();

        // If Jade has pin, do auth_user and only call to update
        // the firmware if/when the user has authenticated.
        if (m_version["JADE_HAS_PIN"].toBool())
        {
            // auth the user on the jade hw
            // Cheeky way to get a handful of random to pass to entropy function
            const QByteArray noise = QUuid::createUuid().toByteArray();
            m_jade->addEntropy(noise, [this](const QVariantMap& msg) {
                if (!msg.contains("result") || !msg["result"].toBool())
                {
                    qWarning() << "Error uploading entropy";
                    disconnectJade();
                }

                // Log-in/pin on the hardware
                m_jade->authUser("liquid", [this](const QVariantMap& msg) {
                    if (!msg.contains("result") || !msg["result"].toBool())
                    {
                        qWarning() << "Error authorising user on Jade";
                        disconnectJade();
                    }

                    // Start the fw download/upload process
                    updateJadeFirmware();
                });
            });
        }
        else
        {
            // No PIN set - start the fw download/upload process immediately
            updateJadeFirmware();
        }
    });
}

void JadeDeviceSerialPortDiscoveryAgent2::disconnectJade()
{
    onJadeDisconnected();
}

void JadeDeviceSerialPortDiscoveryAgent2::onJadeDisconnected()
{
    deviceDisconnected();
}


#include "network.h"
class JadeGetWalletPublicKeyActivity : public GetWalletPublicKeyActivity
{
    JadeDevice* const m_device;
    Network* const m_network;
    const QVector<uint32_t> m_path;
    QByteArray m_public_key;
public:
    JadeGetWalletPublicKeyActivity(Network* network, const QVector<uint32_t>& path, JadeDevice* device)
        : GetWalletPublicKeyActivity(device)
        , m_device(device), m_network(network), m_path(path)
    {
    }
    QByteArray publicKey() const override {
        return m_public_key;
    }
    void exec() override
    {
        m_device->m_jade->getXpub(m_network->id(), m_path, [this](const QVariantMap& msg) {
            Q_ASSERT(msg.contains("result") && msg["result"].type() == QVariant::String);
            m_public_key = msg["result"].toString().toLocal8Bit();
            finish();
        });
    }
};

class JadeSignMessageActivity : public SignMessageActivity
{
    JadeDevice* const m_device;
    const QString m_message;
    const QVector<uint32_t> m_path;
    QByteArray m_signature;
public:
    JadeSignMessageActivity(const QString& message, const QVector<uint32_t>& path, JadeDevice* device)
        : SignMessageActivity(device)
        , m_device(device)
        , m_message(message)
        , m_path(path)
    {}
    QByteArray signature() const override
    {
        return m_signature;
    }
    virtual void exec() override
    {
        m_device->m_jade->signMessage(m_path, m_message, [this](const QVariantMap& result) {
            Q_ASSERT(result.contains("result") && result["result"].type() == QVariant::String);
            auto sig = QByteArray::fromBase64(result["result"].toString().toLocal8Bit());
            if (sig.size() == EC_SIGNATURE_RECOVERABLE_LEN) sig = sig.mid(1);
            Q_ASSERT(sig.size() == EC_SIGNATURE_LEN);
            QByteArray xxx(EC_SIGNATURE_DER_MAX_LEN, 0);
            size_t yyy;
            wally_ec_sig_to_der((const unsigned char*) sig.constData(), sig.size(), (unsigned char*) xxx.data(), EC_SIGNATURE_DER_MAX_LEN, &yyy);
            m_signature = QByteArray(xxx.constData(), yyy);
            finish();
        });
    }
};

#include "util.h"

class JadeSignTransactionActivity : public SignTransactionActivity
{
    JadeDevice* const m_device;
    Network* const m_network;
    const QJsonObject m_transaction;
    const QJsonArray m_signing_inputs;
    const QJsonArray m_transaction_outputs;
    const QJsonObject m_signing_transactions;
    const QJsonArray m_signing_address_types;
    QList<QByteArray> m_signatures;
public:
    JadeSignTransactionActivity(Network* network, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions, const QJsonArray& signing_address_types, JadeDevice* device)
        : SignTransactionActivity(device)
        , m_device(device)
        , m_network(network)
        , m_transaction(transaction)
        , m_signing_inputs(signing_inputs)
        , m_transaction_outputs(transaction_outputs)
        , m_signing_transactions(signing_transactions)
        , m_signing_address_types(signing_address_types)
    {
        Q_ASSERT(!m_signing_address_types.contains("pwpkh"));
        Q_ASSERT(!m_signing_transactions.isEmpty());
    }

    QList<QByteArray> signatures() const override { return m_signatures; }

    static QVariantList ParsePath(const QJsonValue& value)
    {
        QVariantList path;
        for (const auto p : ::ParsePath(value)) path.append(p);
        return path;
    }

    void exec() override
    {
        const auto txn = ParseByteArray(m_transaction.value("transaction"));
        QVariantList inputs;
        QVariantList change;

        for (const auto value : m_signing_inputs) {
            const auto input = value.toObject();
            const bool sw_input = input.value("address_type") != "p2sh";
            const auto script = ParseByteArray(input.value("prevout_script"));

            if (sw_input && m_signing_inputs.size() == 1) {
                inputs.append(QVariantMap({
                    { "is_witness", true },
                    { "input_tx", QVariant() },
                    { "script", script },
                    { "satoshi", ParseSatoshi(input.value("satoshi")) },
                    { "path", ParsePath(input.value("user_path")) },
                }));
            } else {
                const auto input_tx = ParseByteArray(m_signing_transactions.value(input.value("txhash").toString()));
                Q_ASSERT(!input_tx.isEmpty());
                inputs.append(QVariantMap({
                    { "is_witness", true },
                    { "input_tx", input_tx },
                    { "script", script },
                    { "satoshi", ParseSatoshi(input.value("satoshi")) },
                    { "path", ParsePath(input.value("user_path")) },
                }));
            }
        }

        for (const auto& value : m_transaction_outputs) {
            const auto output = value.toObject();
            const bool is_change = output.value("is_change").toBool();
            if (is_change) {
                const auto path = ParsePath(output.value("user_path"));
                const auto recovery_xpub = output.value("recovery_xpub").toString();
                const auto csv_blocks = output.value("address_type").toString() == "csv" ? output.value("subtype").toInt() : 0;
                const QVariantMap data = {
                    { "path", path },
                    { "recovery_xpub", recovery_xpub },
                    { "csv_blocks", csv_blocks },
                };
                change.append(data);
            } else {
                change.append(QVariant());
            }
        }

        m_device->m_jade->signTx(m_network->id(), txn, inputs, change, [this](const QVariantMap& result) {
            if (result.contains("result") && result["result"].type() == QVariant::List) {
                for (const auto& s : result["result"].toList()) {
                    m_signatures.append(s.toByteArray());
                }
                finish();
            } else {
                fail();
            }
        });
    }
};

class JadeGetBlindingKeyActivity : public GetBlindingKeyActivity
{
    JadeDevice* const m_device;
    const QString m_script;
    QByteArray m_public_key;
public:
    JadeGetBlindingKeyActivity(const QString& script, JadeDevice* device)
        : GetBlindingKeyActivity(device)
        , m_device(device)
        , m_script(script)
    {
    }
    QByteArray publicKey() const override
    {
        return m_public_key;
    }
    void exec() override
    {
        // TODO: the following QByteArray::fromHex should be done in resolver (and refactor ledger activity)
        const auto script = QByteArray::fromHex(m_script.toLocal8Bit());
        m_device->m_jade->getBlindingKey(script, [this](const QVariantMap& msg) {
            Q_ASSERT(msg.contains("result") && msg["result"].type() == QVariant::ByteArray);
            m_public_key = msg["result"].toByteArray();
            finish();
        });
    }
};

class JadeGetBlindingNonceActivity : public GetBlindingNonceActivity
{
    JadeDevice* const m_device;
    const QByteArray m_pubkey;
    const QByteArray m_script;
    QByteArray m_nonce;
public:
    JadeGetBlindingNonceActivity(const QByteArray& pubkey, const QByteArray& script, JadeDevice* device)
        : GetBlindingNonceActivity(device)
        , m_device(device)
        , m_pubkey(pubkey)
        , m_script(script)
    {
    }
    QByteArray nonce() const override
    {
        return m_nonce;
    }
    void exec() override
    {
        m_device->m_jade->getSharedNonce(m_script, m_pubkey, [this](const QVariantMap& msg) {
            Q_ASSERT(msg.contains("result") && msg["result"].type() == QVariant::ByteArray);
            m_nonce = msg["result"].toByteArray();
            finish();
        });
    }
};

class JadeSignLiquidTransactionActivity : public SignLiquidTransactionActivity
{
    JadeDevice* const m_device;
    const QJsonObject m_transaction;
    const QJsonArray m_signing_inputs;
    const QJsonArray m_outputs;

    QVariantList m_inputs;
    QVector<uint64_t> m_values;
    QList<QByteArray> m_abfs;
    QList<QByteArray> m_vbfs;
    QByteArray m_hash_prev_outs;
    int m_last_blinded_index;
    QVariantList m_change;
    QVariantList m_trusted_commitments;
    QByteArray m_last_vbf;

    QList<QByteArray> m_signatures;
    QList<QByteArray> m_asset_commitments;
    QList<QByteArray> m_value_commitments;
    QList<QByteArray> m_asset_blinders;
    QList<QByteArray> m_amount_blinders;
private:
    static QVariantList ParsePath(const QJsonValue& value)
    {
        QVariantList path;
        for (const auto p : ::ParsePath(value)) path.append(p);
        return path;
    }
public:
    JadeSignLiquidTransactionActivity(const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, JadeDevice* device)
        : SignLiquidTransactionActivity(device)
        , m_device(device)
        , m_transaction(transaction)
        , m_signing_inputs(signing_inputs)
        , m_outputs(outputs)
    {
        m_last_blinded_index = m_outputs.size();
        while (--m_last_blinded_index >= 0) {
            const auto output = m_outputs.at(m_last_blinded_index).toObject();
            if (!output.value("is_fee").toBool()) break;
        }
        Q_ASSERT(m_last_blinded_index >= 0);
    }
    QList<QByteArray> signatures() const override { return m_signatures; };
    QList<QByteArray> assetCommitments() const override { return m_asset_commitments; }
    QList<QByteArray> valueCommitments() const override { return m_value_commitments; }
    QList<QByteArray> assetBlinders() const override { return m_asset_blinders; }
    QList<QByteArray> amountBlinders() const override { return m_amount_blinders; }
    void exec() override
    {
        QByteArray prevouts;
        QDataStream stream_prevouts(&prevouts, QIODevice::WriteOnly);
        stream_prevouts.setByteOrder(QDataStream::LittleEndian);

        for (const auto value : m_signing_inputs) {
            const auto input = value.toObject();
            const auto address_type = input.value("address_type").toString();
            const bool is_segwit = address_type != "p2sh";
            const auto script = ParseByteArray(input.value("prevout_script"));
            const auto value_commitment = ParseByteArray(input.value("commitment"));
            const auto path = ParsePath(input.value("user_path"));
            m_inputs.append(QVariantMap({
                { "is_witness", is_segwit },
                { "script", script },
                { "value_commitment", value_commitment },
                { "path", path }
            }));

            m_values.append(ParseSatoshi(input.value("satoshi")));
            m_abfs.append(ReverseByteArray(ParseByteArray(input.value("assetblinder"))));
            m_vbfs.append(ReverseByteArray(ParseByteArray(input.value("amountblinder"))));

            const auto txid = ReverseByteArray(ParseByteArray(input.value("txhash")));
            stream_prevouts.writeRawData(txid.constData(), txid.size());
            stream_prevouts << input.value("pt_idx").toInt();
        }

        QByteArray out(SHA256_LEN, 0);
        wally_sha256d((const unsigned char*) prevouts.constData(), prevouts.size(), (unsigned char*) out.data(), out.size());
        m_hash_prev_outs = out;

        for (const auto value : m_outputs) {
            const auto output = value.toObject();
            const auto satoshi = ParseSatoshi(output.value("satoshi"));
            if (!output.value("is_fee").toBool()) {
                m_values.append(satoshi);
            }
            if (output.value("is_change").toBool()) {
                const auto path = ParsePath(output.value("user_path"));
                const auto recovery_xpub = output.value("recovery_xpub").toString();
                const auto csv_blocks = output.value("address_type").toString() == "csv" ? output.value("subtype").toInt() : 65535;
                const QVariantMap data = {
                    { "path", path },
                    { "recovery_xpub", recovery_xpub },
                    { "csv_blocks", csv_blocks },
                };
                m_change.append(data);
            } else {
                m_change.append(QVariant());
            }
        }

        progress()->setIndeterminate(false);
        progress()->setTo(m_outputs.size() + 1 + 1 + m_inputs.size());

        nextTrustedCommitment(0);
    }
    void nextTrustedCommitment(int index) {

        const auto output = m_outputs.at(index).toObject();

        if (output.value("is_fee").toBool()) {
            return nextTrustedCommitment(index + 1);
        }

        if (index == m_last_blinded_index && m_last_vbf.isEmpty()) {
            m_device->m_jade->getBlindingFactor(m_hash_prev_outs, index, "ASSET", [this, index](const QVariantMap& msg) {
                if (handleError(msg)) return;
                progress()->incrementValue();

                Q_ASSERT(msg.contains("result") && msg["result"].type() == QVariant::ByteArray);
                m_abfs.append(msg["result"].toByteArray());
                const auto abf = m_abfs.join();
                const auto vbf = m_vbfs.join();

                QByteArray out(BLINDING_FACTOR_LEN, 0);
                int res = wally_asset_final_vbf(
                            m_values.constData(), m_values.size(),
                            m_inputs.size(),
                            (const unsigned char*) abf.constData(), abf.size(),
                            (const unsigned char*) vbf.constData(), vbf.size(),
                            (unsigned char*) out.data(), out.size());
                Q_ASSERT(res == WALLY_OK);

                m_last_vbf = out;
                m_vbfs.append(m_last_vbf);

                nextTrustedCommitment(index);
            });
            return;
        }

        const auto asset_id = ParseByteArray(output.value("asset_id"));
        const auto blinding_key = ParseByteArray(output.value("public_key"));
        const auto satoshi = ParseSatoshi(output.value("satoshi"));

        m_device->m_jade->getCommitments(asset_id, satoshi, m_hash_prev_outs, index, m_last_vbf, [this, index, blinding_key](const QVariantMap& msg) {
            if (handleError(msg)) return;
            progress()->incrementValue();

            Q_ASSERT(msg.contains("result") && msg["result"].type() == QVariant::Map);
            auto commitment = msg["result"].toMap();

            m_abfs.append(commitment.value("abf").toByteArray());
            m_vbfs.append(commitment.value("vbf").toByteArray());

            commitment["blinding_key"] = blinding_key;
            m_trusted_commitments.append(commitment);

            if (index == m_last_blinded_index) {
                m_trusted_commitments.append(QVariantMap());
                sign();
            } else {
                nextTrustedCommitment(index + 1);
            }
        });
    }
    void sign()
    {
        const auto tx = ParseByteArray(m_transaction.value("transaction"));
        m_device->m_jade->signLiquidTx("liquid", tx, m_inputs, m_trusted_commitments, m_change, [this](const QVariantMap& msg) {
            if (handleError(msg)) return;
            progress()->incrementValue();
            Q_ASSERT(msg.contains("result") && msg["result"].type() == QVariant::List);
            for (const auto& signature : msg["result"].toList()) {
                m_signatures.append(signature.toByteArray());
            }
            for (const auto& value : m_trusted_commitments) {
                const auto commitment = value.toMap();
                if (commitment.isEmpty() || commitment["asset_id"].isNull()) {
                    m_asset_commitments.append(QByteArray());
                    m_value_commitments.append(QByteArray());
                    m_asset_blinders.append(QByteArray());
                    m_amount_blinders.append(QByteArray());
                } else {
                    m_asset_commitments.append(commitment["asset_generator"].toByteArray());
                    m_value_commitments.append(commitment["value_commitment"].toByteArray());
                    m_asset_blinders.append(commitment["abf"].toByteArray());
                    m_amount_blinders.append(commitment["vbf"].toByteArray());
                }
            }
            finish();
        });
    }
    bool handleError(const QVariantMap& msg)
    {
        if (!msg.contains("error")) return false;
        Q_ASSERT(msg["error"].type() == QVariant::Map);
        setMessage(QJsonObject::fromVariantMap(msg["error"].toMap()));
        fail();
        return true;
    }
};

JadeDevice::JadeDevice(JadeAPI* jade, QObject* parent)
    : Device(parent)
    , m_jade(jade)
{
}

GetWalletPublicKeyActivity *JadeDevice::getWalletPublicKey(Network *network, const QVector<uint32_t>& path)
{
    return new JadeGetWalletPublicKeyActivity(network, path, this);
}

SignMessageActivity *JadeDevice::signMessage(const QString &message, const QVector<uint32_t> &path)
{
    return new JadeSignMessageActivity(message, path, this);
}

SignTransactionActivity *JadeDevice::signTransaction(Network* network, const QJsonObject &transaction, const QJsonArray &signing_inputs, const QJsonArray &transaction_outputs, const QJsonObject &signing_transactions, const QJsonArray &signing_address_types)
{
    return new JadeSignTransactionActivity(network, transaction, signing_inputs, transaction_outputs, signing_transactions, signing_address_types, this);
}

GetBlindingKeyActivity *JadeDevice::getBlindingKey(const QString& script)
{
    return new JadeGetBlindingKeyActivity(script, this);
}

GetBlindingNonceActivity *JadeDevice::getBlindingNonce(const QByteArray& pubkey, const QByteArray& script)
{
    return new JadeGetBlindingNonceActivity(pubkey, script, this);
}

SignLiquidTransactionActivity *JadeDevice::signLiquidTransaction(const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs)
{
    return new JadeSignLiquidTransactionActivity(transaction, signing_inputs, outputs, this);
}

void JadeDevice::updateVersionInfo()
{
    m_jade->getVersionInfo([this](const QVariantMap& data) {
        setVersionInfo(data.value("result").toMap());
    });
}

void JadeDevice::setVersionInfo(const QVariantMap& version_info)
{
    if (m_version_info == version_info) return;
    // qDebug() << QJsonDocument(QJsonObject::fromVariantMap(data)).toJson(QJsonDocument::Indented).toStdString().c_str();
    m_version_info = version_info;
    emit versionInfoChanged();
    m_name = QString("Jade %1").arg(version_info.value("EFUSEMAC").toString().mid(6));
    emit nameChanged();
}

QVariantMap JadeDevice::versionInfo() const
{
    return m_version_info;
}

namespace {
const QString JADE_MIN_ALLOWED_FW_VERSION = "0.1.24";
}

bool JadeDevice::updateRequired() const
{
    return SemVer(version()) < SemVer(JADE_MIN_ALLOWED_FW_VERSION);
}

QString JadeDevice::version() const
{
    return m_version_info.value("JADE_VERSION").toString();
}
