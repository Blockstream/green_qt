#include "jadeupdatecontroller.h"

#include "httpmanager.h"
#include "jadeapi.h"
#include "jadedevice.h"
#include "progress.h"

#include <QCryptographicHash>
#include <QFile>
#include <QPointer>
#include <QTimer>

namespace {

const QString JADE_FW_VERSIONS_FILE = "LATEST";

static const QString JADE_FW_SERVER_HTTPS = "https://jadefw.blockstream.com";
static const QString JADE_FW_SERVER_ONION = "http://vgza7wu4h7osixmrx6e4op5r72okqpagr3w6oupgsvmim4cz3wzdgrad.onion";

static const QString JADE_BOARD_TYPE_JADE = "JADE";
static const QString JADE_BOARD_TYPE_JADE_V1_1 = "JADE_V1.1";
static const QString JADE_BOARD_TYPE_JADE_V2 = "JADE_V2";
static const QString JADE_BOARD_TYPE_JADE_V2C = "JADE_V2C";
static const QString JADE_FEATURE_SECURE_BOOT = "SB";

} // namespace

JadeHttpRequestTask::JadeHttpRequestTask(const QString& path, QObject* parent)
    : HttpRequestTask(parent)
{
    setMethod("GET");
    addUrl(JADE_FW_SERVER_HTTPS + path);
    addUrl(JADE_FW_SERVER_ONION + path);
}

JadeBinaryRequestTask::JadeBinaryRequestTask(const QString& path, QObject* parent)
    : JadeHttpRequestTask(path, parent)
{
    setAccept("base64");
}

JadeUpdateTask::JadeUpdateTask(const QVariantMap& firmware, const QByteArray& data, JadeDevice* device)
    : Task(device)
    , m_device(device)
    , m_firmware(firmware)
    , m_data(data)
{
    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(m_data);
    m_firmware.insert("cmphash", hash.result().toHex());
}

void JadeUpdateTask::update()
{
    if (m_status != Status::Ready) return;
    setStatus(Status::Active);

    auto backend = m_device->api();
    if (!backend) {
        qWarning() << Q_FUNC_INFO << "no backend";
        setStatus(Status::Failed);
        return;
    }
    const auto size = m_firmware.value("fwsize").toLongLong();
    const auto chunk_size = backend->relaxWrite() ? 256 : m_device->versionInfo().value("JADE_OTA_MAX_CHUNK").toInt();
    qDebug() << Q_FUNC_INFO << "start" << m_firmware.value("version").toString() << "delta" << m_firmware.value("delta").toBool()
             << "fwsize" << size << "cmpsize" << m_data.size() << "chunk" << chunk_size;

    auto progress_cb = [guard = QPointer<JadeUpdateTask>(this)](const QVariantMap& result) {
        if (!guard) return;
        Q_ASSERT(result.contains("uploaded"));
        const auto uploaded = result.value("uploaded").toLongLong();
        guard->progress()->setIndeterminate(uploaded <= 12288);
        guard->progress()->setValue(double(uploaded) / double(guard->m_data.size()));
    };
    auto done_cb = [guard = QPointer<JadeUpdateTask>(this)](const QVariantMap& result) {
        if (!guard) return;
        if (result["result"] == true) {
            guard->setStatus(Status::Finished);
        } else {
            const auto error = result.value("error").toMap();
            const auto code = error.value("code").toLongLong();
            const auto message = error.value("message").toString();
            const auto status = QString::fromLatin1(error.value("data").toByteArray());

#define CBOR_RPC_USER_CANCELLED -32000
#define CBOR_RPC_PROTOCOL_ERROR -32001
#define CBOR_RPC_HW_LOCKED -32002

            if (code == CBOR_RPC_USER_CANCELLED) {
                emit guard->cancelled();
                return;
            }

            // message `OTA is only allowed on new or logged-in device.` code is as follow:
            // in 0.1.21 code is CBOR_RPC_PROTOCOL_ERROR
            // in 0.1.23 and later is CBOR_RPC_HW_LOCKED
            if (code == CBOR_RPC_HW_LOCKED || message == "OTA is only allowed on new or logged-in device.") {
                emit guard->locked();
                return;
            }

            qDebug() << Q_FUNC_INFO << guard << "Unexpected error" << code << message << status;
            guard->abort(status.isEmpty() ? message : status);
        }
    };

    const auto fwhash = m_firmware.value("fwhash").toString();

    if (m_firmware.value("delta").toBool()) {
        const auto patch_size = m_firmware.value("patch_size").toInt();
        backend->otaDeltaUpdate(m_data, size, fwhash, patch_size, chunk_size, this, progress_cb, done_cb);
    } else {
        backend->otaUpdate(m_data, size, fwhash, chunk_size, this, progress_cb, done_cb);
    }
}

