#include "account.h"
#include "asset.h"
#include "context.h"
#include "convert.h"
#include "ga.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
#include "session.h"

#include <gdk.h>

#include <QDebug>
#include <QtConcurrentRun>

#include <string>

static QString to_c(const QLocale& locale, QString number)
{
    bool ok = false;
    auto n = locale.toDouble(number, &ok);
    if (!ok) n = QLocale::c().toDouble(number);
    number = QLocale::c().toString(n, 'f', 10);
    const auto decimal_point = QLocale::c().decimalPoint();
    if (number.contains(decimal_point)) {
        number.replace(QRegularExpression("0+$"), {});
        if (number.endsWith(decimal_point)) {
            number = number.mid(0, number.length() - decimal_point.length());
        }
    }
    return number;
}

static QString number_to_string(const QLocale& locale, QString number, int precision)
{
    number = locale.toString(locale.QLocale::c().toDouble(number), 'f', precision);
    const auto decimal_point = locale.decimalPoint();
    if (number.contains(decimal_point)) {
        number.replace(QRegularExpression("0+$"), {});
        if (number.endsWith(decimal_point)) {
            number = number.mid(0, number.length() - decimal_point.length());
        }
    }
    return number;
}

Convert::Convert(QObject* parent)
    : QObject(parent)
{
}

void Convert::setContext(Context* context)
{
    if (m_context == context) return;
    m_context = context;
    emit contextChanged();
    invalidate();
    if (m_context) {
        connectToSessionSignals();
    }
}

void Convert::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
    emit isLiquidAssetChanged();
    invalidate();
    if (m_account) {
        setContext(m_account->context());
    }
}

void Convert::setInput(const QVariantMap& input)
{
    if (m_input == input) return;
    m_input = input;
    emit inputChanged();
    invalidate();
}

void Convert::clearInput()
{
    setInput({});
    emit inputCleared();
}

void Convert::connectToSessionSignals()
{
    auto session = assetSession();

    // Disconnect from old session if different
    if (m_connected_session && session != m_connected_session) {
        disconnect(m_connected_session, nullptr, this, nullptr);
    }

    if (!session || session == m_connected_session) return;

    m_connected_session = session;
    connect(session, &Session::settingsChanged, this, [=, this] {
        emit fiatChanged();
        invalidate();
    });
    connect(session, &Session::tickerEvent, this, [=, this] {
        emit fiatChanged();
        invalidate();
    });
}

void Convert::setAsset(Asset* asset)
{
    if (m_asset == asset) return;
    m_asset = asset;
    emit assetChanged();
    emit isLiquidAssetChanged();
    invalidate();
    if (m_asset) connectToSessionSignals();
}

void Convert::setUnit(const QString& unit)
{
    if (m_unit == unit) return;
    m_unit = unit;
    emit unitChanged();
    emit outputChanged();
}

void Convert::changeUnit(const QString& unit)
{
    if (m_unit == unit) return;
    m_unit = unit;
    const auto u = m_unit == "\u00B5BTC" ? "ubtc" : m_unit.toLower();
    auto value = m_result.value(u);
    if (!value.isNull()) {
        m_input = {{ u, value.toVariant() }};
    }
    emit unitChanged();
    emit outputChanged();
}

void Convert::setResult(const QJsonObject& result)
{
    Q_ASSERT(!result.contains("satoshi") || result.value("satoshi").type() == QJsonValue::String);
    m_result = result;
    emit resultChanged();
    emit fiatChanged();
    emit outputChanged();
}

QVariantMap Convert::fiat() const
{
    return formatFiat();
}

