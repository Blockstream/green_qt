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

#include <qbluetoothuuid.h>

#include "deviceinfo.h"

DeviceInfo::DeviceInfo(const QBluetoothDeviceInfo &d)
{
    m_bluetooth_device = d;
    m_is_ble = true;
}


DeviceInfo::DeviceInfo(const QSerialPortInfo &d)
{
    m_serial_device = d;
    m_is_ble = false;
}

QString DeviceInfo::getAddress() const
{
    //return "Press here to upgrade";
    if (!m_is_ble) {
        return m_serial_device.portName();
    }
#ifdef Q_OS_MAC
    // On OS X and iOS we do not have addresses,
    // only unique UUIDs generated by Core Bluetooth.
    return m_bluetooth_device.deviceUuid().toString();
#else
    return m_bluetooth_device.address().toString();
#endif
}
QString DeviceInfo::getType() const
{
    return m_is_ble ? "BLE":"USB";
}

QString DeviceInfo::getName() const
{
    return m_is_ble ? m_bluetooth_device.name() : m_serial_device.serialNumber();
}

QBluetoothDeviceInfo DeviceInfo::getBluetoothDevice()
{
    return m_bluetooth_device;
}

QSerialPortInfo DeviceInfo::getSerialDevice()
{
    return m_serial_device;
}

void DeviceInfo::setBluetoothDevice(const QBluetoothDeviceInfo &dev)
{
    m_bluetooth_device = QBluetoothDeviceInfo(dev);
    Q_EMIT deviceChanged();
}

void DeviceInfo::setSerialDevice(const QSerialPortInfo &dev)
{
    m_serial_device = QSerialPortInfo(dev);
    Q_EMIT deviceChanged();
}
