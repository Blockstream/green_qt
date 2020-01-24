#include "asset.h"
#include "wallet.h"

#include <QtMath>

Asset::Asset(const QString& id, Wallet* wallet)
    : QObject(nullptr)
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
    if (m_data.value("name").toString() == "btc") return wallet()->amountToSats(amount);

    auto precision = m_data.value("precision").toInt(0);
    bool ok;
    double result = amount.toDouble(&ok);
    if (!ok) return 0;
    result *= qPow(10, precision);
    return result;
}

QString Asset::formatAmount(qint64 amount) const
{
    if (m_data.value("name").toString() == "btc") return wallet()->formatAmount(amount);

    auto precision = m_data.value("precision").toInt(0);
    auto str = QString::number(static_cast<qreal>(amount) / qPow(10, precision), 'f', precision);

    auto ticker = m_data.value("ticker").toString();
    if (ticker.isEmpty()) return str;

    return str + " " + ticker;
}
