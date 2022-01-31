#include "activitymanager.h"
#include "command.h"
#include "ga.h"
#include "json.h"
#include "handlers/connecthandler.h"
#include "handlers/loginhandler.h"
#include "handlers/registeruserhandler.h"
#include "ledgerdevice.h"
#include "ledgerdevicecontroller.h"
#include "network.h"
#include "networkmanager.h"
#include "resolver.h"
#include "semver.h"
#include "session.h"
#include "settings.h"
#include "util.h"
#include "wallet.h"
#include "walletmanager.h"

#include <gdk.h>

namespace {
    Network *network_from_app_name(const QString& app_name)
    {
        QString id;
        if (app_name == "Bitcoin") id = "mainnet";
        if (app_name == "Bitcoin Test") id = "testnet";
        if (app_name == "Liquid") id = "liquid";
        return id.isEmpty() ? nullptr : NetworkManager::instance()->network(id);
    }
    QJsonObject device_details_from_device(Device* device)
    {
        return {{
            "device", QJsonObject({
                { "name", device->uuid() },
                { "supports_arbitrary_scripts", true },
                { "supports_low_r", false },
                { "supports_liquid", device->type() == Device::LedgerNanoS ? 1 : 0 }
            })
        }};
    }
} // namespace

LedgerDeviceController::LedgerDeviceController(QObject* parent)
    : QObject(parent)
{
}

LedgerDeviceController::~LedgerDeviceController()
{
}

void LedgerDeviceController::setDevice(LedgerDevice *device)
{
    if (m_device == device) return;
    m_device = device;
    emit deviceChanged(m_device);

    if (m_device) {
        QTimer::singleShot(1000, this, &LedgerDeviceController::initialize);
    }
}

void LedgerDeviceController::initialize()
{
    if (!m_device) return;

    if (m_app_version.isNull()) {
        auto activity = m_device->getApp();
        QObject::connect(activity, &Activity::finished, this, [=] {
            activity->deleteLater();
            m_app_version = activity->version();
            m_app_name = activity->name();
            emit appChanged();

            qInfo() << "device:" << m_device->name()
                    << "app_name:" << m_app_name
                    << "app_version:" << m_app_version.toString();

            m_device->setAppVersion(m_app_version.toString());

            m_network = network_from_app_name(activity->name());
            emit networkChanged(m_network);

            update();

            if (!m_network) {
                if (m_device->type() == Device::LedgerNanoS) {
                    if (m_app_version < SemVer::parse("2.0.0")) {
                        setStatus("outdated");
                        return;
                    }
                } else if (m_device->type() == Device::LedgerNanoX) {
                    if (m_app_version < SemVer::parse("1.3.0")) {
                        setStatus("outdated");
                        return;
                    }
                } else {
                    setStatus("dashboard");
                }
            } else {
                if (m_device->type() == Device::LedgerNanoS) {
                    if (m_network->isLiquid()) {
                        if (m_app_version < SemVer(1, 4, 8)) {
                            setStatus("outdated");
                            return;
                        }
                    } else {
                        if (m_app_version < SemVer(1, 6, 0)) {
                            setStatus("outdated");
                            return;
                        }
                    }
                } else if (m_device->type() == Device::LedgerNanoX) {
                    if (m_app_version < SemVer(1, 6, 1)) {
                        setStatus("outdated");
                        return;
                    }
                }
            }
            QTimer::singleShot(1000, this, &LedgerDeviceController::initialize);
        });
        QObject::connect(activity, &Activity::failed, this, [this, activity] {
            activity->deleteLater();
            setStatus("error");
        });
        ActivityManager::instance()->exec(activity);
        return;
    }
}

void LedgerDeviceController::setStatus(const QString& status)
{
    qDebug() << Q_FUNC_INFO << m_status << status;
    if (m_status == status) return;
    m_status = status;
    emit statusChanged(m_status);
    update();
}

