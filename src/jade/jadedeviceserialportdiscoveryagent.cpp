#include "jadedeviceserialportdiscoveryagent.h"

#include <QSerialPortInfo>
#include <QTimer>
#include <QtConcurrentRun>

#include "devicemanager.h"
#include "jadeapi.h"
#include "jadedevice.h"

namespace {

bool FilterSerialPort(const QSerialPortInfo& info)
{
    // Silicon Laboratories USB to UART (0x10c4, 0xea60)
    if (info.vendorIdentifier() == 0x10c4 && info.productIdentifier() == 0xea60) return false;

    // WCH CH9102F (0x1a86, 0x55d4)
    if (info.vendorIdentifier() == 0x1a86 && info.productIdentifier() == 0x55d4) return false;

#ifdef Q_OS_LINUX
    // VMware Inc., happens in Debian VM
    if (info.vendorIdentifier() == 0x15ad) return false;

    // don't filter if vid and pid are unknown, happens with flatpak
    if (info.vendorIdentifier() == 0 && info.productIdentifier() == 0) return false;
#endif

    return true;
}

} // namespace

JadeDeviceSerialPortDiscoveryAgent::JadeDeviceSerialPortDiscoveryAgent(QObject* parent)
    : QObject(parent)
{
    scan();
}

void JadeDeviceSerialPortDiscoveryAgent::scan()
{
    using Watcher = QFutureWatcher<QList<QSerialPortInfo>>;
    const auto watcher = new Watcher(this);

    watcher->setFuture(QtConcurrent::run([=] {
        return QSerialPortInfo::availablePorts();
    }));

    connect(watcher, &Watcher::finished, this, [=] {
        auto backends = m_backends;
        m_backends.clear();

        for (const auto &info : watcher->result()) {
            const auto system_location = info.systemLocation();

            if (FilterSerialPort(info)) continue;

            auto backend = backends.take(system_location);
            if (!backend) {
#ifdef Q_OS_MACOS
                const bool relax_write = system_location.contains("cu.usbmodem");
#else
                const bool relax_write = false;
#endif
                backend = new JadeAPI(info, relax_write, this);
                connect(backend, &JadeAPI::onConnected, this, [=] {
                    // qDebug() << "OPEN OK" << system_location;
                    probe(backend);
                });
                connect(backend, &JadeAPI::onOpenError, this, [=] {
                    // qDebug() << "OPEN ERROR" << system_location;
                });
                connect(backend, &JadeAPI::onDisconnected, this, [=] {
                    // qDebug() << "DISCONNECT" << system_location;
                });
                probe(backend);
            } else if (!backend->isConnected()) {
                probe(backend);
            }
            m_backends.insert(system_location, backend);
        }

        while (!backends.empty()) {
            const auto system_location = backends.firstKey();
            auto backend = backends.take(system_location);
            remove(backend);
        }

        QTimer::singleShot(100, this, &JadeDeviceSerialPortDiscoveryAgent::scan);
    });
}

void JadeDeviceSerialPortDiscoveryAgent::probe(JadeAPI* backend)
{
    if (m_attempts.value(backend) > 10) return;
    m_attempts[backend] ++;
    backend->connectDevice();
    backend->getVersionInfo(false, [=](const QVariantMap& data) {
        if (data.contains("error")) {
            qDebug() << "VERSION INFO ERROR:" << data.value("error");
            auto error = data.value("error").toMap();
            if (error.value("message").toString() == "timeout") {
                qDebug() << "RETRY";
                QTimer::singleShot(100, backend, [=] {
                    probe(backend);
                });
            }
            return;
        }

        const auto version_info = data.value("result").toMap();
        const auto efusemac = version_info.value("EFUSEMAC").toString();

        JadeDevice* device = nullptr;

        for (auto a_device : DeviceManager::instance()->devices()) {
            auto jade_device = qobject_cast<JadeDevice*>(a_device);
            if (!jade_device) continue;
            if (efusemac != jade_device->versionInfo().value("EFUSEMAC").toString()) continue;
            device = jade_device;
            break;
        }

        if (!device) device = new JadeDevice(this);
        device->setBackend(backend);
        device->setVersionInfo(version_info);
        device->setConnected(true);

        DeviceManager::instance()->addDevice(device);

        updateLater(backend);
    });
}

void JadeDeviceSerialPortDiscoveryAgent::updateLater(JadeAPI* backend)
{
    if (backend->isBusy()) {
        QTimer::singleShot(500, backend, [=] {
            updateLater(backend);
        });
        return;
    }

    QTimer::singleShot(500, backend, [=] {
        const auto device = deviceFromBackend(backend);
        if (!device) return;
        if (QVersionNumber(1, 0, 21) <= QVersionNumber::fromString(device->version())) {
            backend->ping([=](const QVariantMap& data) {
                if (data.contains("result")) {
                    int status = data.value("result").toInt();
                    const auto device = deviceFromBackend(backend);
                    device->setStatus((JadeDevice::Status) status);
                } else {
                    device->setStatus(JadeDevice::StatusIdle);
                }
            });
        } else {
            device->setStatus(JadeDevice::StatusIdle);
        }
        backend->getVersionInfo(true, [=](const QVariantMap& data) {
            const auto device = deviceFromBackend(backend);
            if (device) {
                if (data.contains("error")) {
                    qDebug() << "VERSION INFO ERROR:" << data.value("error");
                    device->setConnected(false);
                    device->setStatus(JadeDevice::StatusIdle);
                } else {
                    const auto version_info = data.value("result").toMap();
                    device->setConnected(true);
                    device->setVersionInfo(version_info);
                }
            }
            updateLater(backend);
        });
    });
}

JadeDevice *JadeDeviceSerialPortDiscoveryAgent::deviceFromBackend(JadeAPI* backend)
{
    for (auto a_device : DeviceManager::instance()->devices()) {
        auto jade_device = qobject_cast<JadeDevice*>(a_device);
        if (!jade_device) continue;
        if (jade_device && jade_device->api() == backend) return jade_device;
    }
    return nullptr;
}

void JadeDeviceSerialPortDiscoveryAgent::remove(JadeAPI* backend)
{
    auto system_location = m_backends.key(backend);
    m_backends.take(system_location);

    auto device = deviceFromBackend(backend);
    if (device) {
        device->setBackend(nullptr);
        device->setConnected(false);
        device->setStatus(JadeDevice::StatusIdle);
    }

    m_attempts.remove(backend);
    backend->disconnectDevice();
    backend->deleteLater();
}
