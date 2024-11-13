#include "analytics.h"
#include "promo.h"
#include "settings.h"
#include "util.h"

static PromoManager* g_promo_manager{nullptr};

Promo::Promo(const QString& id, QObject* parent)
    : QObject(parent)
    , m_id(id)
{
    m_dismissed = Settings::instance()->promosDismissed().contains(m_id);
}

void Promo::setReady(bool ready)
{
    if (m_ready == ready) return;
    m_ready = ready;
    emit readyChanged();
}

void Promo::setData(const QJsonObject& data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged();
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

    if (!ExistsDataDir("promos")) {
        QDirIterator it(GetDataDir("promos"));
        while (it.hasNext()) {
            QJsonObject data;
            if (!ReadPromoRecord(it.next(), data)) continue;
            getOrCreatePromo(data);
        }
    }
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
    promo->setReady(true);
    return promo;
}
