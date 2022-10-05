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

#include "serviceinfo.h"

ServiceInfo::ServiceInfo(JadeDevice2 *service):
    m_jade(service)
{
}

JadeDevice2 *ServiceInfo::jade_service() const
{
    return m_jade;
}

void ServiceInfo::setPercentage(const qint64 percentage) {
    m_jade->m_percentage = percentage;
    Q_EMIT serviceChanged();
}

void ServiceInfo::setBytesSec(const qint64 bytesSec) {
    m_jade->m_bytes_sec = bytesSec;
    Q_EMIT serviceChanged();
}

void ServiceInfo::setSecondsLeft(const qint64 seconds) {
    m_jade->m_seconds_left = seconds;
    Q_EMIT serviceChanged();
}

void ServiceInfo::setName(const QString &name) {
    m_jade->m_fw_offered = name;
    Q_EMIT serviceChanged();
}

void ServiceInfo::setCurrentVersion(const QString &name) {
    m_jade->m_current_version = name;
    Q_EMIT serviceChanged();
}

QString ServiceInfo::getCurrentVersion() const
{
    return m_jade->m_current_version;
}

QString ServiceInfo::getName() const
{
    return m_jade->m_fw_offered;
}

QString ServiceInfo::getBytesSec() const
{
    return QString::number(m_jade->m_bytes_sec);
}

QString ServiceInfo::getTimeLeft() const
{
    if (m_jade->m_seconds_left > 60) {
        const qint64 mins = m_jade->m_seconds_left / 60;
        if (mins == 1) {
            return QString::number(mins) + " minute left";
        } else {
            return QString::number(mins) + " minutes left";
        }
    } else {
        if (m_jade->m_seconds_left == 1) {
            return QString::number(m_jade->m_seconds_left) + " second left";
        } else{
            return QString::number(m_jade->m_seconds_left) + " seconds left";
        }
    }
}

QString ServiceInfo::getPercentage() const
{
    return QString::number(m_jade->m_percentage);
}
