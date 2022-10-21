#include "jadeupdatecontroller.h"

#include "activitymanager.h"
#include "httpmanager.h"
#include "jadeapi.h"
#include "jadedevice.h"
#include "json.h"
#include "semver.h"
#include "session.h"

#include <QCryptographicHash>
#include <QFile>

#include <gdk.h>

namespace {

const QString JADE_FW_VERSIONS_FILE = "LATEST";

static const QString JADE_FW_SERVER_HTTPS = "https://jadefw.blockstream.com";
static const QString JADE_FW_SERVER_ONION = "http://vgza7wu4h7osixmrx6e4op5r72okqpagr3w6oupgsvmim4cz3wzdgrad.onion";

static const QString JADE_BOARD_TYPE_JADE = "JADE";
static const QString JADE_BOARD_TYPE_JADE_V1_1 = "JADE_V1.1";
static const QString JADE_FEATURE_SECURE_BOOT = "SB";

} // namespace

JadeHttpRequestActivity::JadeHttpRequestActivity(const QString& path, QObject* parent)
    : HttpRequestActivity(parent)
{
    setMethod("GET");
    addUrl(JADE_FW_SERVER_HTTPS + path);
    addUrl(JADE_FW_SERVER_ONION + path);
}

JadeBinaryRequestActivity::JadeBinaryRequestActivity(const QString& path, QObject* parent)
    : JadeHttpRequestActivity(path, parent)
{
    setAccept("base64");
}

JadeUnlockActivity::JadeUnlockActivity(JadeDevice* device, QObject* parent)
    : SessionActivity(parent)
    , m_device(device)
{
}

void JadeUnlockActivity::exec()
{
    const auto nets = m_device->versionInfo().value("JADE_NETWORKS").toString();
    m_device->api()->authUser(nets == "TEST" ? "testnet" : "mainnet", [this](const QVariantMap& msg) {
        Q_ASSERT(msg.contains("result"));
        if (msg["result"] == true) {
            finish();
        } else {
            fail();
        }
    }, [=](JadeAPI& jade, int id, const QJsonObject& req) {
        const auto params = Json::fromObject(req.value("params").toObject());
        GA_json* output;
        GA_http_request(session()->m_session, params.get(), &output);
        auto res = Json::toObject(output);
        GA_destroy_json(output);
        jade.handleHttpResponse(id, req, res.value("body").toObject());
    });
}

JadeUpdateActivity::JadeUpdateActivity(const QVariantMap& firmware, const QByteArray& data, JadeDevice* device)
    : Activity(device)
    , m_device(device)
    , m_firmware(firmware)
    , m_data(data)
{
    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(m_data);
    m_firmware.insert("hash", hash.result().toHex());
}

void JadeUpdateActivity::exec()
{
    const auto size = m_firmware.value("fwsize").toLongLong();
    const auto chunk_size = m_device->api()->relaxWrite() ? 256 : m_device->versionInfo().value("JADE_OTA_MAX_CHUNK").toInt();

    auto progress_cb = [this](const QVariantMap& result) {
        Q_ASSERT(result.contains("uploaded"));
        const auto uploaded = result.value("uploaded").toLongLong();
        progress()->setIndeterminate(uploaded <= 12288);
        progress()->setValue(double(uploaded) / double(m_data.size()));
    };
    auto done_cb = [this](const QVariantMap& result) {
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
    };

    if (m_firmware.value("delta").toBool()) {
        const auto patch_size = m_firmware.value("patch_size").toInt();
        m_device->api()->otaDeltaUpdate(m_data, size, patch_size, chunk_size, progress_cb, done_cb);
    } else {
        m_device->api()->otaUpdate(m_data, size, chunk_size, progress_cb, done_cb);
    }
}

JadeUpdateController::JadeUpdateController(QObject *parent)
    : QObject(parent)
{
}

void JadeUpdateController::disconnectDevice()
{
    m_device->api()->disconnectDevice();
}

void JadeUpdateController::setDevice(JadeDevice *device)
{
    if (m_device == device) return;
    m_device = device;
    emit deviceChanged(m_device);
    check();
}

void JadeUpdateController::setIndex(const QJsonObject& index)
{
    if (m_index == index) return;
    m_index = index;
    emit indexChanged();
    check();
}

