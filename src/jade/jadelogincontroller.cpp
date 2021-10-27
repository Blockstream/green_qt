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
#include "semver.h"
#include "session.h"
#include "settings.h"
#include "wallet.h"
#include "walletmanager.h"

#include <gdk.h>

#include <wally_bip32.h>

static QString g_exclude_certificate = "-----BEGIN CERTIFICATE-----\nMIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/\nMSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT\nDkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow\nPzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD\nEw5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB\nAN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O\nrz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq\nOLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b\nxiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw\n7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD\naeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV\nHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG\nSIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69\nikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr\nAvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz\nR8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5\nJDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo\nOb8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ\n-----END CERTIFICATE-----\n";

static QJsonObject device_details_from_device(JadeDevice* device)
{
    const bool supports_host_unblinding = SemVer::parse(device->version()) >= SemVer(0, 1, 27);
    return {{
        "device", QJsonObject({
            { "name", "JADE" },
            { "supports_arbitrary_scripts", true },
            { "supports_low_r", true },
            { "supports_liquid", 1 },
            { "supports_ae_protocol", 1 },
            { "supports_host_unblinding", supports_host_unblinding }
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
    if (m_active) return;
    m_active = true;
    update();
}

void JadeLoginController::update()
{
    if (!m_active) return;

    Q_ASSERT(m_device);
    auto network = NetworkManager::instance()->network(m_network);
    Q_ASSERT(network);

    if (!m_wallet) {

        m_wallet = new Wallet(network);
        m_wallet->m_id = m_device->uuid();
        m_wallet->m_device = m_device;
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

        QObject::connect(m_wallet->session(), &Session::connectedChanged, this, &JadeLoginController::update);

        m_wallet->session()->setActive(true);
    }

    if (!m_wallet->session()->isConnected()) return;

    auto device_details = device_details_from_device(m_device);
    auto register_user_handler = new RegisterUserHandler(m_wallet, device_details);
    auto login_handler = new LoginHandler(m_wallet, device_details);

    connect(register_user_handler, &Handler::done, this, [login_handler] {
        login_handler->exec();
    });
    connect(register_user_handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    connect(register_user_handler, &Handler::error, this, []() {
        //setStatus("locked");
    });
    connect(login_handler, &Handler::done, this, [this, login_handler] {
        m_wallet->updateHashId(login_handler->walletHashId());
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

    if (!m_wallet || !m_wallet->session()) return;
    if (!m_wallet->session()->isActive() || !m_wallet->session()->isConnected()) return;

    m_device->api()->setHttpRequestProxy([this](JadeAPI& jade, int id, const QJsonObject& req) {
        QJsonObject _params = req.value("params").toObject();
        QJsonArray root_certificates;
        for (auto certificate : _params.value("root_certificates").toArray()) {
            if (certificate.toString() != g_exclude_certificate) {
                root_certificates.append(certificate);
            }
        }
        if (root_certificates.isEmpty()) {
            _params.remove("root_certificates");
        } else {
            _params["root_certificates"] = root_certificates;
        }
        const auto params = Json::fromObject(_params);
        GA_json* output;
        GA_http_request(m_wallet->m_session->m_session, params.get(), &output);
        auto res = Json::toObject(output);
        GA_destroy_json(output);
        jade.handleHttpResponse(id, req, res.value("body").toObject());
    });
    m_device->api()->authUser(network->id(), [this, register_user_handler](const QVariantMap& msg) {
        Q_ASSERT(msg.contains("result"));
        if (msg["result"] == true) {
            register_user_handler->exec();
        } else {
            m_wallet->deleteLater();
            m_wallet = nullptr;
            emit walletChanged(nullptr);
            emit invalidPin();
            m_active = false;
            return;
        }
    });
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