QVariantMap Convert::formatFiat(double additional_value) const
{
    const auto empty_result = QVariantMap{
        { "label", "" },
        { "amount", "" },
        { "value", 0.0 },
        { "available", false },
        { "currency", m_result.value("fiat_currency").toString("") }
    };

    if (m_result.contains("fiat") && !m_result.value("fiat").isNull() && m_result.contains("fiat_currency")) {
        bool ok = false;
        const auto base = QLocale::c().toDouble(m_result.value("fiat").toString(), &ok);
        if (!ok) return empty_result;

        const auto currency = mainnet() ? m_result.value("fiat_currency").toString() : "FIAT";
        const auto value = base + additional_value;
        const auto amount = number_to_string(QLocale::system(), QLocale::c().toString(value, 'f', 10), 2);

        return {
            { "label", amount + " " + currency },
            { "amount", amount },
            { "currency", currency },
            { "value", value },
            { "available", true }
        };
    }

    return empty_result;
}

static QString mainnetUnit(const QString& unit)
{
    if (unit == "BTC" || unit == "btc") return "BTC";
    if (unit == "mBTC" || unit == "mbtc") return "mBTC";
    if (unit == "\u00B5BTC" || unit == "\u00B5btc" || unit == "ubtc") return "\u00B5BTC";
    if (unit == "bits") return "bits";
    if (unit == "sats") return "sats";
    if (unit == "sats") return "sats";
    Q_UNREACHABLE();
}

static QString testnetUnit(const QString& unit)
{
    if (unit == "BTC" || unit == "btc") return "TEST";
    if (unit == "mBTC" || unit == "mbtc") return "mTEST";
    if (unit == "\u00B5BTC" || unit == "\u00B5btc" || unit == "ubtc") return "\u00B5TEST";
    if (unit == "bits") return "bTEST";
    if (unit == "sats") return "sTEST";
    if (unit == "sats") return "sTEST";
    Q_UNREACHABLE();
}

QVariantMap Convert::output() const
{
    const auto result = format(m_unit);
    if (m_debug) qDebug() << Q_FUNC_INFO << result;
    return result;
}

void Convert::setDebug(bool debug)
{
    m_debug = debug;
    emit debugChanged();
}

QString Convert::satoshi() const
{
    return m_result.value("satoshi").toString("0");
}

QVariantMap Convert::format(const QString& unit) const
{
    QVariantMap result{{ "label", "" }, { "amount", "" }, { unit, "" }};
    if (!m_context && !m_account) return result;
    if (isLiquidAsset()) {
        const auto precision = m_asset->precision();
        const auto satoshi = m_result.value("satoshi").toString(m_input.value("satoshi").toString());
        auto amount = QLocale::c().toString(satoshi.toDouble() / qPow(10, precision), 'f', precision);
        result["bip21_amount"] = amount;
        amount = number_to_string(QLocale::system(), amount, precision);
        result["amount"] = amount;
        if (m_asset->data().contains("ticker")) {
            const auto ticker = m_asset->data().value("ticker").toString();
            result["unit"] = ticker;
            result["label"] = amount + " " + ticker;
        } else {
            result["unit"] = QString();
            result["label"] = amount;
        }
    } else if (!unit.isEmpty()) {
        const auto unit_key = unit == "\u00B5BTC" ? "ubtc" : unit.toLower();
        const bool is_liquid = (m_account && m_account->isLiquid()) || (m_asset && m_asset->networkKey().contains("liquid"));
        const QString prefix{is_liquid ? "L" : ""};
        const QString display_unit = prefix + (mainnet() ? mainnetUnit(unit) : testnetUnit(unit));
        result["unit"] = display_unit;
        result["bip21_amount"] = m_result["btc"];
        if (!m_result.contains(unit_key)) return result;
        auto amount = m_result.value(unit_key).toString();
        amount = number_to_string(QLocale::system(), amount, 8);
        result["amount"] = amount;
        result["label"] = amount + " " + display_unit;
    }
    return result;
}

bool Convert::isLiquidAsset() const
{
  if (m_account) {
    const auto network = m_account->network();
    return m_asset && network->isLiquid() && network->policyAsset() != m_asset->id();
  }

  if (m_asset) {
    for (const auto network : NetworkManager::instance()->networks()) {
      if (network->policyAsset() == m_asset->id()) {
        return false;
      }
    }
    return true;
  }

  return false;
}

