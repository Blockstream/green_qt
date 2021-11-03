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
                { "name", device->name() },
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

void LedgerDeviceController::setDevice(Device *device)
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
    LedgerDevice* device = qobject_cast<LedgerDevice*>(m_device);
    if (!device) return;

#if 1
    if (m_app_version.isNull()) {
        auto activity = device->getApp();
        connect(activity, &Activity::finished, this, [this, activity, device] {
            activity->deleteLater();
            m_app_version = activity->version();
            m_app_name = activity->name();
            emit appChanged();

            qInfo() << "device:" << device->name()
                    << "app_name:" << m_app_name
                    << "app_version:" << m_app_version.toString();

            device->setAppVersion(m_app_version.toString());

            m_network = network_from_app_name(activity->name());
            emit networkChanged(m_network);

            if (!m_network) {
                if (device->type() == Device::LedgerNanoS) {
                    if (m_app_version < SemVer::parse("2.0.0")) {
                        setStatus("outdated");
                        return;
                    }
                } else if (device->type() == Device::LedgerNanoX) {
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

//            if (!m_network) {
//                // TODO: device can be in dashboard or in another applet
//                // either ignore or warn of that
//                // It is in dashboard if cmd->m_name.indexOf("OLOS") >= 0
////                QTimer::singleShot(1000, this, &LedgerDeviceController::initialize);
//                return;
//            }

            QTimer::singleShot(1000, this, &LedgerDeviceController::initialize);
        });
        connect(activity, &Activity::failed, this, [this, activity] {
            activity->deleteLater();
            setStatus("error");
            //QTimer::singleShot(1000, this, &LedgerDeviceController::initialize);
        });
        activity->exec();
        return;
    }
#endif
#if 0
    if (m_fw_version.isNull()) {
        auto activity = device->getFirmware();
        connect(activity, &Activity::finished, this, [this, activity] {
            activity->deleteLater();
            m_fw_version = activity->version();
            emit firmwareChanged();

            /*

            */
        });
        connect(activity, &Activity::failed, this, [this, activity] {
            activity->deleteLater();
            setStatus("error");
            //QTimer::singleShot(1000, this, &LedgerDeviceController::initialize);
        });
        activity->exec();
        return;
    }
#endif
}

void LedgerDeviceController::setStatus(const QString& status)
{
    if (m_status == status) return;
    m_status = status;
    emit statusChanged(m_status);
}

void LedgerDeviceController::login()
{
    if (!m_network) return;

    if (!m_session) {
        m_session = new Session(this);

        m_session.track(connect(m_session, &Session::connectedChanged, this, &LedgerDeviceController::login));
        m_session.track(connect(m_session, &Session::activityCreated, this, &LedgerDeviceController::activityCreated));

        m_session->setNetwork(m_network);
        m_session->setActive(true);

        emit sessionChanged(m_session);
        return;
    }

    if (m_session->isActive() && !m_session->isConnected()) return;

    if (m_wallet) return;

    m_device_details = device_details_from_device(m_device);
    m_wallet = new Wallet(m_network);
    m_wallet->setName(m_device->name());
    m_wallet->m_device = m_device;
    m_wallet->setSession(m_session);
    m_wallet->m_id = m_device->uuid();
    emit walletChanged(m_wallet);

    setStatus("login");
    auto register_user_handler = new RegisterUserHandler(m_device_details, m_wallet->session());
    auto login_handler = new LoginHandler(m_device_details, m_wallet->session());
    connect(register_user_handler, &Handler::done, this, [login_handler] {
        login_handler->exec();
    });
    connect(register_user_handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    connect(register_user_handler, &Handler::error, this, [this]() {
        setStatus("locked");
    });
    connect(login_handler, &Handler::done, this, [this, login_handler] {
        m_wallet->updateHashId(login_handler->walletHashId());
        m_wallet->setSession();
        WalletManager::instance()->addWallet(m_wallet);

        m_progress = 1;
        emit progressChanged(m_progress);

        // TODO: should the controller decide wallet lifetime?
        auto w = m_wallet;
        connect(m_device, &QObject::destroyed, this, [w] {
            WalletManager::instance()->removeWallet(w);
            delete w;
        });
        setStatus("done");
    });
    connect(login_handler, &Handler::resolver, this, [this](Resolver* resolver) {
        connect(resolver, &Resolver::progress, this, [this](int current, int total) {
            m_progress = current == total ? 0 : qreal(current) / qreal(total);
            emit progressChanged(m_progress);
        });
        resolver->resolve();
    });
    connect(login_handler, &Handler::error, this, [this]() {
        setStatus("locked");
    });
    register_user_handler->exec();
}
