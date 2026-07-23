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
#include <QFutureSynchronizer>
#include <QPointer>
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

class ConvertPrivate
{
public:
    Context* context{nullptr};
    Account* account{nullptr};
    Asset* asset{nullptr};
    QString unit;
    QVariantMap input;
    QJsonObject result;
    int timer_id{-1};
    bool debug{false};
    QPointer<Session> connected_session;
    QFutureSynchronizer<void> future_synchronizer;
};

Convert::Convert(QObject* parent)
    : QObject(parent)
    , d_ptr(new ConvertPrivate)
{
}

Convert::~Convert()
{
    Q_D(Convert);
    d->future_synchronizer.waitForFinished();
    delete d;
}

Context* Convert::context() const
{
    Q_D(const Convert);
    return d->context;
}

Account* Convert::account() const
{
    Q_D(const Convert);
    return d->account;
}

Asset* Convert::asset() const
{
    Q_D(const Convert);
    return d->asset;
}

QVariantMap Convert::input() const
{
    Q_D(const Convert);
    return d->input;
}

QString Convert::unit() const
{
    Q_D(const Convert);
    return d->unit;
}

QJsonObject Convert::result() const
{
    Q_D(const Convert);
    return d->result;
}

bool Convert::debug() const
{
    Q_D(const Convert);
    return d->debug;
}

void Convert::setContext(Context* context)
{
    Q_D(Convert);
    if (d->context == context) return;
    d->context = context;
    emit contextChanged();
    invalidate();
    if (d->context) {
        connectToSessionSignals();
    }
}

void Convert::setAccount(Account* account)
{
    Q_D(Convert);
    if (d->account == account) return;
    d->account = account;
    emit accountChanged();
    emit isLiquidAssetChanged();
    invalidate();
    if (d->account) {
        setContext(d->account->context());
    }
}

void Convert::setInput(const QVariantMap& input)
{
    Q_D(Convert);
    if (d->input == input) return;
    d->input = input;
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
    Q_D(Convert);
    auto session = assetSession();

    // Disconnect from old session if different
    if (d->connected_session && session != d->connected_session) {
        disconnect(d->connected_session, nullptr, this, nullptr);
    }

    if (!session || session == d->connected_session) return;

    d->connected_session = session;
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
    Q_D(Convert);
    if (d->asset == asset) return;
    d->asset = asset;
    emit assetChanged();
    emit isLiquidAssetChanged();
    invalidate();
    if (d->asset) connectToSessionSignals();
}

void Convert::setUnit(const QString& unit)
{
    Q_D(Convert);
    if (d->unit == unit) return;
    d->unit = unit;
    emit unitChanged();
    emit outputChanged();
}

void Convert::changeUnit(const QString& unit)
{
    Q_D(Convert);
    if (d->unit == unit) return;
    d->unit = unit;
    const auto u = d->unit == "\u00B5BTC" ? "ubtc" : d->unit.toLower();
    auto value = d->result.value(u);
    if (!value.isNull()) {
        d->input = {{ u, value.toVariant() }};
    }
    emit unitChanged();
    emit outputChanged();
}

