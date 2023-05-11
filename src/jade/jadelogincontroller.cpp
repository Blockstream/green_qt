#include "activitymanager.h"
#include "context.h"
#include "jadeapi.h"
#include "jadedevice.h"
#include "jadelogincontroller.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
#include "resolver.h"
#include "session.h"
#include "wallet.h"
#include "walletmanager.h"

#include <gdk.h>

#include <wally_wrapper.h>

JadeController::JadeController(QObject* parent)
    : Controller(parent)
{
}

Context* JadeController::ensureContext()
{
    if (!m_context) {
        auto context = new Context(this);
        setContext(context);
    }
    return m_context;
}

void JadeController::setDevice(JadeDevice* device)
{
    if (m_device == device) return;
    m_device = device;
    if (m_device) {
        QObject::connect(m_device, &JadeDevice::versionInfoChanged, m_dispatcher, &TaskDispatcher::dispatch);
    }
    emit deviceChanged();
    m_dispatcher->dispatch();
}


JadeSetupController::JadeSetupController(QObject* parent)
    : JadeController(parent)
{
}

void JadeSetupController::setup(const QString& network)
{
    ensureContext()->setNetwork(NetworkManager::instance()->network(network));

    auto connect_session = new SessionConnectTask(ensureContext()->session());
    auto setup = new JadeSetupTask(this);

    connect_session->then(setup);

    auto group = new TaskGroup(this);

    group->add(connect_session);
    group->add(setup);

    m_dispatcher->add(group);
}

JadeSetupTask::JadeSetupTask(JadeSetupController* controller)
    : Task(controller)
    , m_controller(controller)
{
}

void JadeSetupTask::update()
{
    if (m_status != Status::Ready) return;

    const auto device = m_controller->device();
    if (!device) return;

    if (!(device->state() == JadeDevice::StateUninitialized || device->state() == JadeDevice::StateUnsaved)) {
        setStatus(Status::Finished);
        return;
    }

    auto network = m_controller->ensureContext()->network();
    if (!network) return;

    setStatus(Status::Active);
    device->setUnlocking(true);

    device->api()->authUser(network->canonicalId(), [=](const QVariantMap& msg) {
        device->setUnlocking(false);

        Q_ASSERT(msg.contains("result"));
        if (msg["result"] == true) {
            device->updateVersionInfo();
            setStatus(Status::Finished);
        } else {
            qDebug() << "INVALID PIN";
            setStatus(Status::Failed);
            // TODO
            // emit invalidPin();
            // update();
        }
    }, [=](JadeAPI& jade, int id, const QJsonObject& req) {
        const auto params = Json::fromObject(req.value("params").toObject());

// TODO
//        const auto url = QUrl(req.value("params").toObject().value("urls").toArray().first().toString());
//        if (url.path() == "/set_pin") {
//            // copy current jade info since the signal is emitted asynchronously
//            const auto info = device->versionInfo();
//            QMetaObject::invokeMethod(m_controller, [=] { emit m_controller->setPin(info); }, Qt::QueuedConnection);
//        }

        GA_json* output;
        const auto context = m_controller->ensureContext();
        const auto session = context->session()->m_session;
        GA_http_request(session, params.get(), &output);
        auto res = Json::toObject(output);
        GA_destroy_json(output);
        jade.handleHttpResponse(id, req, res.value("body").toObject());
    });
}

JadeUnlockController::JadeUnlockController(QObject* parent)
    : JadeController(parent)
{
}

void JadeUnlockController::unlock()
{
    if (!m_device) return;
    const auto nets = m_device->versionInfo().value("JADE_NETWORKS").toString();
    ensureContext()->setNetwork(NetworkManager::instance()->network(nets == "ALL" || nets == "MAIN" ? "mainnet" : "testnet"));

    auto connect_session = new SessionConnectTask(ensureContext()->session());
    auto unlock = new JadeUnlockTask(this);

    connect_session->then(unlock);

    auto group = new TaskGroup(this);

    group->add(connect_session);
    group->add(unlock);

    m_dispatcher->add(group);
}

static QJsonObject device_details_from_device(JadeDevice* device)
{
    const bool supports_host_unblinding = QVersionNumber::fromString(device->version()) >= QVersionNumber(0, 1, 27);
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
    emit networkChanged();
    m_dispatcher->dispatch();
}

void JadeLoginController::setEnabled(bool enabled)
{
    if (m_enabled == enabled) return;
    m_enabled = enabled;
    emit isEnabledChanged();
}

void JadeLoginController::setWallet(Wallet *wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
}

void JadeLoginController::login()
{
    auto login = new JadeLoginTask(this);
    m_dispatcher->add(login);
}

JadeLoginController::JadeLoginController(QObject* parent)
    : JadeController(parent)
{
    auto identify = new JadeIdentifyTask(this);
    m_dispatcher->add(identify);
}

JadeUnlockTask::JadeUnlockTask(JadeController* controller)
    : Task(controller)
    , m_controller(controller)
{
}

