#include "account.h"
#include "asset.h"
#include "context.h"
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

void Convert::setContext(Context* context)
{
    if (m_context == context) return;
    m_context = context;
    emit contextChanged();
}

void Convert::setAccount(Account* account)
{
    if (m_account == account) return;
    if (m_account) clearValue();
    m_account = account;
    emit accountChanged();
    invalidate();
    if (m_account) {
        connect(m_account->context()->primarySession(), &Session::unitChanged, this, &Convert::invalidate);
        connect(m_account->session(), &Session::tickerEvent, this, &Convert::invalidate);
    }
}

void Convert::setAsset(Asset* asset)
{
    if (m_asset == asset) return;
    if (m_asset) clearValue();
    m_asset = asset;
    emit assetChanged();
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

QString Convert::fiatLabel() const
{
    if (m_result.contains("fiat") && m_result.contains("fiat_currency")) {
        const auto currency = mainnet() ? m_result.value("fiat_currency").toString() : "FIAT";
        const auto amount = m_result.value("fiat").toString();
        return amount + " " + currency;
    }
    return {};
}

static QString testnetUnit(const QString& unit)
{
    if (unit == "BTC") return "TEST";
    if (unit == "mBTC") return "mTEST";
    if (unit == "\u00B5BTC") return "\u00B5TEST";
    if (unit == "bits") return "bTEST";
    if (unit == "sats") return "sTEST";
    Q_UNREACHABLE();
}

QString Convert::unitLabel() const
{
    if (!m_account) return {};
    const auto session = m_account->context()->primarySession();
    if (!session) return {};
    const auto unit = session->unit();
    const auto unit_key = unit == "\u00B5BTC" ? "ubtc" : unit.toLower();

    if (!m_result.contains(unit_key)) return {};
    const auto amount = m_result.value(unit_key).toString();
    return amount + " " + (mainnet() ? unit : testnetUnit(unit));
}

void Convert::invalidate()
{
    if (m_timer_id >= 0) killTimer(m_timer_id);
    m_timer_id = startTimer(0);
}

void Convert::update()
{
    qDebug() << Q_FUNC_INFO;

    if (!m_account) {
        setFiat(false);
        setResult({});
        return;
    }

    const auto network = m_account->network();
    const bool is_liquid_asset = m_asset && network->isLiquid() && network->policyAsset() != m_asset->id();
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

bool Convert::mainnet() const
{
    return m_account && m_account->context()->deployment() == "mainnet";
}

void Convert::timerEvent(QTimerEvent *event)
{
    if (event->timerId() == m_timer_id) {
        killTimer(m_timer_id);
        m_timer_id = -1;
        update();
    }
}

