#include "jadeupdatecontroller.h"
#include "jadedevice.h"
#include "network.h"
#include "networkmanager.h"
#include "semver.h"
#include "session.h"
#include "json.h"
#include "jadeapi.h"

#include <QFile>

#include <gdk.h>

namespace {

const QString JADE_FW_VERSIONS_FILE = "LATEST";

const QString JADE_FW_SERVER_HTTPS = "https://jadefw.blockstream.com";
static const QString JADE_FW_SERVER_ONION = "http://vgza7wu4h7osixmrx6e4op5r72okqpagr3w6oupgsvmim4cz3wzdgrad.onion";

static const QString JADE_FW_JADE_PATH = "/bin/jade/";
static const QString JADE_FW_JADE1_1_PATH = "/bin/jade1.1/";
static const QString JADE_FW_JADEDEV_PATH = "/bin/jadedev/";
static const QString JADE_FW_JADE1_1DEV_PATH = "/bin/jade1.1dev/";
static const QString JADE_FW_SUFFIX = "fw.bin";

static const QString JADE_BOARD_TYPE_JADE = "JADE";
static const QString JADE_BOARD_TYPE_JADE_V1_1 = "JADE_V1.1";
static const QString JADE_FEATURE_SECURE_BOOT = "SB";

} // namespace

JadeHttpRequestActivity::JadeHttpRequestActivity(const QString& path, Session* session)
    : HttpRequestActivity(session)
{
    setMethod("GET");
    addUrl(JADE_FW_SERVER_HTTPS + path);
    addUrl(JADE_FW_SERVER_ONION + path);
}

JadeChannelRequestActivity::JadeChannelRequestActivity(const QString& base, const QString& channel, Session* session)
    : JadeHttpRequestActivity(base + channel, session)
    , m_base(base)
{
    setAccept("text");
}

QVariantList JadeChannelRequestActivity::firmwares() const
{
    QVariantList firmwares;
    const auto body = response().value("body").toString();
    for (const auto& line : body.split('\n')) {
        const auto parts = line.split('_');
        if (parts.size() == 4 && parts.last() == JADE_FW_SUFFIX) {
            const auto version = parts[0];
            QVariantMap firmware;
            firmware.insert("path", m_base + line);
            firmware.insert("version", version);
            firmware.insert("config", parts[1]);
            firmware.insert("size", parts[2].toLongLong());
            firmwares.append(firmware);
        }
    }
    return firmwares;
}

JadeBinaryRequestActivity::JadeBinaryRequestActivity(const QString& path, Session* session)
    : JadeHttpRequestActivity(path, session)
{
    setAccept("base64");
}

JadeUnlockActivity::JadeUnlockActivity(const QString& network, JadeDevice* device)
    : Activity(device)
    , m_device(device)
    , m_network(network)
{
}

void JadeUnlockActivity::exec()
{
    m_device->m_jade->authUser(m_network, [this](const QVariantMap& msg) {
        Q_ASSERT(msg.contains("result"));
        if (msg["result"] == true) {
            finish();
        } else {
            fail();
        }
    });
}

JadeUpdateActivity::JadeUpdateActivity(const QVariantMap& firmware, const QByteArray& data, JadeDevice* device)
    : Activity(device)
    , m_device(device)
    , m_firmware(firmware)
    , m_data(data)
{
}

void JadeUpdateActivity::exec()
{
    const auto size = m_firmware.value("size").toLongLong();
    const auto chunk_size = m_device->versionInfo().value("JADE_OTA_MAX_CHUNK").toInt();

    m_device->m_jade->otaUpdate(m_data, size, chunk_size, [this](const QVariantMap& result) {
        Q_ASSERT(result.contains("uploaded"));
        const auto uploaded = result.value("uploaded").toLongLong();
        progress()->setIndeterminate(uploaded <= 12288);
        progress()->setValue(double(uploaded) / double(m_data.size()));
    }, [this](const QVariantMap& result) {
        if (result["result"] == true) {
            finish();
        } else {
            const auto error = result.value("error").toMap();
            const auto code = error.value("code").toLongLong();
            const auto message = error.value("message").toString();

#define CBOR_RPC_PROTOCOL_ERROR -32001
#define CBOR_RPC_HW_LOCKED -32002
            // message `OTA is only allowed on new or logged-in device.` code is as follow:
            // in 0.1.21 code is CBOR_RPC_PROTOCOL_ERROR
            // in 0.1.23 and later is CBOR_RPC_HW_LOCKED
            if (code == CBOR_RPC_HW_LOCKED || message == "OTA is only allowed on new or logged-in device.") {
                emit locked();
            } else {
                qDebug() << Q_FUNC_INFO << this << "Unexpected error" << code << message;
                fail();
            }
        }
    });
}

JadeUpdateController::JadeUpdateController(QObject *parent)
    : QObject(parent)
{
}

