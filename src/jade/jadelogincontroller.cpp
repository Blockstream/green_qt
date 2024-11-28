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
#include "util.h"
#include "wallet.h"
#include "walletmanager.h"

#include <gdk.h>

#include <wally_wrapper.h>

#include <QByteArray>
#include <QCryptographicHash>
#include <QFutureWatcher>
#include <QRandomGenerator>
#include <QtConcurrentRun>

namespace {

const QString g_ext_pubkey_pem{
    "-----BEGIN PUBLIC KEY-----\n"
    "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAyBnvF2+06j87PL4GztOf\n"
    "6OVPXoHObwU/fV3PJDWAY1kpWO2MRQUaM7xtb+XwEzt+Vw9it378nCVvREJ/4IWQ\n"
    "uVO8qQn2V1eASIoRtfM5HjERRtL4JUc7D1U2Vr4ecJEhQ1nSQuhuU9N2noo/tTxX\n"
    "nYIMiFOBJNPqzjWr9gTzcLdE23UjpasKMKyWEVPw0AGWl/aOGo8oAaGYjqB870s4\n"
    "29FBJeqOpaTHZqI/xp9Ac+R8gCP6H77vnSHGIxyZBIfcoPc9AFL83Ch0ugPLMQDf\n"
    "BsUzfi8gANHp6tKAjrH00wgHV1JC1hT7BRHffeqh9Tc7ERUmxg06ajBZf0XdWbIr\n"
    "tpNs6/YZJbv4S8+0VP9SRDOYigOuv/2nv16RyMO+TphH6PvwLQoRGixswICT2NBh\n"
    "oqTDi2kIwse51EYjLZ5Wi/n5WH+YtKs0O5cVY+0/mUMvknD7fBPv6+rvOr0OZu28\n"
    "1Qi+vZuP8it3qIdYybNmyD2FMGsYOb2OkIG2JC5GSn7YGwc+dRa87DGrG7S4rh4I\n"
    "qRCB9pudTntGoQNhs0G9aNNa36sUSp+FUAPB8r55chmQPVDv2Uqt/2cpfgy/UIPE\n"
    "DvMN0FWJF/3y6x0UOJiNK3VJKjhorYi6dRuJCmk6n+BLXHCaYvfLD7mEp0IEapo7\n"
    "VTWr98cwCwEqT+NTHm2FaNMCAwEAAQ==\n"
    "-----END PUBLIC KEY-----"
};

} // namespace

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

QSet<QByteArray> AllowedHosts()
{
    QSet<QByteArray> allowed;
    QSettings jade(GetDataFile("app", "jade.ini"), QSettings::IniFormat);
    int size = jade.beginReadArray("hosts");
    for (int i = 0; i < size; ++i) {
        jade.setArrayIndex(i);
        const auto hash = jade.value("hash").toString();
        allowed.insert(QByteArray::fromHex(hash.toUtf8()));
    }
    jade.endArray();
    return allowed;
}

bool IsHostAllowed(const QSet<QByteArray>& allowed, const QString& host)
{
    if (host == "jadepin.blockstream.com") return true;
    if (host == "j8d.io") return true;
    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(host.toUtf8());
    return allowed.contains(hash.result());
}

bool IsHostAllowed(const QStringList& hosts)
{
    const auto allowed = AllowedHosts();
    for (const auto host : hosts) {
        if (IsHostAllowed(allowed, host)) {
            return true;
        }
    }
    return false;
}

void AllowHost(QSet<QByteArray>& allowed, const QString& host)
{
    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(host.toUtf8());
    allowed.insert(hash.result());
}

void AllowHost(const QStringList& hosts)
{
    auto allowed = AllowedHosts();
    for (const auto host : hosts) {
        AllowHost(allowed, host);
    }
    const auto hashes = allowed.values();
    QSettings jade(GetDataFile("app", "jade.ini"), QSettings::IniFormat);
    jade.beginWriteArray("hosts", hashes.size());
    for (int i = 0; i < hashes.size(); ++i) {
        jade.setArrayIndex(i);
        jade.setValue("hash", QString::fromUtf8(hashes.at(i).toHex()));
    }
}

