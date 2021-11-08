#include "activitymanager.h"
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


static QJsonObject device_details_from_device(JadeDevice* device)
{
    const bool supports_host_unblinding = SemVer::parse(device->version()) >= SemVer(0, 1, 27);
    return {{
        "device", QJsonObject({
            { "name", device->uuid() },
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
    update();
}

void JadeLoginController::setEnabled(bool enabled)
{
    if (m_enabled == enabled) return;
    m_enabled = enabled;
    emit isEnabledChanged(m_enabled);
}

void JadeLoginController::setActive(bool active)
{
    if (m_active == active) return;
    Q_ASSERT(!m_active);
    m_active = active;
    emit activeChanged(m_active);
    update();
}

void JadeLoginController::setWallet(Wallet *wallet)
{
    if (m_wallet == wallet) return;
    if (m_wallet) {
        Q_ASSERT(!wallet);
        m_wallet = nullptr;
        emit walletChanged(nullptr);
    } else {
        Q_ASSERT(!m_wallet);
        Q_ASSERT(!m_active);
        m_wallet = wallet;
        emit walletChanged(m_wallet);
        setNetwork(wallet->network()->id());
    }
}

void JadeLoginController::update()
{
    auto network = NetworkManager::instance()->network(m_network);

    if (!m_device || !network) {
        setEnabled(false);
        return;
    }

    {
        const auto nets = m_device->versionInfo().value("JADE_NETWORKS").toString();
        setEnabled((nets == "ALL") || (nets == "MAIN" && network->isMainnet()) || (nets == "TEST" && !network->isMainnet()));
        if (!m_enabled) return;
    }

    switch (m_device->state()) {
    case JadeDevice::StateUninitialized:
    case JadeDevice::StateUnsaved:
        return unlock();
    default:
        break;
    }

//    case JadeDevice::StateTemporary:
//    case JadeDevice::StateReady:
//        break;
//    }

    if (m_wallet_hash_id.isEmpty()) {
        return identify();
    }

    if (!m_wallet) {
        m_wallet = WalletManager::instance()->walletWithHashId(m_wallet_hash_id, false);
        if (m_wallet) {
            emit walletChanged(m_wallet);
            m_wallet->setDevice(m_device);
        }
    }

    login();
}

void JadeLoginController::ping()
{
    if (!m_device) return;
    if (m_device->api()->isBusy()) return;
    m_device->updateVersionInfo();
}

void JadeLoginController::connect()
{
    if (!m_active) return;

    Q_ASSERT(!m_session);
    auto network = NetworkManager::instance()->network(m_network);
    Q_ASSERT(network);

    qDebug() << "connecting";

    m_session = new Session(this);
    m_session->setNetwork(network);
    m_session->setActive(true);

    QObject::connect(m_session, &Session::connectedChanged, this, &JadeLoginController::update);
}

void JadeLoginController::unlock()
{
    if (!m_device) return;
    if (!m_session) return connect();
    if (!m_session->isConnected()) return;

    qDebug() << "unlocking";

    m_device->api()->setHttpRequestProxy([this](JadeAPI& jade, int id, const QJsonObject& req) {
        const auto params = Json::fromObject(req.value("params").toObject());
        GA_json* output;
        GA_http_request(m_session->m_session, params.get(), &output);
        auto res = Json::toObject(output);
        GA_destroy_json(output);
        jade.handleHttpResponse(id, req, res.value("body").toObject());
    });
    m_device->api()->authUser(m_network, [=](const QVariantMap& msg) {
        m_device->api()->setHttpRequestProxy(nullptr);
        Q_ASSERT(msg.contains("result"));
        if (msg["result"] == true) {
            m_device->updateVersionInfo();
        } else {
            emit invalidPin();
            setActive(false);
        }
    });
}

void JadeLoginController::identify()
{
    if (!m_device) return;
    if (m_device->state() == JadeDevice::StateLocked) return unlock();

    qDebug() << "identifying";

    auto network = NetworkManager::instance()->network(m_network);

    auto activity = m_device->getWalletPublicKey(network, {});
    QObject::connect(activity, &Activity::finished, [this, activity] {
        activity->deleteLater();

        const auto master_xpub = activity->publicKey();
        Q_ASSERT(!master_xpub.isEmpty());

        const auto net_params = Json::fromObject({{ "name", m_network }});
        const auto params = Json::fromObject({{ "master_xpub", QString::fromLocal8Bit(master_xpub) }});
        GA_json* output;
        int rc = GA_get_wallet_identifier(net_params.get(), params.get(), &output);
        Q_ASSERT(rc == GA_OK);
        const auto identifier = Json::toObject(output);
        GA_destroy_json(output);

        m_wallet_hash_id = identifier.value("wallet_hash_id").toString();
        Q_ASSERT(!m_wallet_hash_id.isEmpty());

        update();
    });
    QObject::connect(activity, &Activity::failed, [this, activity] {
        activity->deleteLater();
    });
    ActivityManager::instance()->exec(activity);
}

void JadeLoginController::login()
{
    if (!m_session) return connect();
    if (!m_session->isConnected()) return;

    Q_ASSERT(m_device);

    auto device_details = device_details_from_device(m_device);
    auto handler = new LoginHandler(device_details, m_session);

    QObject::connect(handler, &Handler::done, this, [this, handler] {
        handler->deleteLater();

        Q_ASSERT(m_wallet_hash_id == handler->walletHashId());

        if (!m_wallet) {
            m_wallet = WalletManager::instance()->createWallet(m_session->network());
            m_wallet->m_is_persisted = true;
            m_wallet->updateHashId(m_wallet_hash_id);
            m_wallet->setName(QString("%1 on %2").arg(m_session->network()->displayName()).arg(m_device->name()));
            m_wallet->setDevice(m_device);
            WalletManager::instance()->insertWallet(m_wallet);
            emit walletChanged(m_wallet);
        }

        m_wallet->setSession(m_session);
        m_wallet->setSession();
        m_session = nullptr;

    });
    QObject::connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
//        qDebug() << "RESOLVE NOW!" << resolver;
//            connect(resolver, &Resolver::progress, this, [](int current, int total) {
//                                        m_progress = current == total ? 0 : qreal(current) / qreal(total);
//                                        emit progressChanged(m_progress);
//            });
        resolver->resolve();
    });
    QObject::connect(handler, &Handler::error, this, [=]{
        //setStatus("locked");
        handler->deleteLater();
        signup();
    });

    handler->exec();
}

void JadeLoginController::signup()
{
    if (!m_session) return connect();
    if (!m_session->isConnected()) return;

    Q_ASSERT(m_device);

    auto device_details = device_details_from_device(m_device);
    auto handler = new RegisterUserHandler(device_details, m_session);

    QObject::connect(handler, &Handler::done, this, [this, handler] {
        Q_ASSERT(m_wallet_hash_id == handler->walletHashId());
        login();
    });
    QObject::connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    QObject::connect(handler, &Handler::error, this, []() {
        //setStatus("locked");
    });

    handler->exec();
}

JadeLoginController::JadeLoginController(QObject* parent)
    : QObject(parent)
{
    auto timer = new QTimer(this);
    QObject::connect(timer, &QTimer::timeout, this, &JadeLoginController::ping);
    timer->start(30000);
}

void JadeLoginController::setDevice(JadeDevice* device)
{
    if (m_device == device) return;
    m_device = device;
    if (m_device) {
        QObject::connect(m_device, &JadeDevice::versionInfoChanged, this, &JadeLoginController::update);
    }
    emit deviceChanged(m_device);
    update();
}