void JadeUpdateController::setChannel(const QString& channel)
{
    if (m_channel == channel) return;
    m_firmwares.clear();
    emit firmwaresChanged(m_firmwares);
    m_channel = channel;
    emit channelChanged(m_channel);
    check();
}

void JadeUpdateController::disconnectDevice()
{
    m_device->m_jade->disconnectDevice();
}

void JadeUpdateController::setDevice(JadeDevice *device)
{
    if (m_device == device) return;
    m_device = device;
    emit deviceChanged(m_device);
}

void JadeUpdateController::check()
{
    if (!m_device) return;

    if (!m_session) {
        m_session = new Session(this);

        connect(m_session, &Session::connectedChanged, this, &JadeUpdateController::check);
        connect(m_session, &Session::activityCreated, this, &JadeUpdateController::activityCreated);

        m_session->setNetwork(NetworkManager::instance()->network("mainnet"));
        m_session->setActive(true);

        emit sessionChanged(m_session);
    }

    if (!m_session->isActive() || !m_session->isConnected()) return;

    m_device->m_jade->setHttpRequestProxy([this](JadeAPI& jade, int id, const QJsonObject& req) {
        const auto params = Json::fromObject(req.value("params").toObject());
        GA_json* output;
        GA_http_request(m_session->m_session, params.get(), &output);
        auto res = Json::toObject(output);
        GA_destroy_json(output);
        jade.handleHttpResponse(id, req, res.value("body").toObject());
    });

    const auto version_info = m_device->versionInfo();
    const auto board_type = version_info.value("BOARD_TYPE", JADE_BOARD_TYPE_JADE).toString();
    const auto config = version_info.value("JADE_CONFIG").toString();
    const auto features = version_info.value("JADE_FEATURES").toStringList();
    const bool secure_boot = features.contains(JADE_FEATURE_SECURE_BOOT);

    QString path;
    if (board_type == JADE_BOARD_TYPE_JADE) {
        path = secure_boot ? JADE_FW_JADE_PATH : JADE_FW_JADEDEV_PATH;
    } else if (board_type == JADE_BOARD_TYPE_JADE_V1_1) {
        path = secure_boot ? JADE_FW_JADE1_1_PATH : JADE_FW_JADE1_1DEV_PATH;
    } else {
        return;
    }

    const QString channel = m_channel.isEmpty() ? JADE_FW_VERSIONS_FILE : m_channel;
    auto activity = new JadeChannelRequestActivity(path, channel, m_session);
    connect(activity, &Activity::finished, this, [this, activity, config] {
        activity->deleteLater();
        m_firmwares.clear();
        for (auto data : activity->firmwares()) {
            QVariantMap firmware = data.toMap();
            const bool installed = SemVer::parse(m_device->version()) == SemVer::parse(firmware.value("version").toString()) && config.compare(firmware.value("config").toString(), Qt::CaseInsensitive) == 0;
            firmware.insert("installed", installed);
            m_firmwares.append(firmware);
        }
        emit firmwaresChanged(m_firmwares);
    });
    activity->exec();
    emit activityCreated(activity);
}

void JadeUpdateController::update(const QVariantMap& firmware)
{
    const auto path = firmware.value("path").toString();
    const auto data = m_firmware_data.value(path);

    if (data.isEmpty()) {
        auto activity = new JadeBinaryRequestActivity(path, m_session);
        connect(activity, &Activity::failed, this, [activity] {
            activity->deleteLater();
        });
        connect(activity, &Activity::finished, this, [this, firmware, path, activity] {
            activity->deleteLater();
            const auto body = activity->response().value("body").toString();
            const auto data = QByteArray::fromBase64(body.toLocal8Bit());
            m_firmware_data.insert(path, data);
            update(firmware);
        });
        emit activityCreated(activity);
        activity->exec();
    } else {
        auto activity = new JadeUpdateActivity(firmware, data, m_device);
        connect(activity, &JadeUpdateActivity::locked, this, [this, activity] {
            auto unlock_activity = unlock();
            connect(unlock_activity, &Activity::finished, this, [activity, unlock_activity] {
                unlock_activity->deleteLater();
                activity->exec();
            });
            connect(unlock_activity, &Activity::failed, this, [activity, unlock_activity] {
                unlock_activity->deleteLater();
                activity->fail();
            });
        });
        connect(activity, &Activity::failed, this, [activity] {
            activity->deleteLater();
        });
        emit activityCreated(activity);
        activity->exec();
    }
}

JadeUnlockActivity* JadeUpdateController::unlock()
{
    const auto nets = m_device->versionInfo().value("JADE_NETWORKS").toString();
    auto activity = new JadeUnlockActivity(nets == "TEST" ? "testnet" : "mainnet", m_device);
    activity->exec();
    emit activityCreated(activity);
    return activity;
}