JadeHttpRequest *JadeController::handleHttpRequest(const QJsonObject& params)
{
    auto session = m_context->getOrCreateSession(m_network);
    auto request = new JadeHttpRequest(params, session);
    if (IsHostAllowed(request->hosts())) {
        request->accept(false);
    } else {
        emit httpRequest(request);
        connect(request, &JadeHttpRequest::accepted, [=](bool remember) {
            if (remember) {
                AllowHost(request->hosts());
            }
        });
    }
    return request;
}

JadeSetupController::JadeSetupController(QObject* parent)
    : JadeController(parent)
{
}

void JadeSetupController::setup(const QString& deployment)
{
    if (!m_monitor) setMonitor(new TaskGroupMonitor(this));
    if (!m_monitor->idle()) return;
    if (m_context) {
        m_context->deleteLater();
        setContext(nullptr);
    }
    setContext(new Context(deployment, false, this));
    m_context->setDevice(m_device);

    m_network = m_context->primaryNetwork();
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

    m_monitor->add(group);
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
    }, [=](JadeAPI& /*jade*/, int id, const QJsonObject& req) {
        QMetaObject::invokeMethod(m_controller, [=] {
            auto request = m_controller->handleHttpRequest(req.value("params").toObject());
            QObject::connect(request, &JadeHttpRequest::finished, [=](const QJsonObject& res) {
                m_controller->device()->api()->handleHttpResponse(id, req, res.value("body"));
            });
        }, Qt::QueuedConnection);
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
    if (!m_monitor) setMonitor(new TaskGroupMonitor(this));
    const auto nets = m_device->versionInfo().value("JADE_NETWORKS").toString();
    const QString deployment = nets == "ALL" || nets == "MAIN" ? "mainnet" : "testnet";
    if (m_context) {
        Q_ASSERT(m_context->deployment() == deployment);
    } else {
        setContext(new Context(deployment, false, this));
    }

    m_context->setDevice(m_device);
    m_context->setRemember(m_remember);

    m_network = m_context->primaryNetwork();
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
    monitor()->add(group);

    connect(group, &TaskGroup::finished, this, [=] {
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
        QMetaObject::invokeMethod(m_controller, [=] {
            auto request = m_controller->handleHttpRequest(req.value("params").toObject());
            QObject::connect(request, &JadeHttpRequest::finished, [=](const QJsonObject& res) {
                m_controller->device()->api()->handleHttpResponse(id, req, res.value("body"));
            });
        }, Qt::QueuedConnection);
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
    const auto network = m_controller->context()->primaryNetwork();
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

        device->createSession(xpub_hash_id);

        setStatus(Status::Finished);
    });
    QObject::connect(activity, &Activity::failed, this, [=] {
        activity->deleteLater();

        setStatus(Status::Failed);
    });
    ActivityManager::instance()->exec(activity);
}

JadeHttpRequest::JadeHttpRequest(const QJsonObject& params, Session* session)
    : QObject(session)
    , m_session(session)
    , m_params(params)
{
}

QStringList JadeHttpRequest::hosts() const
{
    QStringList hosts;
    for (auto url : m_params.value("urls").toArray()) {
        hosts.append(QUrl(url.toString()).authority());
    }
    return hosts;
}

QString JadeHttpRequest::path() const
{
    return m_params.value("urls").toArray().first().toString();
}

void JadeHttpRequest::accept(bool remember)
{
    Q_ASSERT(!m_busy);
    m_busy = true;
    emit busyChanged();

    auto context = m_session->context();
    context->dispatcher()->add(new ConnectTask(m_session));

    auto req = new HttpRequestTask(m_params, m_session);
    context->dispatcher()->add(req);

    connect(req, &HttpRequestTask::finished, this, [=] {
        req->deleteLater();
        emit finished(req->response());
    });

    emit accepted(remember);
}

