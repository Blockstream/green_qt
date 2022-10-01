#include "asset.h"

#include <QDesktopServices>
#include <QLocale>
#include <QtMath>
#include <QUrl>

#include "network.h"
#include "wallet.h"

Asset::Asset(const QString& id, Wallet* wallet)
    : QObject(wallet)
    , m_wallet(wallet)
    , m_id(id)
{
}

bool Asset::isLBTC() const
{
    return m_data.value("asset_id").toString() == m_wallet->network()->policyAsset();
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
    if (name == "btc") return "Liquid Bitcoin";
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
    if (isLBTC()) {
        return wallet()->amountToSats(amount);
    }

    QString sanitized_amount = amount;
    sanitized_amount.replace(',', '.');
    auto precision = m_data.value("precision").toInt(0);
    bool ok;
    double result = sanitized_amount.toDouble(&ok);
    if (!ok) return 0;
    result *= qPow(10, precision);
    return result;
}

QString Asset::formatAmount(qint64 amount, bool include_ticker, const QString& unit) const
{
    if (isLBTC()) {
        return wallet()->formatAmount(amount, include_ticker, unit);
    }

    auto precision = m_data.value("precision").toInt(0);
    auto str = QLocale::system().toString(static_cast<double>(amount) / qPow(10, precision), 'f', precision);

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
