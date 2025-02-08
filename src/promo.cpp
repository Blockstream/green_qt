#include "analytics.h"
#include "promo.h"
#include "green_settings.h"
#include "util.h"

static PromoManager* g_promo_manager{nullptr};

Promo::Promo(const QString& id, QObject* parent)
    : QObject(parent)
    , m_id(id)
{
    m_dismissed = Settings::instance()->promosDismissed().contains(m_id);
    connect(this, &Promo::dataChanged, this, &Promo::readyChanged);
}

Promo::~Promo()
{
    if (m_dismissed) {
        for (const auto resource : m_resources.values()) {
            resource->purge();
        }
    }
}

bool Promo::ready() const
{
    for (auto i = m_resources.begin(); i != m_resources.end(); i++) {
        if (!i.value()->ready()) {
            return false;
        }
    }
    return true;
}

void Promo::setData(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged();

    // do not download resources if promo is dismissed
    if (m_dismissed) return;

    for (auto i = m_data.begin(); i != m_data.end(); i++) {
        if (i.key() == "link") continue;
        if (!i.value().isString()) continue;
        const auto value = i.value().toString();
        if (!value.startsWith("https://")) continue;
        auto resource = getOrCreateResource(i.key());
        resource->download(value);
    }
}

PromoResource* Promo::getOrCreateResource(const QString& name)
{
    auto resource = m_resources.value(name);
    if (!resource) {
        resource = new PromoResource(this);
        m_resources.insert(name, resource);
        connect(resource, &PromoResource::pathChanged, this, &Promo::readyChanged);
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
}

PromoManager::~PromoManager()
{
    g_promo_manager = nullptr;
}

PromoManager *PromoManager::instance()
{
    Q_ASSERT(g_promo_manager);
    return g_promo_manager;
}

QQmlListProperty<Promo> PromoManager::promos()
{
    return { this, &m_promos };
}

void PromoManager::update()
{
    const auto config = Analytics::instance()->getRemoteConfigValue("promos");
    if (!config.isArray()) return;
    for (const auto value : config.toArray()) {
        if (!value.isObject()) continue;
        const auto data = value.toObject();
        getOrCreatePromo(data);
    }
    emit changed();
}

Promo* PromoManager::getOrCreatePromo(const QJsonObject& data)
{
    const auto id = data.value("id").toString();
    auto promo = m_promo_by_id.value(id);
    if (!promo) {
        promo = new Promo(id, this);
        m_promo_by_id.insert(id, promo);
        m_promos.append(promo);
    }

    promo->setData(data);
    return promo;
}

PromoResource::PromoResource(QObject* parent)
    : QObject(parent)
{
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

    if (m_reply) return;

    QDir dir(GetDataDir("promos"));

    const auto url = QUrl(source);
    const auto suffix = QFileInfo(url.path()).suffix();
    const auto hash = Sha256(source);
    const auto name = hash + "." + suffix;
    const auto path = dir.absoluteFilePath(name);

    if (QFileInfo::exists(path)) {
        setPath(QUrl::fromLocalFile(path).toString());
    } else {
        QNetworkRequest req{source};
        auto engine = qmlEngine(PromoManager::instance());
        if (!engine) {
            qDebug() << Q_FUNC_INFO << "engine not set";
            return;
        }
        auto net = engine->networkAccessManager();
        if (!net) {
            qDebug() << Q_FUNC_INFO << "network access manager not set";
            return;
        }
        m_reply = net->get(req);
        connect(m_reply, &QNetworkReply::finished, this, [=] {
            QFile file(path);
            if (file.open(QIODevice::WriteOnly)) {
                file.write(m_reply->readAll());
                file.close();
            }
            setPath(QUrl::fromLocalFile(path).toString());
            m_reply->deleteLater();
            m_reply = nullptr;
        });
    }
}

void PromoResource::purge()
{
    auto path = QUrl(m_path).toLocalFile();
    QFile::remove(path);
}

bool PromoResource::ready() const
{
    return m_source.isEmpty() || !m_path.isEmpty();
}
