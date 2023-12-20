#include "account.h"
#include "asset.h"
#include "convert.h"
#include "json.h"
#include "network.h"
#include "session.h"

#include <gdk.h>

#include <QDebug>
#include <QtConcurrentRun>

Convert::Convert(QObject* parent)
    : QObject(parent)
{
}

void Convert::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
    clearValue();
    invalidate();
}

void Convert::setAsset(Asset* asset)
{
    if (m_asset == asset) return;
    m_asset = asset;
    emit assetChanged();
    clearValue();
    invalidate();
}

void Convert::setFiat(bool fiat)
{
    if (m_fiat == fiat) return;
    m_fiat = fiat;
    emit fiatChanged();
}

void Convert::setUnit(const QString& unit)
{
    if (m_unit == unit) return;
    m_unit = unit;
    emit unitChanged();
    if (m_result.contains(m_unit)) {
        setValue(m_result.value(m_unit).toString());
    }
    invalidate();
}

void Convert::setValue(const QString& value)
{
    if (m_value == value) return;
    m_value = value;
    emit valueChanged();
    invalidate();
}

void Convert::clearValue()
{
    setValue({});
}

void Convert::setResult(const QJsonObject& result)
{
    if (m_result == result) return;
    m_result = result;
    emit resultChanged();
}

void Convert::invalidate()
{
    if (m_timer_id < 0) {
        m_timer_id = startTimer(1);
    }
}

void Convert::update()
{
    qDebug() << Q_FUNC_INFO;

    if (!m_account || !m_asset) {
        setFiat(false);
        setResult({});
        return;
    }

    const auto network = m_account->network();
    const bool is_liquid_asset = network->isLiquid() && network->policyAsset() != m_asset->id();
    setFiat(!is_liquid_asset);

    const auto value = m_value.isEmpty() ? "0" : m_value;

    if (is_liquid_asset) {
        setResult({{ "satoshi", m_asset->parseAmount(value) }});
        return;
    }

    if (m_unit.isEmpty()) {
        setResult({});
        return;
    }

    QJsonObject details;
    details[m_unit] = value;

    using Watcher = QFutureWatcher<QJsonObject>;
    const auto watcher = new Watcher(this);
    const auto session = m_account->session()->m_session;
    watcher->setFuture(QtConcurrent::run([=] {
        GA_json* output;
        const int rc = GA_convert_amount(session, Json::fromObject(details).get(), &output);
        if (rc == GA_OK) {
            const auto result = Json::toObject(output);
            GA_destroy_json(output);
            return result;
        } else {
            return QJsonObject{};
        }
    }));

    connect(watcher, &Watcher::finished, this, [=] {
        watcher->deleteLater();
        setResult(watcher->result());
    });
}

void Convert::timerEvent(QTimerEvent *event)
{
    if (event->timerId() == m_timer_id) {
        killTimer(m_timer_id);
        m_timer_id = -1;
        update();
    }
}