void JadeUpdateController::check()
{
    m_firmwares.clear();
    m_firmware_available.clear();

    const bool debug_jade = qApp->arguments().contains("--debugjade");
    if (m_device && !m_index.isEmpty()) {
        const auto version_info = m_device->versionInfo();
        const auto version = version_info.value("JADE_VERSION").toString();
        const auto board_type = version_info.value("BOARD_TYPE", JADE_BOARD_TYPE_JADE).toString();
        const auto config = version_info.value("JADE_CONFIG").toString().toLower();
        const auto features = version_info.value("JADE_FEATURES").toStringList();
        const bool secure_boot = features.contains(JADE_FEATURE_SECURE_BOOT);

        if (board_type == JADE_BOARD_TYPE_JADE) {
            type = secure_boot ? "jade" : "jadedev";
        } else if (board_type == JADE_BOARD_TYPE_JADE_V1_1) {
            type = secure_boot ? "jade1.1" : "jade1.1dev";
        }

        if (!type.isEmpty()) {
            QStringList channels;
            if (debug_jade) channels.append("beta");
            channels.append("stable");
            if (debug_jade) channels.append("previous");

            QSet<QPair<QString, QString>> delta_available;

            for (const auto& channel : channels) {
                auto index = m_index.value(type).toObject().value(channel).toObject();

                auto process = [&](bool delta, QJsonObject& firmware) {
                    const bool same_version = SemVer::parse(version) == SemVer::parse(firmware.value("version").toString());
                    const bool newer_version = SemVer::parse(version) < SemVer::parse(firmware.value("version").toString());
                    const bool same_config = config == firmware.value("config").toString();
                    const bool upgrade = newer_version || (same_version && !same_config);
                    const bool downgrade = SemVer::parse(firmware.value("version").toString()) < SemVer::parse(version);
                    const bool installed = same_version && same_config;
                    if (delta && installed) return;
                    firmware.insert("channel", channel);
                    firmware.insert("newer_version", newer_version);
                    firmware.insert("same_config", same_config);
                    firmware.insert("delta", delta);
                    firmware.insert("installed", installed);
                    firmware.insert("downgrade", downgrade);
                    firmware.insert("upgrade", upgrade);
                    m_firmwares.append(firmware);
                };

                for (const auto& value : index.value("delta").toArray()) {
                    auto firmware = value.toObject();
                    if (version != firmware.value("from_version").toString()) continue;
                    if (config != firmware.value("from_config").toString()) continue;
                    firmware.insert("has_delta", false);
                    delta_available.insert(qMakePair(firmware.value("version").toString(), firmware.value("config").toString()));
                    process(true, firmware);
                }

                for (const auto& value : index.value("full").toArray()) {
                    auto firmware = value.toObject();
                    const bool has_delta = delta_available.contains(qMakePair(firmware.value("version").toString(), firmware.value("config").toString()));
                    firmware.insert("has_delta", has_delta);
                    process(false, firmware);
                }
            }

            for (const auto& value : m_firmwares) {
                auto firmware = value.toMap();
                if (firmware.value("channel").toString() == "stable" &&
                    firmware.value("same_config").toBool() &&
                    firmware.value("newer_version").toBool()) {
                    m_firmware_available = firmware;
                }
            }
        }
    }

    emit firmwaresChanged();
    emit firmwareAvailableChanged();
}

void JadeUpdateController::update(const QVariantMap& firmware)
{
    m_updating = true;
    emit updatingChanged();

    const auto path = firmware.value("filename").toString();

    m_fetching = true;
    emit fetchingChanged();

    auto activity = new JadeBinaryRequestActivity("/bin/" + type + "/" + path, this);
    connect(activity, &Activity::failed, this, [=] {
        activity->deleteLater();
        m_fetching = false;
        emit fetchingChanged();
        m_updating = false;
        emit updatingChanged();
    });
    connect(activity, &Activity::finished, this, [=] {
        activity->deleteLater();
        m_fetching = false;
        emit fetchingChanged();
        m_updating = false;
        emit updatingChanged();
        if (activity->hasError()) {
            qDebug() << activity->response();
        } else {
            const auto data = QByteArray::fromBase64(activity->body().toByteArray());
            install(firmware, data);
        }
    });
    emit activityCreated(activity);
    HttpManager::instance()->exec(activity);
}

void JadeUpdateController::install(const QVariantMap& firmware, const QByteArray& data)
{
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
    connect(activity, &Activity::failed, this, [=] {
        activity->deleteLater();
        m_updating = false;
        emit updatingChanged();
    });
    emit activityCreated(activity);
    ActivityManager::instance()->exec(activity);
}

JadeUnlockActivity* JadeUpdateController::unlock()
{
    auto activity = new JadeUnlockActivity(m_device, this);
    HttpManager::instance()->exec(activity);
    emit activityCreated(activity);
    return activity;
}

JadeFirmwareController::JadeFirmwareController(QObject* parent)
    : QObject(parent)
{
}

void JadeFirmwareController::check()
{
    fetch("jade");
    fetch("jade1.1");
    if (qApp->arguments().indexOf("--debugjade")) {
        fetch("jadedev");
        fetch("jade1.1dev");
    }
}

void JadeFirmwareController::fetch(const QString& type)
{
    auto req = new HttpRequestActivity(this);
    req->setMethod("GET");
    req->addUrl(QString("%1/bin/%2/index.json").arg(JADE_FW_SERVER_HTTPS, type));
    req->addUrl(QString("%1/bin/%2/index.json").arg(JADE_FW_SERVER_ONION, type));

    m_fetching ++;
    emit fetchingChanged();

    connect(req, &HttpRequestActivity::finished, this, [=] {
        m_index[type] = req->body().toJsonObject();

        emit indexChanged();
        m_fetching --;
        emit fetchingChanged();
    });
    connect(req, &HttpRequestActivity::failed, this, [=] {
        m_fetching --;
        emit fetchingChanged();
    });

    HttpManager::instance()->exec(req);
}
