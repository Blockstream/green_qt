#include "jadedeviceserialportdiscoveryagent.h"

#include <QGuiApplication>
#include <QSerialPortInfo>
#include <QTimer>
#include <QtConcurrentRun>

#include "devicemanager.h"
#include "jadeapi.h"
#include "jadedevice.h"

#include <libserialport.h>

extern QCommandLineParser g_args;

namespace {

bool FilterSerialPort(const QSerialPortInfo& info)
{
    // Silicon Laboratories USB to UART (0x10c4, 0xea60)
    if (info.vendorIdentifier() == 0x10c4 && info.productIdentifier() == 0xea60) return false;

    // WCH CH9102F (0x1a86, 0x55d4)
    if (info.vendorIdentifier() == 0x1a86 && info.productIdentifier() == 0x55d4) return false;

    if (info.vendorIdentifier() == 0x0403 && info.productIdentifier() == 0x6001) return false;
    if (info.vendorIdentifier() == 0x1a86 && info.productIdentifier() == 0x7523) return false;
    if (info.vendorIdentifier() == 0x303a && info.productIdentifier() == 0x4001) return false;
    if (info.vendorIdentifier() == 0x303a && info.productIdentifier() == 0x1001) return false;

#ifdef Q_OS_LINUX
    // VMware Inc., happens in Debian VM
    if (info.vendorIdentifier() == 0x15ad) return false;

    // don't filter if vid and pid are unknown, happens with flatpak
    if (info.vendorIdentifier() == 0 && info.productIdentifier() == 0) return false;
#endif

    if (info.systemLocation().contains("tty")) return false;

    return true;
}

QList<QSerialPortInfo> AvailablePorts()
{
    QList<QSerialPortInfo> ports;

    sp_port** port_list;
    const auto result = sp_list_ports(&port_list);
    if (result != SP_OK) {
        qDebug() << Q_FUNC_INFO << "sp_list_ports() failed;";
        return ports;
    }

    for (int i = 0; port_list[i]; ++i) {
        const auto transport = sp_get_port_transport(port_list[i]);
        if (transport != SP_TRANSPORT_USB) continue;

        const auto path = QString::fromUtf8(sp_get_port_name(port_list[i]));
        const auto name = QFileInfo(path).fileName();

        QSerialPortInfo port(name);
        if (FilterSerialPort(port)) continue;
        ports.append(port);
    }

    sp_free_port_list(port_list);
    return ports;
}

} // namespace

JadeDeviceSerialPortDiscoveryAgent::JadeDeviceSerialPortDiscoveryAgent(QObject* parent)
    : QObject(parent)
{
    if (g_args.value("jade") != "disabled") {
        scan();
    }
}

void JadeDeviceSerialPortDiscoveryAgent::scan()
{
    for (auto backend : m_backends.values()) {
        if (backend->m_locked) {
            qDebug() << Q_FUNC_INFO << "skip 10s due to OTA";
            QTimer::singleShot(10000, this, &JadeDeviceSerialPortDiscoveryAgent::scan);
            return;
        }
    }

    using Watcher = QFutureWatcher<QList<QSerialPortInfo>>;
    const auto watcher = new Watcher(this);

    watcher->setFuture(QtConcurrent::run([=] {
        return AvailablePorts();
    }));

    connect(watcher, &Watcher::finished, this, [=] {
        auto backends = m_backends;
        m_backends.clear();

        for (const auto &info : watcher->result()) {
            const auto system_location = info.systemLocation();

            auto backend = backends.take(system_location);
            if (!backend) {
                backend = new JadeAPI(info, this);
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

        // scan more often when app is active
        int interval = qGuiApp->applicationState() == Qt::ApplicationActive ? 1000 : 10000;
        QTimer::singleShot(interval, this, &JadeDeviceSerialPortDiscoveryAgent::scan);
    });
}

void JadeDeviceSerialPortDiscoveryAgent::probe(JadeAPI* backend)
{
    if (backend->m_locked) return;
    backend->connectDevice();
    backend->getVersionInfo(false, [=](const QVariantMap& data) {
        if (data.contains("error")) {
            auto error = data.value("error").toMap();
            if (error.value("message").toString() == "timeout") {
                QTimer::singleShot(100, backend, [=] {
                    probe(backend);
                });
            }
            return;
        }

        if (data.contains("result")) {
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
#ifdef Q_OS_MACOS
            const auto system_location = m_backends.key(backend);
            const auto board_type = version_info.value("BOARD_TYPE", "JADE").toString();
            if (board_type != "JADE_V2" && system_location.contains("cu.usbmodem")) {
                backend->setRelaxWrite(true);
            }
#endif
            DeviceManager::instance()->addDevice(device);
        }

        updateLater(backend);
    });
}

void JadeDeviceSerialPortDiscoveryAgent::updateLater(JadeAPI* backend)
{
    QTimer::singleShot(1000, backend, [=] {
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
        if (QVersionNumber(1, 0, 21) <= QVersionNumber::fromString(device->version()) || !backend->isBusy() && !backend->m_locked) {
            backend->getVersionInfo(true, [=](const QVariantMap& data) {
                const auto device = deviceFromBackend(backend);
                if (device) {
                    if (data.contains("error")) {
                        device->setConnected(false);
                        device->setStatus(JadeDevice::StatusIdle);
                    } else if (data.contains("result")) {
                        const auto version_info = data.value("result").toMap();
                        device->setVersionInfo(version_info);
                        device->setConnected(true);
                    }
                }
                updateLater(backend);
            });
        } else {
            updateLater(backend);
        }
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

    backend->disconnectDevice();
    backend->deleteLater();
}
