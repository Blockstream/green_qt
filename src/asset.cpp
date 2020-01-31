#include "asset.h"
#include "wallet.h"

#include <QDesktopServices>
#include <QUrl>
#include <QtMath>

Asset::Asset(const QString& id, Wallet* wallet)
    : QObject(wallet)
    , m_wallet(wallet)
    , m_id(id)
{
}

void Asset::setIcon(const QString &icon)
{
    if (m_icon == icon) return;
    m_icon = icon;
    emit iconChanged();
}

QString Asset::name() const
{
    auto name = m_data.value("name").toString();
    if (name.isEmpty()) return m_id;
    if (name == "btc") return "L-BTC";
    return name;
}

void Asset::setData(const QJsonObject &data)
{
    if (m_data == data) return;
    m_data = data;
    emit dataChanged();
}

qint64 Asset::parseAmount(const QString& amount) const
{
    if (m_data.value("name").toString() == "btc") {
        return wallet()->amountToSats(amount);
    }

    auto precision = m_data.value("precision").toInt(0);
    bool ok;
    double result = amount.toDouble(&ok);
    if (!ok) return 0;
    result *= qPow(10, precision);
    return result;
}

QString Asset::formatAmount(qint64 amount, bool include_ticker) const
{
    if (m_data.value("name").toString() == "btc") {
        return wallet()->formatAmount(amount, include_ticker);
    }

    auto precision = m_data.value("precision").toInt(0);
    auto str = QString::number(static_cast<qreal>(amount) / qPow(10, precision), 'f', precision);

    if (include_ticker) {
        auto ticker = m_data.value("ticker").toString();
        if (!ticker.isEmpty()) str += " " + ticker;
    }

    return str;
}

void Asset::openInExplorer() const
{
    QDesktopServices::openUrl({ "https://blockstream.info/liquid/asset/" + m_id });
}