void LedgerDeviceController::update()
{
    if (m_wallet_hash_id.isEmpty()) {
        return identify();
    }

    if (!m_wallet) {
        m_wallet = WalletManager::instance()->walletWithHashId(m_wallet_hash_id, false);
        if (m_wallet) {
            emit walletChanged(m_wallet);
            m_wallet->setDevice(m_device);

            QObject::connect(m_wallet, &Wallet::authenticationChanged, this, [=] {
                setActive(m_wallet->isAuthenticated());
            });
        }
    }

    login();
}

void LedgerDeviceController::setActive(bool active)
{
    if (m_active == active) return;
    m_active = active;
    emit activeChanged(m_active);
    update();
}

void LedgerDeviceController::connect()
{
    if (m_session) return;
    if (!m_network) return;
    if (!m_active) return;

    m_session = new Session(m_network, this);

    m_session.track(QObject::connect(m_session, &Session::connectedChanged, this, &LedgerDeviceController::update));
    m_session.track(QObject::connect(m_session, &Session::activityCreated, this, &LedgerDeviceController::activityCreated));

    m_session->setActive(true);

    emit sessionChanged(m_session);
}

void LedgerDeviceController::identify()
{
    if (!m_device) return;

    qDebug() << "identifying, retrieve master public key";
    auto activity = m_device->getWalletPublicKey(m_network, {});
    QObject::connect(activity, &Activity::finished, this, [=] {
        activity->deleteLater();

        const auto master_xpub = activity->publicKey();
        Q_ASSERT(!master_xpub.isEmpty());

        qDebug() << "identifying, compute wallet hash id";
        const auto net_params = Json::fromObject({{ "name", m_network->id() }});
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
    QObject::connect(activity, &Activity::failed, this, [=] {
        activity->deleteLater();
        setStatus("locked");
    });
    ActivityManager::instance()->exec(activity);
}

void LedgerDeviceController::login()
{
    if (!m_device) return;
    if (!m_session) return connect();
    if (!m_session->isConnected()) return;
    if (m_login_handler) return;
    if (m_wallet && m_wallet->authentication() != Wallet::Unauthenticated) return;
    if (m_status == "login") return;
    setStatus("login");

    auto device_details = device_details_from_device(m_device);
    m_login_handler = new LoginHandler(device_details, m_session);

    QObject::connect(m_login_handler, &Handler::done, this, [=] {
        Q_ASSERT(m_wallet_hash_id == m_login_handler->walletHashId());
        m_login_handler->deleteLater();
        m_login_handler = nullptr;

        if (!m_wallet) {
            m_wallet = WalletManager::instance()->createWallet(m_session->network(), m_wallet_hash_id);
            m_wallet->m_is_persisted = true;
            m_wallet->setName(QString("%1 on %2").arg(m_session->network()->displayName()).arg(m_device->name()));
            m_wallet->setDevice(m_device);
            WalletManager::instance()->insertWallet(m_wallet);
            emit walletChanged(m_wallet);
        }

        m_wallet->setSession(m_session);
        m_wallet->setSession();
        setStatus("done");
        m_session = nullptr;

    });
    QObject::connect(m_login_handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    QObject::connect(m_login_handler, &Handler::error, this, [=]{
        setStatus("locked");
        m_login_handler->deleteLater();
        m_login_handler = nullptr;
        signup();
    });

    m_login_handler->exec();
}

void LedgerDeviceController::signup()
{
    if (!m_device) return;
    if (!m_session) return connect();
    if (!m_session->isConnected()) return;

    auto device_details = device_details_from_device(m_device);
    auto handler = new RegisterUserHandler(device_details, m_session);

    QObject::connect(handler, &Handler::done, this, [=] {
        Q_ASSERT(m_wallet_hash_id == handler->walletHashId());
        login();
    });
    QObject::connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    QObject::connect(handler, &Handler::error, this, [=]() {
        setStatus("locked");
    });

    handler->exec();
}