void JadeUnlockTask::update()
{
    if (m_status != Status::Ready) return;

    const auto device = m_controller->device();
    if (!device) return;

    if (device->state() != JadeDevice::StateUnsaved && device->state() == JadeDevice::StateUnsaved) {
        setStatus(Status::Finished);
        return;
    }

    const auto network = m_controller->ensureContext()->network();
    if (!network) return;

    setStatus(Status::Active);
    device->setUnlocking(true);

    device->api()->authUser(network->canonicalId(), [=](const QVariantMap& msg) {
        device->setUnlocking(false);
        if (msg.contains("result") && msg["result"] == true) {
            device->updateVersionInfo();
            setStatus(Status::Finished);
        } else {
            qDebug() << "INVALID PIN";
            setStatus(Status::Failed);
            // TODO
            // emit invalidPin();
            // update();
        }
    }, [=](JadeAPI& jade, int id, const QJsonObject& req) {
        const auto params = Json::fromObject(req.value("params").toObject());

        const auto url = QUrl(req.value("params").toObject().value("urls").toArray().first().toString());
        if (url.path() == "/set_pin") {
            // copy current jade info since the signal is emitted asynchronously
            const auto info = device->versionInfo();
            QMetaObject::invokeMethod(m_controller, [=] { emit m_controller->setPin(info); }, Qt::QueuedConnection);
        }

        GA_json* output;
        const auto context = m_controller->ensureContext();
        const auto session = context->session()->m_session;
        GA_http_request(session, params.get(), &output);
        auto res = Json::toObject(output);
        GA_destroy_json(output);
        jade.handleHttpResponse(id, req, res.value("body").toObject());
    });
}

JadeIdentifyTask::JadeIdentifyTask(JadeLoginController* controller)
    : Task(controller)
    , m_controller(controller)
{
}

void JadeIdentifyTask::update()
{
    if (m_status != Status::Ready) return;

    const auto device = m_controller->device();
    if (!device) return;
    if (device->state() == JadeDevice::StateLocked) return;
    if (device->state() == JadeDevice::StateTemporary) return;

    const auto network = m_controller->ensureContext()->network();
    if (!network) return;

    setStatus(Status::Active);

    auto activity = device->getWalletPublicKey(network, {});
    QObject::connect(activity, &Activity::finished, this, [=] {
        activity->deleteLater();

        const auto master_xpub = activity->publicKey();
        Q_ASSERT(!master_xpub.isEmpty());

        const auto net_params = Json::fromObject({{ "name", m_controller->network() }});
        const auto params = Json::fromObject({{ "master_xpub", QString::fromLocal8Bit(master_xpub) }});
        GA_json* output;
        int rc = GA_get_wallet_identifier(net_params.get(), params.get(), &output);
        Q_ASSERT(rc == GA_OK);
        const auto identifier = Json::toObject(output);
        GA_destroy_json(output);

        m_controller->m_wallet_hash_id = identifier.value("wallet_hash_id").toString();

        setStatus(Status::Finished);
    });
    QObject::connect(activity, &Activity::failed, this, [=] {
        activity->deleteLater();

        setStatus(Status::Failed);
    });
    ActivityManager::instance()->exec(activity);
}

JadeLoginTask::JadeLoginTask(JadeLoginController* controller)
    : Task(controller)
    , m_controller(controller)
{
}

void JadeLoginTask::update()
{
    auto context = m_controller->ensureContext();
    auto network = NetworkManager::instance()->network(m_controller->network());
    auto device = m_controller->device();

    context->setNetwork(network);

    if (m_status == Status::Ready) {
        const auto device = m_controller->device();
        if (!device) return;
        if (device->state() == JadeDevice::StateLocked) return;
        if (device->state() == JadeDevice::StateTemporary) return;

        if (m_controller->m_wallet_hash_id.isEmpty()) return;

        const auto device_details = device_details_from_device(device);
        auto connect_session = new SessionConnectTask(context->session());
        auto session_register = new RegisterUserTask(device_details, context);
        auto session_login = new SessionLoginTask(device_details, context);
        auto get_credentials = new GetCredentialsTask(context);

        connect_session->then(session_register);
        session_register->then(session_login);
        session_login->then(get_credentials);

        group()->add(connect_session);
        group()->add(session_register);
        group()->add(session_login);
        group()->add(get_credentials);

        setStatus(Status::Active);

        return;
    }

    if (m_status == Status::Active) {
        if (context->m_wallet_hash_id.isEmpty()) return;

        if (context->m_wallet_hash_id != m_controller->m_wallet_hash_id) {
            setError("id_mismatch_wallet_hash_id");
            setStatus(Status::Failed);
            return;
        }

        auto wallet = WalletManager::instance()->walletWithHashId(context->m_wallet_hash_id, false);
        if (!wallet) {
            wallet = WalletManager::instance()->createWallet(network, context->m_wallet_hash_id);
            wallet->m_is_persisted = true;
            wallet->setName(QString("%1 on %2").arg(network->displayName()).arg(device->name()));
            WalletManager::instance()->insertWallet(wallet);
        }

        context->setDevice(device);
        context->setWallet(wallet);
        m_controller->setWallet(wallet);

        auto get_watchonly_details = new GetWatchOnlyDetailsTask(context);
        auto load_twofactor_config = new LoadTwoFactorConfigTask(context);
        auto load_currencies = new LoadCurrenciesTask(context);

        group()->add(get_watchonly_details);
        group()->add(load_twofactor_config);
        group()->add(load_currencies);
        if (wallet->network()->isLiquid()) {
            group()->add(new LoadAssetsTask(context));
        }
        group()->add(new LoadAccountsTask(context));

        connect(group(), &TaskGroup::finished, this, [=] {
            WalletManager::instance()->addWallet(wallet);
            // transfer context to wallet
            wallet->setContext(context);
            m_controller->setContext(nullptr);
            emit m_controller->loginDone();
        });

        setStatus(Status::Finished);
    }
}