void JadeHttpRequest::reject()
{
    emit rejected();
    emit finished({});
}

JadeQRController::JadeQRController(QObject *parent)
    : JadeController(parent)
{
}

void JadeQRController::process(const QJsonObject& result)
{
    const auto ur_type = result.value("ur_type").toString();

    if (ur_type == "jade-pin") {
        processJadePin(result.value("result").toObject());
    } else {
        Q_UNREACHABLE();
    }
}

void JadeQRController::processJadePin(const QJsonObject& result)
{
    const auto id = result.value("id").toString();
    Q_ASSERT(id == "qrauth");

    const auto req = result.value("result").toObject().value("http_request").toObject();
    const auto on_reply = req.value("on-reply").toString();
    const auto params = req.value("params").toObject();
    Q_ASSERT(on_reply == "pin");

    if (!m_context) {
        setContext(new Context("mainnet", false, this));
    }

    m_network = m_context->primaryNetwork();
    auto request = handleHttpRequest(params);
    QObject::connect(request, &JadeHttpRequest::finished, this, [=](const QJsonObject& res) {
        const auto params = res.value("body").toObject();
        QJsonObject data{
            { "id", "0" },
            { "method", "pin" },
            { "params", params },
        };

        QJsonObject details{
            { "ur_type", "jade-pin" },
            { "data", QString::fromLatin1(QCborMap::fromJsonObject(data).toCborValue().toCbor().toHex()) },
            { "max_fragment_len", 40 },
        };

        auto task = new EncodeBCURTask(details, m_context->primarySession());
        connect(task, &Task::finished, this, [=] {
            emit resultEncoded(task->result().value("result").toObject());
        });
        dispatcher()->add(task);
    });
}

JadeGenuineCheckController::JadeGenuineCheckController(QObject* parent)
    : JadeController(parent)
{
}

void JadeGenuineCheckController::genuineCheck()
{
    if (!m_device) return;
    if (!m_device->api()) return;

    QByteArray challenge(32, Qt::Uninitialized);
    QRandomGenerator::global()->generate(challenge.begin(), challenge.end());

    if (!m_context) {
        setContext(new Context("mainnet", false, this));
        // m_context->setDevice(m_device);
    }

    if (!m_monitor) {
        setMonitor(new TaskGroupMonitor(this));
    }

    if (!m_session) {
        auto network = m_context->primaryNetwork();
        m_session = m_context->getOrCreateSession(network);
    }

    m_device->api()->signAttestation(challenge, [=](const QVariantMap& msg) {
        qDebug() << Q_FUNC_INFO << msg;

        if (msg.contains("result")) {
            const auto result = msg.value("result").toMap();

            const auto ext_signature = result.value("ext_signature").toByteArray();
            const auto pubkey_pem = result.value("pubkey_pem").toString();
            const auto signature = result.value("signature").toByteArray();

            auto group = new TaskGroup(this);

            group->add(new ConnectTask(m_session));
            group->add(new RSAVerifyTask(pubkey_pem, challenge, signature, m_session));
            group->add(new RSAVerifyTask(g_ext_pubkey_pem, pubkey_pem.toLatin1(), ext_signature, m_session));

            connect(group, &TaskGroup::finished, this, &JadeGenuineCheckController::success);
            connect(group, &TaskGroup::failed, this, &JadeGenuineCheckController::failed);

            monitor()->add(group);
            dispatcher()->add(group);

            return;
        }

        if (msg.contains("error")) {
            const auto error = msg.value("error").toMap();
            const auto code = error.value("code").toLongLong();

            if (code == -32000) {
                emit cancelled();
                return;
            }

            if (code == -32603) {
                emit unsupported();
                return;
            }
        }

        qDebug() << Q_FUNC_INFO << msg;
        emit failed();
    });
}