void Convert::setResult(const QJsonObject& result)
{
    Q_D(Convert);
    Q_ASSERT(!result.contains("satoshi") || result.value("satoshi").type() == QJsonValue::String);
    d->result = result;
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
    Q_D(const Convert);
    const auto empty_result = QVariantMap{
        { "label", "" },
        { "amount", "" },
        { "value", 0.0 },
        { "available", false },
        { "currency", d->result.value("fiat_currency").toString("") }
    };

    if (d->result.contains("fiat") && !d->result.value("fiat").isNull() && d->result.contains("fiat_currency")) {
        bool ok = false;
        const auto base = QLocale::c().toDouble(d->result.value("fiat").toString(), &ok);
        if (!ok) return empty_result;

        const auto currency = mainnet() ? d->result.value("fiat_currency").toString() : "FIAT";
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
    Q_D(const Convert);
    const auto result = format(d->unit);
    if (d->debug) qDebug() << Q_FUNC_INFO << result;
    return result;
}

void Convert::setDebug(bool debug)
{
    Q_D(Convert);
    d->debug = debug;
    emit debugChanged();
}

QString Convert::satoshi() const
{
    Q_D(const Convert);
    return d->result.value("satoshi").toString("0");
}

QVariantMap Convert::format(const QString& unit) const
{
    Q_D(const Convert);
    QVariantMap result{{ "label", "" }, { "amount", "" }, { unit, "" }};
    if (!d->context && !d->account) return result;
    if (isLiquidAsset()) {
        const auto precision = d->asset->precision();
        const auto satoshi = d->result.value("satoshi").toString(d->input.value("satoshi").toString());
        auto amount = QLocale::c().toString(satoshi.toDouble() / qPow(10, precision), 'f', precision);
        result["bip21_amount"] = amount;
        amount = number_to_string(QLocale::system(), amount, precision);
        result["amount"] = amount;
        if (d->asset->data().contains("ticker")) {
            const auto ticker = d->asset->data().value("ticker").toString();
            result["unit"] = ticker;
            result["label"] = amount + " " + ticker;
        } else {
            result["unit"] = QString();
            result["label"] = amount;
        }
    } else if (!unit.isEmpty()) {
        const auto unit_key = unit == "\u00B5BTC" ? "ubtc" : unit.toLower();
        const bool is_liquid = (d->account && d->account->isLiquid()) || (d->asset && d->asset->networkKey().contains("liquid"));
        const QString prefix{is_liquid ? "L" : ""};
        const QString display_unit = prefix + (mainnet() ? mainnetUnit(unit) : testnetUnit(unit));
        result["unit"] = display_unit;
        result["bip21_amount"] = d->result["btc"];
        if (!d->result.contains(unit_key)) return result;
        auto amount = d->result.value(unit_key).toString();
        amount = number_to_string(QLocale::system(), amount, 8);
        result["amount"] = amount;
        result["label"] = amount + " " + display_unit;
    }
    return result;
}

bool Convert::isLiquidAsset() const
{
  Q_D(const Convert);
  if (d->asset && d->asset->isLightning()) return false;
  if (d->account) {
    const auto network = d->account->network();
    return d->asset && network->isLiquid() && network->policyAsset() != d->asset->id();
  }

  if (d->asset) {
    for (const auto network : NetworkManager::instance()->networks()) {
      if (network->policyAsset() == d->asset->id()) {
        return false;
      }
    }
    return true;
  }

  return false;
}

Session* Convert::assetSession() const
{
    Q_D(const Convert);
    if (!d->context) return nullptr;

    const bool needsLiquid = isLiquidAsset();
    for (auto session : d->context->getSessions()) {
        if (session->network()->isLiquid() == needsLiquid) {
            return session;
        }
    }

    return d->context->primarySession();
}

void Convert::invalidate()
{
    Q_D(Convert);
    if (d->timer_id != -1) killTimer(d->timer_id);
    d->timer_id = startTimer(10);
}

void Convert::update()
{
    Q_D(Convert);
    if (d->debug) qDebug() << Q_FUNC_INFO;

    if (!d->context && !d->account) {
        setInput({});
        setResult({});
        return;
    }

    auto input = d->input;

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
            { "asset_id", d->asset->id() },
            { "precision", d->asset->precision() }
        });
    }

    if (details.contains("text")) {
        const auto text = details.take("text").toString();
        if (text.isEmpty()) {
            // no-op
        } else if (isLiquidAsset()) {
            details.insert(d->asset->id(), text);
        } else {
            const auto unit_key = d->unit == "\u00B5BTC" ? "ubtc" : d->unit.toLower();
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
    auto primary_session = d->context ? d->context->primarySession() : nullptr;
    if (primary_session && !details.contains("fiat_currency")) {
        const auto settings = primary_session->settings();
        const auto pricing = settings.value("pricing").toObject();
        const auto currency = pricing.value("currency").toString();
        details.insert("fiat_currency", currency);
    }

    const auto session = assetSession();
    if (!session) {
        qWarning() << Q_FUNC_INFO << "No session found for asset:" << (d->asset ? d->asset->id() : "null");
        setResult({});
        return;
    }

    auto future = QtConcurrent::run([=, this] {
        GA_json* output;
        const int rc = GA_convert_amount(session->m_session, Json::fromObject(details).get(), &output);
        if (rc == GA_OK) {
            const auto result = Json::toObject(output);
            GA_destroy_json(output);
            if (d->debug) qDebug() << Q_FUNC_INFO << session->network()->isLiquid() << details << result;
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

    d->future_synchronizer.addFuture(future);
}

bool Convert::mainnet() const
{
    Q_D(const Convert);
    if (!d->context && !d->account) return false;
    const auto context = d->context ? d->context : d->account->context();
    return context->isMainnet();
}

void Convert::timerEvent(QTimerEvent *event)
{
    Q_D(Convert);
    if (event->timerId() == d->timer_id) {
        killTimer(d->timer_id);
        d->timer_id = -1;
        update();
    }
}
