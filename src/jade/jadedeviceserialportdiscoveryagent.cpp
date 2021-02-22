#include "jadedeviceserialportdiscoveryagent.h"

#include <QTimer>
#include <QSerialPortInfo>

#include "jadeapi.h"
#include "jadedevice.h"
#include "wallet.h"
#include "walletmanager.h"
#include "network.h"
#include "networkmanager.h"

#include "resolver.h"
#include "settings.h"
#include "handlers/connecthandler.h"
#include "handlers/loginhandler.h"
#include "handlers/registeruserhandler.h"

#include <gdk.h>
#include "json.h"

#include <wally_bip32.h>

static QJsonObject device_details_from_device()
{
    return {{
        "device", QJsonObject({
            { "name", "JADE" },
            { "supports_arbitrary_scripts", true },
            { "supports_low_r", true },
            { "supports_liquid", 1 }
        })
    }};
}

#include "devicemanager.h"

JadeDeviceSerialPortDiscoveryAgent::JadeDeviceSerialPortDiscoveryAgent(QObject* parent)
    : QObject(parent)
{
    auto timer = new QTimer(this);
    connect(timer, &QTimer::timeout, [this] {
        auto devices = m_devices;
        m_devices.clear();

        for (const auto &info : QSerialPortInfo::availablePorts()) {
            const auto system_location = info.systemLocation();
            if (m_failed_locations.contains(system_location)) continue;

            // filter for Silicon Laboratories USB to UART
            if (info.vendorIdentifier() != 0x10c4) continue;
            if (info.productIdentifier() != 0xea60) continue;

            auto device = devices.take(system_location);
            if (!device) {
                auto api = new JadeAPI(info);
                device = new JadeDevice(api, this);
                api->setParent(device);
                device->m_system_location = system_location;
                connect(api, &JadeAPI::onConnected, this, [this, device] {
                    device->m_jade->getVersionInfo([this, device](const QVariantMap& data) {
                        const auto result = data.value("result").toMap();
                        device->setVersionInfo(result);
                        DeviceManager::instance()->addDevice(device);
                    });
                });
                connect(api, &JadeAPI::onDisconnected, this, [this, device] {
                    if (m_devices.take(device->m_system_location)) {
                        m_failed_locations.insert(device->m_system_location);
                        delete device;
                    }
                });
                m_devices.insert(system_location, device);
                api->connectDevice();
            } else if (device->m_jade->isConnected()) {
                m_devices.insert(system_location, device);
            } else {
                devices.insert(system_location, device);
            }
        }

        if (devices.empty()) return;

        while (!devices.empty()) {
            const auto system_location = devices.firstKey();
            auto device = devices.take(system_location);
            DeviceManager::instance()->removeDevice(device);
            device->m_jade->disconnectDevice();
            delete device;
        }
    });
    timer->start(2000);
}

void JadeController::setNetwork(const QString& network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged(m_network);
}

void JadeController::login()
{
    Q_ASSERT(m_device);
    auto network = NetworkManager::instance()->network(m_network);
    Q_ASSERT(network);
    Q_ASSERT(!m_wallet);

    m_wallet = new Wallet;
    m_wallet->m_id = m_device->uuid();
    m_wallet->m_device = m_device;
    m_wallet->setNetwork(network);
    m_wallet->createSession();

    walletChanged(m_wallet);

    const auto proxy = Settings::instance()->proxy();
    const auto use_tor = Settings::instance()->useTor();

    auto device_details = device_details_from_device();
    auto connect_handler = new ConnectHandler(m_wallet, proxy, use_tor);
    auto register_user_handler = new RegisterUserHandler(m_wallet, device_details);
    auto login_handler = new LoginHandler(m_wallet, device_details);
    connect(connect_handler, &Handler::done, this, [this, network, register_user_handler] {
        m_device->m_jade->setHttpRequestProxy([this](JadeAPI& jade, int id, const QJsonObject& req) {
            const auto params = Json::fromObject(req.value("params").toObject());
            GA_json* output;
            GA_http_request(m_wallet->m_session, params.get(), &output);
            auto res = Json::toObject(output);
            GA_destroy_json(output);
            jade.handleHttpResponse(id, req, res.value("body").toObject());
        });
        m_device->m_jade->authUser(network->id(), [this, register_user_handler](const QVariantMap& msg) {
            Q_ASSERT(msg.contains("result"));
            if (msg["result"] == true) {
                register_user_handler->exec();
            } else {
                m_wallet->deleteLater();
                m_wallet = nullptr;
                emit walletChanged(nullptr);
                emit invalidPin();
                return;
            }
        });
    });
    connect(register_user_handler, &Handler::done, this, [login_handler] {
        login_handler->exec();
    });
    connect(register_user_handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    connect(register_user_handler, &Handler::error, this, []() {
        //setStatus("locked");
    });
    connect(login_handler, &Handler::done, this, [this] {
        m_wallet->setSession();
        WalletManager::instance()->addWallet(m_wallet);
    });
    connect(login_handler, &Handler::resolver, this, [this](Resolver* resolver) {
        connect(resolver, &Resolver::progress, this, [](int current, int total) {
//                                    m_progress = current == total ? 0 : qreal(current) / qreal(total);
//                                    emit progressChanged(m_progress);
        });
        resolver->resolve();
    });
    connect(login_handler, &Handler::error, this, []() {
        //setStatus("locked");
    });
    connect_handler->exec();
}

JadeController::JadeController(QObject* parent)
    : QObject(parent)
{

}

void JadeController::setDevice(JadeDevice* device)
{
    if (m_device == device) return;
    m_device = device;
    emit deviceChanged(m_device);
}
