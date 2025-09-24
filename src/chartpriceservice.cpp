#include "chartpriceservice.h"

#include <QQmlEngine>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrl>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>
#include <QDebug>

ChartPriceService::ChartPriceService(QObject* parent)
    : QObject(parent)
{
}

QString ChartPriceService::endpoint() const
{
    return QStringLiteral("https://green-btc-chart.blockstream.com/api/v1/bitcoin/prices?currency=%1").arg(m_currency);
}

void ChartPriceService::setCurrency(const QString& c)
{
    if (m_currency == c) return;
    m_currency = c;
    emit currencyChanged();
}

void ChartPriceService::refresh()
{
    auto engine = qmlEngine(this);
    if (!engine) return;
    auto net = engine->networkAccessManager();
    if (!net) return;
    QNetworkRequest req{ QUrl(endpoint()) };
    auto reply = net->get(req);
    connect(reply, &QNetworkReply::finished, this, &ChartPriceService::onReplyFinished);
}

void ChartPriceService::onReplyFinished()
{
    auto reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) return;
    const auto data = reply->readAll();
    const auto json = QJsonDocument::fromJson(data).object();
    auto flatten = [](const QJsonArray& arr) {
        QVariantList out;
        out.reserve(arr.size() * 2);
        for (const auto& v : arr) {
            const auto a = v.toArray();
            if (a.size() >= 2) {
                out.append(a.at(0).toVariant());
                out.append(a.at(1).toVariant());
            }
        }
        return out;
    };

    const auto arr_day = json.value("prices_day").toArray();
    const auto arr_month = json.value("prices_month").toArray();
    const auto arr_full = json.value("prices_full").toArray();
    qDebug() << Q_FUNC_INFO << "day:" << arr_day.size() << "month:" << arr_month.size() << "full:" << arr_full.size();

    m_prices_day = flatten(arr_day);
    m_prices_month = flatten(arr_month);
    m_prices_full = flatten(arr_full);
    // Derive week (7 days) from month timestamps; year (365 days) and five years (5*365)
    auto filterSince = [](const QVariantList& flat, qint64 cutoffMs) {
        QVariantList out;
        const int n = flat.size();
        out.reserve(n);
        for (int i = 0; i + 1 < n; i += 2) {
            const qint64 ts = flat.at(i).toLongLong();
            if (ts >= cutoffMs) {
                out.append(flat.at(i));
                out.append(flat.at(i + 1));
            }
        }
        return out;
    };
    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
    const qint64 weekMs = 7ll * 24 * 60 * 60 * 1000;
    const qint64 yearMs = 365ll * 24 * 60 * 60 * 1000;
    const qint64 fiveYearsMs = 5ll * 365 * 24 * 60 * 60 * 1000;
    m_prices_week = filterSince(m_prices_month, nowMs - weekMs);
    m_prices_year = filterSince(m_prices_full, nowMs - yearMs);
    m_prices_five_years = filterSince(m_prices_full, nowMs - fiveYearsMs);
    if (m_prices_day.size() >= 2) {
        qDebug() << Q_FUNC_INFO << "day first/last:" << m_prices_day.first() << m_prices_day.last();
    }
    emit pricesChanged();
}


