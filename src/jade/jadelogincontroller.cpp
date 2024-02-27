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

void JadeController::setDevice(JadeDevice* device)
{
    if (m_device == device) return;
    m_device = device;
    emit deviceChanged();
    connect(m_device, &Device::connectedChanged, this, [&] {
        if (m_device && !m_device->isConnected()) {
            emit disconnected();
        }
    });
}


JadeSetupController::JadeSetupController(QObject* parent)
    : JadeController(parent)
{
}

void JadeSetupController::setup(const QString& deployment)
{
    if (m_context) {
        m_context->deleteLater();
        setContext(nullptr);
    }
    setContext(new Context(deployment, this));
    m_context->setDevice(m_device);

    m_network = NetworkManager::instance()->networkForDeployment(deployment);
    auto session = m_context->getOrCreateSession(m_network);
    auto connect_session = new ConnectTask(session);
    auto setup = new JadeSetupTask(this);

    connect_session->then(setup);

    auto group = new TaskGroup(this);

    group->add(connect_session);
    group->add(setup);

    connect(group, &TaskGroup::finished, this, [=] {
        emit setupFinished(m_context);
    });

    dispatcher()->add(group);
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

    auto network = m_controller->network();
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
        const auto context = m_controller->context();
        const auto session = context->getOrCreateSession(network)->m_session;
        GA_http_request(session, params.get(), &output);
        auto res = Json::toObject(output);
        GA_destroy_json(output);
        jade.handleHttpResponse(id, req, res.value("body"));
    });
}

JadeUnlockController::JadeUnlockController(QObject* parent)
    : JadeController(parent)
{
}

void JadeUnlockController::setRemember(bool remember)
{
    if (m_remember == remember) return;
    m_remember = remember;
    emit rememberChanged();
    if (m_context) m_context->setRemember(remember);
}

void JadeUnlockController::unlock()
{
    if (!m_device) return;
    const auto nets = m_device->versionInfo().value("JADE_NETWORKS").toString();
    const QString deployment = nets == "ALL" || nets == "MAIN" ? "mainnet" : "testnet";
    if (m_context) {
        Q_ASSERT(m_context->deployment() == deployment);
    } else {
        setContext(new Context(deployment, this));
    }

    m_context->setRemember(m_remember);

    m_network = NetworkManager::instance()->networkForDeployment(deployment);
    auto session = m_context->getOrCreateSession(m_network);

    auto connect_session = new ConnectTask(session);
    auto unlock = new JadeUnlockTask(this);
    auto identify = new JadeIdentifyTask(this);

    connect_session->then(unlock);
    unlock->then(identify);

    auto group = new TaskGroup(this);

    group->add(connect_session);
    group->add(unlock);
    group->add(identify);

    dispatcher()->add(group);

    connect(group, &TaskGroup::finished, this, [=] {
        m_context->setDevice(m_device);

//        auto activity = m_device->getMasterBlindingKey();
//        connect(activity, &Activity::finished, [this, activity] {
//            activity->deleteLater();
//            qDebug() << "master_blinding_key" << QString::fromLocal8Bit(activity->masterBlindingKey().toHex());
//            Q_UNREACHABLE();
//        });
//        connect(activity, &Activity::failed, [=] {
//            Q_UNREACHABLE();
//        });
//        ActivityManager::instance()->exec(activity);

        emit unlocked(m_context);
    });

    connect(group, &TaskGroup::failed, this, [=] {
        emit invalidPin();
    });
}

static QJsonObject device_details_from_device(JadeDevice* device)
{
    const bool supports_external_blinding = QVersionNumber::fromString(device->version()) >= QVersionNumber(0, 1, 48);
    return {{
        "device", QJsonObject({
            { "name", device->uuid() },
            { "supports_arbitrary_scripts", true },
            { "supports_low_r", true },
            { "supports_liquid", 1 },
            { "supports_ae_protocol", 1 },
            { "supports_host_unblinding", true },
            { "supports_external_blinding", supports_external_blinding },
        })
    }};
}

JadeUnlockTask::JadeUnlockTask(JadeUnlockController* controller)
    : Task(controller)
    , m_controller(controller)
{
}

void JadeUnlockTask::update()
{
    if (m_status != Status::Ready) return;

    const auto device = m_controller->device();
    if (!device) return;

    if (device->state() == JadeDevice::StateReady) {
        setStatus(Status::Finished);
        return;
    }

//    if (device->state() != JadeDevice::StateUnsaved && device->state() == JadeDevice::StateUnsaved) {
//        setStatus(Status::Finished);
//        return;
//    }

    const auto network = m_controller->network();
    if (!network) return;

    setStatus(Status::Active);
    device->setUnlocking(true);

    if (!device->api()) {
        setStatus(Status::Failed);
        return;
    }

    device->api()->authUser(network->canonicalId(), [=](const QVariantMap& msg) {
        device->setUnlocking(false);
        if (msg.contains("result") && msg["result"] == true) {
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
        const auto context = m_controller->context();
        const auto session = context->getOrCreateSession(network)->m_session;
        GA_http_request(session, params.get(), &output);
        auto res = Json::toObject(output);
        GA_destroy_json(output);
        jade.handleHttpResponse(id, req, res.value("body"));
    });
}

JadeIdentifyTask::JadeIdentifyTask(JadeController* controller)
    : Task(controller)
    , m_controller(controller)
{
}

void JadeIdentifyTask::update()
{
    if (m_status != Status::Ready) return;

    const auto device = m_controller->device();
    if (!device) return;

    const auto nets = device->versionInfo().value("JADE_NETWORKS").toString();
    const QString deployment = nets == "ALL" || nets == "MAIN" ? "mainnet" : "testnet";
    const auto network = NetworkManager::instance()->networkForDeployment(deployment);
    if (!network) return;

    if (device->state() == JadeDevice::StateLocked) return;
    if (device->state() == JadeDevice::StateTemporary) {
        device->api()->authUser(network->canonicalId(), [=](const QVariantMap& msg) {
            device->updateVersionInfo();
        }, [=](JadeAPI& jade, int id, const QJsonObject& req) {
        });
        return;
    };

    auto context = m_controller->context();

    setStatus(Status::Active);

    auto activity = device->getWalletPublicKey(network, {});
    QObject::connect(activity, &Activity::finished, this, [=] {
        activity->deleteLater();

        const auto master_xpub = activity->publicKey();
        Q_ASSERT(!master_xpub.isEmpty());

        const auto net_params = Json::fromObject({{ "name", network->id() }});
        const auto params = Json::fromObject({{ "master_xpub", QString::fromLocal8Bit(master_xpub) }});
        GA_json* output;
        int rc = GA_get_wallet_identifier(net_params.get(), params.get(), &output);
        Q_ASSERT(rc == GA_OK);
        const auto identifier = Json::toObject(output);
        GA_destroy_json(output);

        const auto xpub_hash_id = identifier.value("xpub_hash_id").toString();
        context->setXPubHashId(xpub_hash_id);
        device->setXPubHashId(xpub_hash_id);

        setStatus(Status::Finished);
    });
    QObject::connect(activity, &Activity::failed, this, [=] {
        activity->deleteLater();

        setStatus(Status::Failed);
    });
    ActivityManager::instance()->exec(activity);
}
