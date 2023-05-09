#include "ledgerdevicecontroller.h"

#include "activitymanager.h"
#include "context.h"
#include "json.h"
#include "ledgerdevice.h"
#include "network.h"
#include "resolver.h"
#include "session.h"
#include "wallet.h"
#include "walletmanager.h"

#include <gdk.h>

namespace {
    QString network_key_from_app_name(const QString& app_name)
    {
        if (app_name == "Bitcoin" || app_name == "Bitcoin Legacy") return "bitcoin";
        if (app_name == "Bitcoin Test" || app_name == "Bitcoin Test Legacy") return "testnet";
        if (app_name == "Liquid") return "liquid";
        if (app_name == "Liquid Test") return "testnet-liquid";
        return {};
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
    : Controller(parent)
{
    const auto initialize = new LedgerInitializeTask(this);
    const auto identify = new LedgerIdentifyTask(this);

    initialize->then(identify);

    auto group = new TaskGroup(this);
    group->add(initialize);
    group->add(identify);

    m_dispatcher->add(group);
}

LedgerDeviceController::~LedgerDeviceController()
{
}

void LedgerDeviceController::setNetwork(Network *network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged();
    m_dispatcher->dispatch();
}

void LedgerDeviceController::setDevice(LedgerDevice *device)
{
    if (m_device == device) return;
    m_device = device;
    emit deviceChanged();
    m_dispatcher->dispatch();
}

void LedgerDeviceController::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
}

void LedgerDeviceController::initialize()
{
}

void LedgerDeviceController::setStatus(const QString& status)
{
    qDebug() << Q_FUNC_INFO << m_status << status;
    if (m_status == status) return;
    m_status = status;
    emit statusChanged();
}

void LedgerDeviceController::login()
{
    if (m_wallet && m_wallet->context()) return;

    setContext(new Context(this));
    m_context->setWallet(m_wallet);
    m_context->setNetwork(m_network);

    auto group = new TaskGroup(this);

    auto connect_session = new SessionConnectTask(m_context->session());
    auto login = new LedgerLoginTask(this);
    auto get_watchonly_details = new GetWatchOnlyDetailsTask(m_context);
    auto load_twofactor_config = new LoadTwoFactorConfigTask(m_context);
    auto load_currencies = new LoadCurrenciesTask(m_context);
    auto load_accounts = new LoadAccountsTask(m_context);

    group->add(connect_session);
    group->add(login);
    group->add(get_watchonly_details);
    group->add(load_twofactor_config);
    group->add(load_currencies);
    group->add(load_accounts);

    if (m_network->isLiquid()) {
        auto load_assets = new LoadAssetsTask(m_context);

        group->add(load_assets);
    }

    m_dispatcher->add(group);

    login->then(load_accounts);

    connect(group, &TaskGroup::finished, this, [=] {
        m_wallet->setContext(m_context);
        m_context = nullptr;
        emit contextChanged();
        setStatus("done");
        emit loginDone();
    });
}

void LedgerDeviceController::setEnabled(bool enabled)
{
    if (m_enabled == enabled) return;
    m_enabled = enabled;
    emit enabledChanged();
}

LedgerInitializeTask::LedgerInitializeTask(LedgerDeviceController *controller)
    : Task(controller)
    , m_controller(controller)
{
}

void LedgerInitializeTask::update()
{
    if (status() != Status::Ready) return;

    const auto network = m_controller->network();
    if (!network) return;

    const auto device = m_controller->device();
    if (!device) return;

    const auto app_name = device->appName();
    if (app_name.isEmpty()) return;

    const auto app_version = QVersionNumber::fromString(device->appVersion());
    if (app_version.isNull()) return;

    setStatus(Status::Active);

    const auto network_key = network_key_from_app_name(app_name);

    m_controller->setEnabled(network->key() == network_key);

    if (network_key.isEmpty()) {
        if (device->type() == Device::LedgerNanoS) {
            if (app_version < QVersionNumber::fromString("2.0.0")) {
                m_controller->setStatus("outdated");
            }
        } else if (device->type() == Device::LedgerNanoX) {
            if (app_version < QVersionNumber::fromString("1.3.0")) {
                m_controller->setStatus("outdated");
            }
        } else {
            m_controller->setStatus("dashboard");
        }
    } else {
        if (device->type() == Device::LedgerNanoS) {
            if (network->isLiquid()) {
                if (app_version < QVersionNumber(1, 4, 8)) {
                    m_controller->setStatus("outdated");
                }
            } else {
                if (app_version < QVersionNumber(1, 6, 0)) {
                    m_controller->setStatus("outdated");
                }
            }
        } else if (device->type() == Device::LedgerNanoX) {
            if (app_version < QVersionNumber(1, 6, 1)) {
                m_controller->setStatus("outdated");
            }
        }
    }

    setStatus(Status::Finished);
}

LedgerIdentifyTask::LedgerIdentifyTask(LedgerDeviceController* controller)
    : Task(controller)
    , m_controller(controller)
{
}

void LedgerIdentifyTask::update()
{
    if (status() != Status::Ready) return;

    const auto network = m_controller->network();
    if (!network) return;

    const auto device = m_controller->device();
    if (!device) return;

    setStatus(Status::Active);

    qDebug() << "identifying, retrieve master public key";
    auto activity = device->getWalletPublicKey(network, {});
    QObject::connect(activity, &Activity::finished, this, [=] {
        activity->deleteLater();

        const auto master_xpub = activity->publicKey();
        Q_ASSERT(!master_xpub.isEmpty());

        qDebug() << "identifying, compute wallet hash id";
        const auto net_params = Json::fromObject({{ "name", network->id() }});
        const auto params = Json::fromObject({{ "master_xpub", QString::fromLocal8Bit(master_xpub) }});
        GA_json* output;
        int rc = GA_get_wallet_identifier(net_params.get(), params.get(), &output);
        Q_ASSERT(rc == GA_OK);
        const auto identifier = Json::toObject(output);
        GA_destroy_json(output);

        const auto wallet_hash_id = identifier.value("wallet_hash_id").toString();
        Q_ASSERT(!wallet_hash_id.isEmpty());

        m_controller->m_wallet_hash_id = wallet_hash_id;

        const auto wallet = WalletManager::instance()->walletWithHashId(wallet_hash_id, false);
        if (wallet) {
            m_controller->setWallet(wallet);
            const auto context = wallet->context();
            if (context) context->setDevice(device);
            wallet->updateDeviceDetails(device->details());
        }

        setStatus(Status::Finished);
    });
    QObject::connect(activity, &Activity::failed, this, [=] {
        activity->deleteLater();
        m_controller->setStatus("locked");
        setStatus(Status::Finished);
    });
    ActivityManager::instance()->exec(activity);
}

LedgerLoginTask::LedgerLoginTask(LedgerDeviceController* controller)
    : ContextTask(controller->context())
    , m_controller(controller)
{
}

void LedgerLoginTask::update()
{
    if (status() != Status::Ready) return;

    const auto network = m_controller->network();
    if (!network) return;

    const auto device = m_controller->device();
    if (!device) return;

    const auto session = m_context->session();
    if (!session) return;
    if (!session->isConnected()) return;

    setStatus(Status::Active);
    m_controller->setStatus("login");

    const auto device_details = device_details_from_device(device);

    auto session_register = new RegisterUserTask(device_details, m_context);
    auto session_login = new SessionLoginTask(device_details, m_context);

    session_register->then(session_login);

    group()->add(session_register);
    group()->add(session_login);

    connect(session_login, &Task::finished, this, [=] {
        auto wallet = m_controller->wallet();

        if (!wallet) {
            wallet = WalletManager::instance()->createWallet(network, m_controller->m_wallet_hash_id);
            wallet->m_is_persisted = true;
            wallet->setName(QString("%1 on %2").arg(network->displayName()).arg(device->name()));
            wallet->updateHashId(m_controller->m_wallet_hash_id);
            WalletManager::instance()->insertWallet(wallet);
            m_context->setWallet(wallet);
        }

        wallet->updateDeviceDetails(device->details());
        m_context->setDevice(device);
        m_context->session()->m_ready = true;
        // TODO should propagate to context

        m_controller->setWallet(wallet);
        setStatus(Status::Finished);
    });

//    QObject::connect(m_login_handler, &Handler::error, this, [=]{
//        setStatus("locked");
//        m_login_handler->deleteLater();
//        m_login_handler = nullptr;
//        signup();
//    });    
}
