#include "loginwithpincontroller.h"

#include "context.h"
#include "jadedevice.h"
#include "ledgerdevice.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
#include "session.h"
#include "task.h"
#include "wallet.h"
#include "walletmanager.h"

#include <QJsonDocument>

#include <gdk.h>

LoginController::LoginController(QObject* parent)
    : Controller(parent)
{
}

void LoginController::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
}

void LoginController::loginWithPin(const QString& pin)
{
    m_error.clear();

    if (!m_wallet) return;
    if (pin.isEmpty()) return;

    auto pin_data = qobject_cast<PinData*>(m_wallet->login());
    Q_ASSERT(pin_data);

    auto network = pin_data->network();
    if (!m_context) setContext(new Context(m_wallet->deployment(), false, this));

    auto session = m_context->getOrCreateSession(network);
    auto login_task = new LoginTask(pin, pin_data->data(), session);

    connect(login_task, &Task::failed, this, [=](const QString& error) {
        if (error == "id_invalid_pin") {
            pin_data->decrementAttempts();
            emit invalidPin();
        } else {
            m_error = error;
        }
    });

    connect(login_task, &Task::finished, this, [=] {
        pin_data->resetAttempts();
    });

    login(login_task);
}

static QJsonObject device_details_from_device(Device* device)
{
    auto jade_device = qobject_cast<JadeDevice*>(device);
    if (jade_device) {
        const bool supports_host_unblinding = QVersionNumber::fromString(jade_device->version()) >= QVersionNumber(0, 1, 27);
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
    auto ledger_device = qobject_cast<LedgerDevice*>(device);
    if (ledger_device) {
        return {{
            "device", QJsonObject({
                { "name", device->uuid() },
                { "supports_arbitrary_scripts", true },
                { "supports_low_r", false },
                { "supports_liquid", device->type() == Device::LedgerNanoS ? 1 : 0 }
            })
        }};
    }
    Q_UNREACHABLE();
}

static QString device_deployment(Device* device)
{
    auto jade_device = qobject_cast<JadeDevice*>(device);
    if (jade_device) {
        const auto networks = jade_device->versionInfo().value("JADE_NETWORKS").toString();
        if (networks == "TEST") return "testnet";
        return "mainnet";
    }
    auto ledger_device = qobject_cast<LedgerDevice*>(device);
    if (ledger_device) {
        const auto app = ledger_device->appName();
        if (app == "Bitcoin") return "mainnet";
        if (app == "Bitcoin Legacy") return "mainnet";
        if (app == "Liquid") return "mainnet";

        if (app == "Bitcoin Test") return "testnet";
        if (app == "Bitcoin Test Legacy") return "testnet";
        if (app == "Liquid Test") return "testnet";
        return {};
    }
    Q_UNREACHABLE();
}

void LoginController::loginWithDevice(Device* device, bool remember)
{
    m_error.clear();

    if (!m_context) {
        const auto deployment = device_deployment(device);
        if (deployment.isEmpty()) {
            emit loginFailed({});
            return;
        }
        setContext(new Context(deployment, false, this));
        m_context->setDevice(device);
        m_context->setRemember(remember);
    }

    const auto hw_device = device_details_from_device(device);
    auto session = m_context->primarySession();
    auto login_task = new LoginTask(hw_device, session);

    connect(login_task, &Task::finished, this, [=] {
        m_context->m_hw_device = hw_device;

        device->createSession(m_context->xpubHashId());

        m_wallet = m_context->wallet();
        if (!m_wallet) {
            for (auto w : WalletManager::instance()->getWallets()) {
                if (qobject_cast<DeviceData*>(w->login()) && w->xpubHashId() == m_context->xpubHashId()) {
                    m_wallet = w;
                    break;
                }
            }
        }
        if (!m_wallet) {
            // TODO: attempt to match with other wallets
            // auto master_xpub = device->masterPublicKey(NetworkManager::instance()->networkForDeployment(m_context->deployment()));
            // for (auto net : NetworkManager::instance()->networks()) {
            //     if (net->deployment() == m_context->deployment()) {
            //         const auto net_params = Json::fromObject({{ "name", net->id() }});
            //         const auto params = Json::fromObject({{ "master_xpub", QString::fromLocal8Bit(master_xpub) }});
            //         GA_json* output;
            //         int rc = GA_get_wallet_identifier(net_params.get(), params.get(), &output);
            //         Q_ASSERT(rc == GA_OK);
            //         const auto identifier = Json::toObject(output);
            //         GA_destroy_json(output);

            //         const auto wallet_hash_id = identifier.value("wallet_hash_id").toString();
            //         qDebug() << net->id() << wallet_hash_id;

            //         for (auto w : WalletManager::instance()->getWallets()) {
            //             if (qobject_cast<DeviceData*>(w->login()) && w->m_hashes.contains(wallet_hash_id)) {
            //                 m_wallet = w;
            //                 break;
            //             }
            //         }
            //         if (m_wallet) break;
            //     }
            // }
        }
        if (!m_wallet) {
            m_wallet = WalletManager::instance()->createWallet();
            m_wallet->m_deployment = m_context->deployment();
            m_wallet->setName(device->name());
            auto device_data = new DeviceData(m_wallet);
            device_data->setDevice(device->details());
            m_wallet->setLogin(device_data);
            m_wallet->m_is_persisted = m_context->remember();
            WalletManager::instance()->insertWallet(m_wallet);
        }
    });

    login(login_task);
}

void LoginController::login(LoginTask* login_task)
{
    clearErrors();

    auto group = new TaskGroup(this);
    group->setName("login");

    login(group, login_task);

    dispatcher()->add(group);

    connect(group, &TaskGroup::failed, this, [=] {
        emit loginFailed(m_error);
    });
    connect(group, &TaskGroup::finished, this, [=] {
        m_context->setWallet(m_wallet);
        emit loginFinished(m_context);
        setContext(nullptr);
    });
}

void LoginController::login(TaskGroup* group, LoginTask* login_task)
{
    auto session = m_context->primarySession();
    auto connect_session = new ConnectTask(session);
    auto get_credentials = new GetCredentialsTask(session);

    connect_session->then(login_task);
    login_task->then(get_credentials);

    connect(connect_session, &Task::failed, this, [=](const QString& error) {
        if (error == "timeout error") {
            m_error = "id_connection_failed";
        }
    });

    group->add(connect_session);
    group->add(login_task);
    group->add(get_credentials);
}

LoadController::LoadController(QObject* parent)
    : Controller(parent)
    , m_monitor(new TaskGroupMonitor(this))
{
    connect(m_monitor, &TaskGroupMonitor::allFinishedOrFailed, this, [=] {
        auto group = m_context->cleanAccounts();
        dispatcher()->add(group);
        connect(group, &TaskGroup::finished, this, [=] {
            auto wallet = m_context->wallet();
            Q_ASSERT(wallet);
            WalletManager::instance()->addWallet(wallet);
            wallet->setContext(m_context);
            for (auto session : m_context->getSessions()) {
                if (!session->m_wallet_hash_id.isEmpty()) {
                    wallet->m_hashes.insert(session->m_wallet_hash_id);
                }
            }
            wallet->save();
            emit loadFinished();
        });
    });
}

static bool compatibleToNetworks(Network* network, const QList<Network*> networks)
{
    for (auto net : networks) {
        if (net->isMainnet() != network->isMainnet()) return false;
        if (net->isDevelopment() != network->isDevelopment()) return false;
    }
    return true;
}

void LoadController::load()
{
    const auto networks = m_context->getActiveNetworks();

    auto group = new TaskGroup(this);

    for (auto network : networks) {
        loadNetwork(group, network);
    }

    m_monitor->add(group);
    dispatcher()->add(group);

    if (!m_context->isWatchonly()) {
        for (auto network : NetworkManager::instance()->networks()) {
            if (!compatibleToNetworks(network, networks)) continue;
            if (m_context->device() && !m_context->device()->supportsNetwork(network)) continue;
            qDebug() << Q_FUNC_INFO << "ATTEMPT LOGIN" << network->id() << network->name();
            loginNetwork(network);
        }
    }
}

void LoadController::loadNetwork(TaskGroup* group, Network* network)
{
    auto session = m_context->getOrCreateSession(network);
    if (!session->m_ready) return;
    if (m_context->isWatchonly() && session->network()->isLiquid()) {
        group->add(new LoadAssetsTask(session));
    }
    group->add(new GetWatchOnlyDetailsTask(session));
    group->add(new LoadTwoFactorConfigTask(session));
    group->add(new LoadCurrenciesTask(session));
    auto load_accounts = new LoadAccountsTask(false, session);
    connect(load_accounts, &Task::finished, this, [=] {
        for (auto account : load_accounts->accounts()) {
            group->add(new LoadBalanceTask(account));
        }
    });
    group->add(load_accounts);
}

void LoadController::loginNetwork(Network* network)
{
    auto group = new TaskGroup(this);
    group->setName(QString("load network %1").arg(network->id()));
    auto session = m_context->getOrCreateSession(network);
    auto connect_session = new ConnectTask(session);
    LoginTask* login{nullptr};

    if (m_context->device()) {
        login = new LoginTask(device_details_from_device(m_context->device()), session);
    } else if (m_context->credentials().contains("mnemonic")) {
        login = new LoginTask(m_context->credentials(), {}, session);
    }

    if (network->isLiquid() && !m_assets_loaded) {
        m_assets_loaded = true;
        auto load_assets = new LoadAssetsTask(session);
        connect_session->then(load_assets);
        load_assets->then(login);
        group->add(load_assets);
    }

    connect(connect_session, &Task::failed, this, [=](const QString& error) {
        if (error == "timeout error") {
            setError("session", "id_connection_failed");
        }
    });

    connect(login, &Task::finished, this, [=] {
        loadNetwork(group, network);
    });

    connect(login, &Task::failed, this, [=](const QString& error) {
        qDebug() << "ignoring login failed for network" << network->id() << "errr:" << error;
        m_context->releaseSession(session);
    });

    group->add(connect_session);
    group->add(login);

    m_monitor->add(group);
    dispatcher()->add(group);
}

PinDataController::PinDataController(QObject* parent)
    : Controller(parent)
{
}

void PinDataController::update(const QString& pin)
{
    if (!m_context) return;

    Q_ASSERT(m_context->wallet());

    auto session = m_context->primarySession();
    Q_ASSERT(session);

    auto task = new EncryptWithPinTask(m_context->credentials(), pin, session);
    connect(task, &Task::finished, this, [=] {
        auto wallet = m_context->wallet();
        auto pin = new PinData(wallet);
        pin->setNetwork(session->network());
        pin->setData(task->result().value("result").toObject().value("pin_data").toObject());
        wallet->setLogin(pin);
        wallet->save();
        emit finished();
    });
    dispatcher()->add(task);
}
