/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the demonstration applications of the Qt Toolkit.
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

#ifndef JADEDEVICE_H
#define JADEDEVICE_H

#include <QtQml>
#include <qbluetoothlocaldevice.h>
#include <QObject>
#include <QVariant>
#include <QList>
#include <QBluetoothDeviceDiscoveryAgent>
#include <QElapsedTimer>
#include "QScopedPointer"
#include "QNetworkReply"

#include "activity.h"
#include "deviceinfo.h"
#include "serviceinfo.h"

QT_FORWARD_DECLARE_CLASS (ServiceInfo)
QT_FORWARD_DECLARE_CLASS (JadeAPI)

class JadeDeviceSerialPortDiscoveryAgent2: public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariant devicesList READ getDevices NOTIFY devicesUpdated)
    Q_PROPERTY(QVariant servicesList READ getServices NOTIFY servicesUpdated)
    Q_PROPERTY(QString update READ getUpdate WRITE setUpdate NOTIFY updateChanged)
    Q_PROPERTY(bool state READ state NOTIFY stateChanged)
public:
    JadeDeviceSerialPortDiscoveryAgent2(QObject* parent = nullptr);
    ~JadeDeviceSerialPortDiscoveryAgent2();
    QVariant getDevices();
    QVariant getServices();
    QString getUpdate();
    bool state();

public slots:
    void startDeviceDiscovery();
    void scanServices(const QString &address);
    void disconnectFromDevice();

private slots:
    // QBluetoothDeviceDiscoveryAgent related
    void deviceScanError(QBluetoothDeviceDiscoveryAgent::Error);
    void deviceScanFinished();
    void pairingError(QBluetoothLocalDevice::Error error);
    void pairingDone(const QBluetoothAddress &address, QBluetoothLocalDevice::Pairing pairing);
    void deviceDisconnected();

    // Jade connected/disconnected signals received
    void onJadeConnected();
    void onJadeDisconnected();

    // Downloading firmware from fw server
    void onFirmwareIndexResult(QNetworkReply *reply);
    void onFirmwareDownloaded(QNetworkReply *reply);

Q_SIGNALS:
    void devicesUpdated();
    void servicesUpdated();
    void updateChanged();
    void stateChanged();
    void disconnected();

private:
    void setUpdate(const QString &message);

    void resetJadePtr(JadeAPI *jade = nullptr);
    void connectJade(JadeAPI *jade);
    void disconnectJade();

    void updateJadeFirmware();
    void startOTA();

    QBluetoothDeviceDiscoveryAgent *discoveryAgent;
    QBluetoothLocalDevice *localDevice = nullptr;
    bool m_deviceScanState = false;

    DeviceInfo currentDevice;
    QList<DeviceInfo *> m_devices;
    QList<ServiceInfo* > m_services;
    QString m_message;

    QByteArray m_compressed_fw;
    QString m_fw_name;
    QVariantMap m_version;
    int m_uncompressed_fw_size;
    QElapsedTimer m_timer;

    // The JadeAPI instance, once connected
    JadeAPI *m_jade;
};

#include "device.h"
class JadeDevice : public Device
{
    Q_OBJECT
    Q_PROPERTY(QString version READ version NOTIFY versionInfoChanged)
    Q_PROPERTY(QVariantMap versionInfo READ versionInfo NOTIFY versionInfoChanged)
    Q_PROPERTY(QString systemLocation READ systemLocation CONSTANT)
    QML_ELEMENT
public:
    JadeDevice(JadeAPI* jade, QObject* parent = nullptr);
    Vendor vendor() const override { return Device::Blockstream; }
    Transport transport() const override { return Transport::USB; }
    Type type() const override { return Type::BlockstreamJade; }
    QString name() const override { return m_name; }
    GetWalletPublicKeyActivity* getWalletPublicKey(Network* network, const QVector<uint32_t>& path) override;
    SignMessageActivity* signMessage(const QString& message, const QVector<uint32_t>& path) override;
    SignTransactionActivity* signTransaction(Network* network, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions, const QJsonArray& signing_address_types) override;
    GetBlindingKeyActivity* getBlindingKey(const QString& script) override;
    GetBlindingNonceActivity* getBlindingNonce(const QByteArray& pubkey, const QByteArray& script) override;
    SignLiquidTransactionActivity* signLiquidTransaction(const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs) override;
    JadeAPI* m_jade;
    QString m_name;
    QString m_system_location;
    void updateVersionInfo();
    void setVersionInfo(const QVariantMap& version_info);
    QVariantMap versionInfo() const;
    QString version() const;
    QString systemLocation() const { return m_system_location; }
signals:
    void versionInfoChanged();
private:
    QVariantMap m_version_info;
};


class SemVer {
    int major;
    int minor;
    int patch;
public:
    SemVer(const QString& str)
    {
        const auto parts = str.split('.');
        Q_ASSERT(parts.size() == 3);
        bool ok;
        major = parts[0].toInt(&ok); Q_ASSERT(ok);
        minor = parts[1].toInt(&ok); Q_ASSERT(ok);
        patch = parts[2].toInt(&ok); Q_ASSERT(ok);
    }
    bool operator<(const SemVer& v) const
    {
        if (major < v.major) return true;
        if (major > v.major) return false;
        if (minor < v.minor) return true;
        if (minor > v.minor) return false;
        return patch < v.patch;
    }
    bool operator==(const SemVer& v) const
    {
        return major == v.major && minor == v.minor && patch == v.patch;
    }
    bool operator!=(const SemVer& v) const
    {
        return major != v.major || minor != v.minor || patch != v.patch;
    }
};

#endif // JADEDEVICE_H
