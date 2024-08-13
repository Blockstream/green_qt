#include "jadeupdatecontroller.h"

#include "activitymanager.h"
#include "httpmanager.h"
#include "jadeapi.h"
#include "jadedevice.h"
#include "json.h"
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
    auto backend = m_device->api();
    if (!backend) return;
    const auto nets = m_device->versionInfo().value("JADE_NETWORKS").toString();
    backend->authUser(nets == "TEST" ? "testnet" : "mainnet", [this](const QVariantMap& msg) {
        if (msg.contains("result") && msg["result"] == true) {
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
        jade.handleHttpResponse(id, req, res.value("body"));
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
    m_firmware.insert("cmphash", hash.result().toHex());
}

void JadeUpdateActivity::exec()
{
    auto backend = m_device->api();
    if (!backend) {
        fail();
        return;
    }
    const auto size = m_firmware.value("fwsize").toLongLong();
    const auto chunk_size = backend->relaxWrite() ? 256 : m_device->versionInfo().value("JADE_OTA_MAX_CHUNK").toInt();

    auto progress_cb = [this](const QVariantMap& result) {
        Q_ASSERT(result.contains("uploaded"));
        const auto uploaded = result.value("uploaded").toLongLong();
        progress()->setIndeterminate(uploaded <= 12288);
        progress()->setValue(double(uploaded) / double(m_data.size()));
    };
    auto done_cb = [=](const QVariantMap& result) {
        backend->m_locked = false;

        if (result["result"] == true) {
            finish();
        } else {
            const auto error = result.value("error").toMap();
            const auto code = error.value("code").toLongLong();
            const auto message = error.value("message").toString();

#define CBOR_RPC_USER_CANCELLED -32000
#define CBOR_RPC_PROTOCOL_ERROR -32001
#define CBOR_RPC_HW_LOCKED -32002

            if (code == CBOR_RPC_USER_CANCELLED) {
                emit cancelled();
                return;
            }

            // message `OTA is only allowed on new or logged-in device.` code is as follow:
            // in 0.1.21 code is CBOR_RPC_PROTOCOL_ERROR
            // in 0.1.23 and later is CBOR_RPC_HW_LOCKED
            if (code == CBOR_RPC_HW_LOCKED || message == "OTA is only allowed on new or logged-in device.") {
                emit locked();
                return;
            }

            qDebug() << Q_FUNC_INFO << this << "Unexpected error" << code << message;
            fail();
        }
    };

    const auto fwhash = m_firmware.value("fwhash").toString();

    backend->m_locked = true;

    if (m_firmware.value("delta").toBool()) {
        const auto patch_size = m_firmware.value("patch_size").toInt();
        backend->otaDeltaUpdate(m_data, size, fwhash, patch_size, chunk_size, progress_cb, done_cb);
    } else {
        backend->otaUpdate(m_data, size, fwhash, chunk_size, progress_cb, done_cb);
    }
}

JadeFirmwareCheckController::JadeFirmwareCheckController(QObject *parent)
    : QObject(parent)
{
}

void JadeFirmwareCheckController::setDevice(JadeDevice *device)
{
    if (m_device == device) return;
    m_device = device;
    emit deviceChanged();
    if (m_device) {
        connect(m_device, &JadeDevice::versionInfoChanged, this, [&] {
            check();
        });
        connect(m_device, &Device::connectedChanged, this, [&] {
            if (m_device && !m_device->isConnected()) {
                emit deviceDisconnected();
            }
        });
    }
    check();
}

void JadeFirmwareCheckController::setIndex(const QJsonObject& index)
{
    if (m_index == index) return;
    m_index = index;
    emit indexChanged();
    check();
}

void JadeFirmwareCheckController::check()
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

        QString type;
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

            QVersionNumber latest_version;
            for (const auto& channel : channels) {
                if (channel == "stable") {
                    auto index = m_index.value(type).toObject().value(channel).toObject();
                    for (const auto& value : index.value("full").toArray()) {
                        auto firmware = value.toObject();
                        const auto firmware_version = QVersionNumber::fromString(firmware.value("version").toString());
                        if (firmware_version > latest_version) {
                            latest_version = firmware_version;
                        }
                    }
                }
            }
            qDebug() << Q_FUNC_INFO << "latest stable version:" << latest_version;

            for (const auto& channel : channels) {
                auto index = m_index.value(type).toObject().value(channel).toObject();

                auto process = [&](bool delta, QJsonObject& firmware) {
                    const auto firmware_version = QVersionNumber::fromString(firmware.value("version").toString());
                    const bool same_version = QVersionNumber::fromString(version) == firmware_version;
                    const bool newer_version = QVersionNumber::fromString(version) < firmware_version;
                    const bool same_config = config == firmware.value("config").toString();
                    const bool upgrade = newer_version || (same_version && !same_config);
                    const bool downgrade = firmware_version < QVersionNumber::fromString(version);
                    const bool installed = same_version && same_config && version==firmware.value("version").toString();
                    const bool compatible = m_device->minimumRequiredVersion() <= firmware_version;
                    const bool latest = firmware_version == latest_version;
                    if (delta && installed) return;
                    firmware.insert("type", type);
                    firmware.insert("channel", channel);
                    firmware.insert("newer_version", newer_version);
                    firmware.insert("same_config", same_config);
                    firmware.insert("delta", delta);
                    firmware.insert("installed", installed);
                    firmware.insert("downgrade", downgrade);
                    firmware.insert("upgrade", upgrade);
                    firmware.insert("compatible", compatible);
                    firmware.insert("latest", latest);
                    firmware.insert("index", firmware_version.majorVersion() * 10000 + firmware_version.minorVersion() * 100 + firmware_version.microVersion());
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

            for (auto& value : m_firmwares) {
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


JadeFirmwareController::JadeFirmwareController(QObject* parent)
    : QObject(parent)
{
}

void JadeFirmwareController::setEnabled(bool enabled)
{
    if (m_enabled == enabled) return;
    m_enabled = enabled;
    emit enabledChanged();
    if (m_fetching) return;
    if (!m_index.isEmpty()) return;
    check();
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

JadeFirmwareUpdateController::JadeFirmwareUpdateController(QObject* parent)
    : QObject(parent)
{
}

void JadeFirmwareUpdateController::setDevice(JadeDevice* device)
{
    if (m_device == device) return;
    m_device = device;
    emit deviceChanged();
    connect(m_device, &Device::connectedChanged, this, [&] {
        if (m_device && !m_device->isConnected()) {
            emit deviceDisconnected();
        }
    });
}

void JadeFirmwareUpdateController::setFirmware(const QVariantMap& firmware)
{
    if (m_firmware == firmware) return;
    m_firmware = firmware;
    emit firmwareChanged();
}

float JadeFirmwareUpdateController::progress() const
{
    return qMax(0.0, (m_progress - 0.1) / 0.9);
}

void JadeFirmwareUpdateController::update()
{
    m_updating = true;
    emit updatingChanged();

    const auto type = m_firmware.value("type").toString();
    const auto path = m_firmware.value("filename").toString();

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
            install(data);
        }
    });
    emit activityCreated(activity);
    HttpManager::instance()->exec(activity);
}

void JadeFirmwareUpdateController::install(const QByteArray& data)
{
    m_started = false;
    auto activity = new JadeUpdateActivity(m_firmware, data, m_device);
    connect(activity->progress(), &Progress::valueChanged, this, [=] {
        m_progress = float(activity->progress()->value() - activity->progress()->from()) /
                     float(activity->progress()->to() - activity->progress()->from());
        emit progressChanged();
        if (m_progress > 0 && !m_started) {
            m_started = true;
            emit updateStarted();
        }
    });
    connect(activity, &JadeUpdateActivity::cancelled, this, [=] {
        activity->deleteLater();
        m_updating = false;
        emit updatingChanged();
        emit updateCancelled();
    });
    connect(activity, &JadeUpdateActivity::locked, this, [=] {
        activity->deleteLater();
        m_updating = false;
        emit updatingChanged();
        emit unlockRequired();
    });
    connect(activity, &Activity::failed, this, [=] {
        activity->deleteLater();
        m_updating = false;
        emit updatingChanged();
        emit updateFailed();
    });
    connect(activity, &Activity::finished, this, [=] {
        emit updateFinished();
        m_device->api()->disconnectDevice();
    });
    emit activityCreated(activity);
    ActivityManager::instance()->exec(activity);
}

