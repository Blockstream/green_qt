#include "analytics.h"
#include "green_settings.h"
#include "promo.h"
#include "util.h"

#include <QJsonArray>
#include <QSaveFile>
#include <QSet>

static PromoManager* g_promo_manager{nullptr};

static bool IsHttpsUrl(const QString& value)
{
    const QUrl url(value, QUrl::StrictMode);
    return url.isValid() && url.scheme() == QStringLiteral("https") && !url.host().isEmpty();
}

static QJsonObject NormalizePromo(const QJsonValue& value)
{
    if (!value.isObject()) return {};

    auto data = value.toObject();
    const auto id = data.value("id");
    const auto title = data.value("title");
    const auto description = data.value("description");
    const auto cta = data.value("cta");
    if (!id.isString() || id.toString().trimmed().isEmpty()) return {};
    if (!title.isString() || title.toString().trimmed().isEmpty()) return {};
    if (!description.isString() || description.toString().trimmed().isEmpty()) return {};
    if (!cta.isObject()) return {};

    const auto cta_data = cta.toObject();
    const auto label = cta_data.value("label");
    const auto url = cta_data.value("url");
    if (!label.isString() || label.toString().trimmed().isEmpty()) return {};
    if (!url.isString() || !IsHttpsUrl(url.toString())) return {};

    const auto image_url = data.value("imageUrl");
    if (!image_url.isString() || !IsHttpsUrl(image_url.toString())) {
        data.remove("imageUrl");
    }
    return data;
}

Promo::Promo(const QString& id, PromoManager* manager)
    : QObject(manager)
    , m_manager(manager)
    , m_id(id)
{
    m_dismissed = Settings::instance()->promosDismissed().contains(m_id);
}

Promo::~Promo()
{
    if (m_dismissed) {
        for (auto it = m_resources.cbegin(), end = m_resources.cend(); it != end; ++it) {
            it.value()->purge();
        }
    }
}

void Promo::setData(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged();

    // do not download resources if promo is dismissed
    if (m_dismissed) return;

    const auto image_url = m_data.value("imageUrl").toString();
    auto resource = m_resources.value("imageUrl");
    if (!image_url.isEmpty() || resource) {
        resource = getOrCreateResource("imageUrl");
        resource->download(image_url);
    }
}

PromoResource* Promo::getOrCreateResource(const QString& name)
{
    auto resource = m_resources.value(name);
    if (!resource) {
        resource = new PromoResource(this);
        m_resources.insert(name, resource);
    }
    return resource;
}

void Promo::dismiss()
{
    if (m_dismissed) return;
    m_dismissed = true;
    emit dismissedChanged();
    Settings::instance()->dismissPromo(m_id);
}

static bool ReadPromoRecord(const QString& path, QJsonObject& data)
{
    QFile file(path);
    if (!file.open(QFile::ReadOnly)) return false;
    QJsonParseError parser_error;
    auto doc = QJsonDocument::fromJson(file.readAll(), &parser_error);
    if (parser_error.error != QJsonParseError::NoError) return false;
    if (!doc.isObject()) return false;
    data = doc.object();
    return data.contains("id");
}

PromoManager::PromoManager()
{
    Q_ASSERT(!g_promo_manager);
    g_promo_manager = this;

    connect(Analytics::instance(), &Analytics::remoteConfigChanged, this, &PromoManager::update);
    QTimer::singleShot(0, this, &PromoManager::update);
}

PromoManager::~PromoManager()
{
    g_promo_manager = nullptr;
}

QQmlListProperty<Promo> PromoManager::promos()
{
    return { this, &m_promos };
}

void PromoManager::update()
{
    const auto config = Analytics::instance()->getRemoteConfigValue("promos_v2");
    if (m_config == config) return;
    m_config = config;
    m_promos.clear();
    QSet<QString> ids;
    const auto values = config.isArray() ? config.toArray() : QJsonArray{};
    for (const auto value : values) {
        const auto data = NormalizePromo(value);
        if (data.isEmpty()) continue;
        const auto id = data.value("id").toString();
        if (ids.contains(id)) continue;
        ids.insert(id);
        createOrUpdatePromo(data);
    }
    emit changed();
    for (auto promo : m_promo_by_id.values()) {
        if (!m_promos.contains(promo)) {
            m_promo_by_id.remove(promo->id());
            promo->deleteLater();
        }
    }
}

void PromoManager::createOrUpdatePromo(const QJsonObject& data)
{
    const auto id = data.value("id").toString();
    auto promo = m_promo_by_id.value(id);
    if (!promo) {
        promo = new Promo(id, this);
        m_promo_by_id.insert(id, promo);
    }
    m_promos.append(promo);
    promo->setData(data);
}

PromoResource::PromoResource(Promo* promo)
    : QObject(promo)
    , m_promo(promo)
{
}

PromoResource::~PromoResource()
{
    if (!m_reply) return;
    auto reply = m_reply;
    m_reply = nullptr;
    reply->disconnect(this);
    reply->abort();
    reply->deleteLater();
}

void PromoResource::setPath(const QString& path)
{
    if (m_path == path) return;
    m_path = path;
    emit pathChanged();
}

void PromoResource::download(const QString& source)
{
    if (m_source == source) return;
    m_source = source;
    setPath({});

    if (m_reply) {
        auto reply = m_reply;
        m_reply = nullptr;
        reply->abort();
    }

    if (m_source.isEmpty()) return;
    downloadNow();
}

void PromoResource::downloadNow()
{
    if (m_source.isEmpty() || m_reply) return;

    QDir dir(GetDataDir("promos"));

    const auto url = QUrl(m_source);
    const auto suffix = QFileInfo(url.path()).suffix();
    const auto hash = Sha256(m_source);
    const auto name = hash + "." + suffix;
    const auto path = dir.absoluteFilePath(name);

    if (QFileInfo::exists(path)) {
        setPath(QUrl::fromLocalFile(path).toString());
        return;
    }

    QNetworkRequest req{m_source};
    auto engine = qmlEngine(promo()->manager());
    if (!engine) {
        qDebug() << Q_FUNC_INFO << "engine not set";
        QTimer::singleShot(1000, this, &PromoResource::downloadNow);
        return;
    }
    auto net = engine->networkAccessManager();
    if (!net) {
        qDebug() << Q_FUNC_INFO << "network access manager not set";
        QTimer::singleShot(1000, this, &PromoResource::downloadNow);
        return;
    }
    const auto source = m_source;
    auto reply = net->get(req);
    m_reply = reply;
    connect(reply, &QNetworkReply::finished, this, [=, this] {
        if (m_reply != reply) {
            reply->deleteLater();
            return;
        }
        m_reply = nullptr;
        if (m_source == source && reply->error() == QNetworkReply::NoError) {
            const auto contents = reply->readAll();
            QSaveFile file(path);
            if (!contents.isEmpty()
                    && file.open(QIODevice::WriteOnly)
                    && file.write(contents) == contents.size()
                    && file.commit()) {
                setPath(QUrl::fromLocalFile(path).toString());
            }
        }
        reply->deleteLater();
    });
}

void PromoResource::purge()
{
    auto path = QUrl(m_path).toLocalFile();
    QFile::remove(path);
}

