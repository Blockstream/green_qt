#include "handlers/connecthandler.h"
#include "handlers/loginhandler.h"
#include "handlers/registeruserhandler.h"
#include "jadeapi.h"
#include "jadedevice.h"
#include "jadelogincontroller.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
#include "resolver.h"
#include "session.h"
#include "settings.h"
#include "wallet.h"
#include "walletmanager.h"

#include <gdk.h>

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

void JadeLoginController::setNetwork(const QString& network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged(m_network);
}

void JadeLoginController::login()
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

    connect(m_device, &QObject::destroyed, this, [this] {
        if (auto wallet = m_wallet) {
            m_wallet = nullptr;
            emit walletChanged(nullptr);
            WalletManager::instance()->removeWallet(wallet);
            delete wallet;
        }
    });

    auto device_details = device_details_from_device();
    auto register_user_handler = new RegisterUserHandler(m_wallet, device_details);
    auto login_handler = new LoginHandler(m_wallet, device_details);

    connect(m_wallet->session(), &Session::connectedChanged, this, [this, network, register_user_handler] {
        if (!m_wallet || !m_wallet->session()) return;
        if (!m_wallet->session()->isActive() || !m_wallet->session()->isConnected()) return;

        m_device->m_jade->setHttpRequestProxy([this](JadeAPI& jade, int id, const QJsonObject& req) {
            const auto params = Json::fromObject(req.value("params").toObject());
            GA_json* output;
            GA_http_request(m_wallet->m_session->m_session, params.get(), &output);
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
    m_wallet->session()->setActive(true);
}

JadeLoginController::JadeLoginController(QObject* parent)
    : QObject(parent)
{
}

void JadeLoginController::setDevice(JadeDevice* device)
{
    if (m_device == device) return;
    m_device = device;
    emit deviceChanged(m_device);
}