Session* Convert::assetSession() const
{
    if (!m_context) return nullptr;

    const bool needsLiquid = isLiquidAsset();
    for (auto session : m_context->getSessions()) {
        if (session->network()->isLiquid() == needsLiquid) {
            return session;
        }
    }

    return m_context->primarySession();
}

void Convert::invalidate()
{
    if (m_timer_id != -1) killTimer(m_timer_id);
    m_timer_id = startTimer(10);
}

void Convert::update()
{
    if (m_debug) qDebug() << Q_FUNC_INFO;

    if (!m_context && !m_account) {
        setInput({});
        setResult({});
        return;
    }

    auto input = m_input;

    for (auto key : input.keys()) {
        const auto value = input[key];
        if (value.isNull()) {
            input.remove(key);
        } else if (value.typeId() == QMetaType::QString) {
            int precision = key == "satoshi" || key == "sats" ? 0 : 8;
            const auto string = value.toString();
            if (string.isEmpty()) {
                input.remove(key);
            } else {
                input[key] = to_c(QLocale::system(), string);
            }
        } else {
            Q_ASSERT(key == "satoshi");
            input[key] = QLocale::c().toString(value.toLongLong());
        }
    }

    auto details = QJsonObject::fromVariantMap(input);
    if (isLiquidAsset()) {
        details.insert("asset_info", QJsonObject{
            { "asset_id", m_asset->id() },
            { "precision", m_asset->precision() }
        });
    }

    if (details.contains("text")) {
        const auto text = details.take("text").toString();
        if (text.isEmpty()) {
            // no-op
        } else if (isLiquidAsset()) {
            details.insert(m_asset->id(), text);
        } else {
            const auto unit_key = m_unit == "\u00B5BTC" ? "ubtc" : m_unit.toLower();
            details.insert(unit_key, text);
        }
    }

    auto satoshi = details.value("satoshi");
    if (satoshi.isString()) {
        details["satoshi"] = satoshi.toString().toLongLong();
    }
    if (details.isEmpty() || (details.keys().size() == 1 && details.keys()[0] == "asset_info")) {
        details["satoshi"] = 0;
    }

    // We need primary session to get user currency
    auto primary_session = m_context ? m_context->primarySession() : nullptr;
    if (primary_session && !details.contains("fiat_currency")) {
        const auto settings = primary_session->settings();
        const auto pricing = settings.value("pricing").toObject();
        const auto currency = mainnet() ? pricing.value("currency").toString() : "FIAT";
        details.insert("fiat_currency", currency);
    }

    const auto session = assetSession();
    if (!session) {
        qWarning() << Q_FUNC_INFO << "No session found for asset:" << (m_asset ? m_asset->id() : "null");
        setResult({});
        return;
    }

    auto future = QtConcurrent::run([=, this] {
        GA_json* output;
        const int rc = GA_convert_amount(session->m_session, Json::fromObject(details).get(), &output);
        if (rc == GA_OK) {
            const auto result = Json::toObject(output);
            GA_destroy_json(output);
            if (m_debug) qDebug() << Q_FUNC_INFO << session->network()->isLiquid() << details << result;
            return result;
        } else {
            qDebug() << Q_FUNC_INFO << details << gdk::get_thread_error_details();
            return QJsonObject{};
        }
    });

    future.then(this, [=, this](QJsonObject result) {
        auto satoshi = result.value("satoshi");
        if (!satoshi.isNull()) {
            result["satoshi"] = QLocale::c().toString(satoshi.toInteger());
        }
        setResult(result);
    });

    m_future_synchronizer.addFuture(future);
}

bool Convert::mainnet() const
{
    if (!m_context && !m_account) return false;
    const auto context = m_context ? m_context : m_account->context();
    return context->isMainnet();
}

void Convert::timerEvent(QTimerEvent *event)
{
    if (event->timerId() == m_timer_id) {
        killTimer(m_timer_id);
        m_timer_id = -1;
        update();
    }
}