JadeFirmwareCheckController::JadeFirmwareCheckController(QObject *parent)
    : QObject(parent)
{
}

void JadeFirmwareCheckController::setDevice(JadeDevice *device)
{
    if (m_device == device) return;
    if (m_device) disconnect(m_device, nullptr, this, nullptr);
    m_device = device;
    emit deviceChanged();
    if (m_device) {
        connect(m_device, &JadeDevice::versionInfoChanged, this, [this] {
            check();
        });
        connect(m_device, &Device::connectedChanged, this, [this] {
            if (m_device && !m_device->isConnected()) {
                emit deviceDisconnected();
            }
        });
        // A Bluetooth Jade is deleted when it goes, while the firmware index
        // may still be on its way.
        connect(m_device, &QObject::destroyed, this, [this] {
            emit deviceChanged();
            check();
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

static QString TypeFromVersionInfo(const QVariantMap& version_info)
{
    const auto board_type = version_info.value("BOARD_TYPE", JADE_BOARD_TYPE_JADE).toString();
    const auto features = version_info.value("JADE_FEATURES").toStringList();
    const bool secure_boot = features.contains(JADE_FEATURE_SECURE_BOOT);

    if (board_type == JADE_BOARD_TYPE_JADE) {
        return secure_boot ? "jade" : "jadedev";
    }
    if (board_type == JADE_BOARD_TYPE_JADE_V1_1) {
        return secure_boot ? "jade1.1" : "jade1.1dev";
    }
    if (board_type == JADE_BOARD_TYPE_JADE_V2) {
        return secure_boot ? "jade2.0" : "jade2.0dev";
    }
    if (board_type == JADE_BOARD_TYPE_JADE_V2C) {
        return secure_boot ? "jade2.0c" : "jade2.0cdev";
    }
    return {};
}

void JadeFirmwareCheckController::check()
{
    m_firmwares.clear();
    m_firmware_available.clear();

    const bool debug_jade = qApp->arguments().contains("--debugjade");
    if (m_device && !m_index.isEmpty()) {
        const auto version_info = m_device->versionInfo();
        const auto type = TypeFromVersionInfo(version_info);
        const auto version = version_info.value("JADE_VERSION").toString();
        const auto config = version_info.value("JADE_CONFIG").toString().toLower();

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
                    const auto firmware_version_string = firmware.value("version").toString();
                    const auto firmware_version = QVersionNumber::fromString(firmware_version_string);
                    // QVersionNumber::fromString() drops non-numeric suffixes, so a pre-release like
                    // "1.0.33-beta1" parses equal to its final release "1.0.33". Track the exact string
                    // match separately so that case is still offered as an upgrade, while a truly
                    // already-installed version (exact match) is not.
                    const bool same_version = QVersionNumber::fromString(version) == firmware_version;
                    const bool exact_match = version == firmware_version_string;
                    const bool newer_version = QVersionNumber::fromString(version) < firmware_version || (same_version && !exact_match);
                    const bool same_config = config == firmware.value("config").toString();
                    const bool upgrade = newer_version || (same_version && !same_config);
                    const bool downgrade = firmware_version < QVersionNumber::fromString(version);
                    const bool installed = exact_match && same_config;
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

static QMap<QString, QPointer<HttpRequestTask>> g_jade_firmware_requests;
static QMap<QString, QJsonObject> g_jade_firmware_results;

JadeFirmwareController::JadeFirmwareController(QObject* parent)
    : QObject(parent)
{
}

void JadeFirmwareController::check(JadeDevice* device)
{
    if (!device) return;
    const auto type = TypeFromVersionInfo(device->versionInfo());
    if (g_jade_firmware_results.contains(type)) {
        m_index[type] = g_jade_firmware_results.value(type);
        emit indexChanged();
        return;
    }

    auto req = fetch(type);
    m_fetching ++;
    emit fetchingChanged();

    connect(req, &Task::finished, this, [=, this] {
        g_jade_firmware_results[type] = req->body().toJsonObject();
        m_index[type] = req->body().toJsonObject();

        emit indexChanged();
        m_fetching --;
        emit fetchingChanged();
    });
    connect(req, &Task::failed, this, [=, this] {
        m_fetching --;
        emit fetchingChanged();
    });
}

HttpRequestTask* JadeFirmwareController::fetch(const QString& type)
{
    auto req = g_jade_firmware_requests.value(type);
    if (req) return req;
    // The request is shared by every controller checking the same firmware type,
    // so it is owned by the HttpManager rather than by whichever controller
    // happens to request it first.
    req = new HttpRequestTask(HttpManager::instance());
    g_jade_firmware_requests.insert(type, req);
    req->setMethod("GET");
    req->addUrl(QString("%1/bin/%2/index.json").arg(JADE_FW_SERVER_HTTPS, type));
    req->addUrl(QString("%1/bin/%2/index.json").arg(JADE_FW_SERVER_ONION, type));
    // Bound to the request, not to this controller: the controller can be
    // destroyed first, which would leave a finished request cached forever.
    connect(req, &Task::finished, req, [=] {
        g_jade_firmware_requests.remove(type);
        req->deleteLater();
    });
    connect(req, &Task::failed, req, [=] {
        g_jade_firmware_requests.remove(type);
        req->deleteLater();
    });
    HttpManager::instance()->exec(req);
    return req;
}

JadeFirmwareUpdateController::JadeFirmwareUpdateController(QObject* parent)
    : QObject(parent)
{
}

JadeFirmwareUpdateController::~JadeFirmwareUpdateController()
{
    if (m_completing_api) m_completing_api->m_locked = false;
    m_completing_api = nullptr;
    m_completing_device = nullptr;
    m_completing = false;
    abortUpdate();
}

void JadeFirmwareUpdateController::setLocked(bool locked)
{
    if (auto api = m_device ? m_device->api() : nullptr) {
        api->m_locked = locked;
    }
}

void JadeFirmwareUpdateController::abortUpdate()
{
    if (m_completing) return;

    const auto task = m_task;
    auto* const api = m_device ? m_device->api() : nullptr;

    if (task) {
        // Stop reacting to the task; settlement is handled below.
        disconnect(task, nullptr, this, nullptr);
    }

    if (m_updating || m_fetching) {
        m_updating = false;
        m_fetching = false;
        emit updatingChanged();
        emit fetchingChanged();
    }

    if (!task) {
        if (api) api->m_locked = false;
        return;
    }

    const auto settle = [this, task, api] {
        if (m_task == task) m_task = nullptr;
        task->deleteLater();
        if (api) api->m_locked = false;
    };

    if (qobject_cast<JadeUpdateTask*>(task.data())) {
        // Unregister OTA callbacks while the task is still alive so their
        // done handler can reach a terminal state without use-after-free.
        // failPendingRequests() invokes handlers synchronously.
        if (api) api->failPendingRequests();
        settle();
        return;
    }

    // Firmware download: OTA has not started, so discovery can resume now.
    // Keep the task on HttpManager until HttpRequestTask's QtConcurrent
    // continuation runs (.then is bound to the task), then destroy it.
    task->setParent(HttpManager::instance());
    m_task = nullptr;
    if (api) api->m_locked = false;
    const auto status = task->status();
    if (status == Task::Status::Finished || status == Task::Status::Failed) {
        task->deleteLater();
        return;
    }
    connect(task, &Task::failed, task, &QObject::deleteLater);
    connect(task, &Task::finished, task, &QObject::deleteLater);
}

void JadeFirmwareUpdateController::setDevice(JadeDevice* device)
{
    if (m_device == device) return;
    if (m_device) {
        if (!(m_completing && m_device == m_completing_device)) {
            abortUpdate();
        }
        disconnect(m_device, nullptr, this, nullptr);
    }
    m_device = device;
    emit deviceChanged();
    if (!m_device) return;
    connect(m_device, &Device::connectedChanged, this, [this] {
        if (m_device && !m_device->isConnected()) {
            if (m_completing && m_device == m_completing_device) return;
            abortUpdate();
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
    setLocked(true);
    m_updating = true;
    emit updatingChanged();

    const auto type = m_firmware.value("type").toString();
    const auto path = m_firmware.value("filename").toString();

    m_fetching = true;
    emit fetchingChanged();

    qDebug() << Q_FUNC_INFO << "download" << type << path;
    auto task = new JadeBinaryRequestTask("/bin/" + type + "/" + path, HttpManager::instance());
    m_task = task;
    connect(task, &Task::failed, this, [=, this] {
        qWarning() << Q_FUNC_INFO << "download failed" << task->error();
        m_task = nullptr;
        task->deleteLater();
        m_fetching = false;
        emit fetchingChanged();
        m_updating = false;
        emit updatingChanged();
        setLocked(false);
        emit updateFailed(task->error());
    });
    connect(task, &Task::finished, this, [=, this] {
        m_task = nullptr;
        task->deleteLater();
        m_fetching = false;
        emit fetchingChanged();
        m_updating = false;
        emit updatingChanged();
        if (task->hasError()) {
            qDebug() << task->response();
            setLocked(false);
            emit updateFailed(task->error());
        } else {
            const auto data = QByteArray::fromBase64(task->body().toByteArray());
            qDebug() << Q_FUNC_INFO << "downloaded" << data.size() << "bytes";
            install(data);
        }
    });
    HttpManager::instance()->exec(task);
}

void JadeFirmwareUpdateController::install(const QByteArray& data)
{
    setLocked(true);
    m_started = false;
    auto task = new JadeUpdateTask(m_firmware, data, m_device);
    m_task = task;

    connect(task->progress(), &Progress::valueChanged, this, [=, this] {
        m_progress = float(task->progress()->value() - task->progress()->from()) /
                     float(task->progress()->to() - task->progress()->from());
        emit progressChanged();
        if (m_progress > 0 && !m_started) {
            m_started = true;
            emit updateStarted();
        }
    });
    connect(task, &JadeUpdateTask::cancelled, this, [=, this] {
        m_task = nullptr;
        task->deleteLater();
        m_updating = false;
        setLocked(false);
        emit updatingChanged();
        emit updateCancelled();
    });
    connect(task, &JadeUpdateTask::locked, this, [=, this] {
        m_task = nullptr;
        task->deleteLater();
        m_updating = false;
        setLocked(false);
        emit updatingChanged();
        emit unlockRequired();
    });
    connect(task, &Task::failed, this, [=, this] {
        m_task = nullptr;
        task->deleteLater();
        m_updating = false;
        setLocked(false);
        emit updatingChanged();
        if (m_device && m_device->isConnected()) {
            emit updateFailed(task->error());
        }
    });
    connect(task, &Task::finished, this, [=, this] {
        m_task = nullptr;
        auto version_info = m_device->versionInfo();
        version_info["JADE_VERSION"] = m_firmware["version"];
        version_info["JADE_CONFIG"] = m_firmware["config"];
        if (version_info["JADE_STATE"].toString() == "READY") {
            version_info["JADE_STATE"] = "LOCKED";
        }
        m_device->setVersionInfo(version_info);
        m_completing_device = m_device;
        m_completing_api = m_device ? m_device->api() : nullptr;
        m_completing = true;
        QPointer<JadeFirmwareUpdateController> self(this);
        QPointer<JadeAPI> api(m_completing_api);
        QTimer::singleShot(5000, this, [=, this] {
            if (!self) {
                if (api) api->m_locked = false;
                return;
            }
            if (api) {
                api->m_locked = false;
                api->disconnectDevice();
                api->connectDevice();
            }
            m_completing = false;
            m_completing_device = nullptr;
            m_completing_api = nullptr;
            emit updateFinished();
        });
    });
    qDebug() << Q_FUNC_INFO << "queue update task, connected" << m_device->isConnected();
    m_device->exec(task);
}
