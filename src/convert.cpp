#include "account.h"
#include "asset.h"
#include "context.h"
#include "convert.h"
#include "json.h"
#include "network.h"
#include "networkmanager.h"
#include "session.h"

#include <gdk.h>

#include <QDebug>
#include <QtConcurrentRun>


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
    if (m_context) setSession(m_context->primarySession());
}

void Convert::setAccount(Account* account)
{
    if (m_account == account) return;
    if (m_account) clearInput();
    m_account = account;
    emit accountChanged();
    invalidate();
    if (m_account) setSession(m_account->session());
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

void Convert::setSession(Session* session)
{
    connect(session, &Session::settingsChanged, this, [=] {
        emit fiatChanged();
        invalidate();
    });
    connect(session, &Session::tickerEvent, this, [=] {
        emit fiatChanged();
        invalidate();
    });
}

void Convert::setAsset(Asset* asset)
{
    if (m_asset == asset) return;
    if (m_asset) clearInput();
    m_asset = asset;
    emit assetChanged();
    invalidate();
}

void Convert::setUnit(const QString& unit)
{
    if (m_unit == unit) return;
    m_unit = unit;
    emit unitChanged();
    emit outputChanged();
}

void Convert::setResult(const QJsonObject& result)
{
    Q_ASSERT(!result.contains("satoshi") || result.value("satoshi").type() == QJsonValue::String);
    if (m_result == result) return;
    m_result = result;
    emit resultChanged();
    emit fiatChanged();
    emit outputChanged();
}

QVariantMap Convert::fiat() const
{
    if (m_result.contains("fiat") && m_result.contains("fiat_currency")) {
        const auto currency = mainnet() ? m_result.value("fiat_currency").toString() : "FIAT";
        const auto amount = number_to_string(QLocale::system(), m_result.value("fiat").toString(), 2);
        return {
            { "label", amount + " " + currency },
            { "amount", amount },
            { "currency", currency },
            { "available", true }
        };
    } else {
        return {
            { "label", "" },
            { "amount", "" },
            { "available", false }
        };
    }
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
    return format(m_unit);
}

QString Convert::satoshi() const
{
    return m_result.value("satoshi").toString("0");
}

QVariantMap Convert::format(const QString& unit) const
{
    QVariantMap result{{ "label", "" }, { "amount", "" }};
    if (!m_context && !m_account) return result;
    if (m_liquid_asset) {
        const auto precision = m_asset->data().value("precision").toInt(0);
        const auto satoshi = m_result.value("satoshi").toString();
        auto amount = QLocale::c().toString(satoshi.toDouble() / qPow(10, precision), 'f', precision);
        result["bip21_amount"] = amount;
        amount = number_to_string(QLocale::system(), amount, precision);
        result["amount"] = amount;
        if (m_asset->data().contains("ticker")) {
            const auto ticker = m_asset->data().value("ticker").toString();
            result["label"] = amount + " " + ticker;
        } else {
            result["label"] = amount;
        }
    } else if (!unit.isEmpty()) {
        const auto unit_key = unit == "\u00B5BTC" ? "ubtc" : unit.toLower();
        const QString prefix{m_account && m_account->isLiquid() ? "L-" : ""};
        result["label"] = prefix + (mainnet() ? unit : testnetUnit(unit));
        result["bip21_amount"] = m_result["btc"];
        if (!m_result.contains(unit_key)) return result;
        auto amount = m_result.value(unit_key).toString();
        amount = number_to_string(QLocale::system(), amount, 8);
        result["amount"] = amount;
        result["label"] = amount + " " + result["label"].toString();
    }
    return result;
}

void Convert::invalidate()
{
    if (m_timer_id != -1) killTimer(m_timer_id);
    m_timer_id = startTimer(0);
}

void Convert::update()
{
    if (!m_context && !m_account) {
        setInput({});
        setResult({});
        return;
    }

    if (m_account) {
        const auto network = m_account->network();
        m_liquid_asset = m_asset && network->isLiquid() && network->policyAsset() != m_asset->id();
    } else if (m_asset) {
        m_liquid_asset = true;
        for (const auto network : NetworkManager::instance()->networks()) {
            if (network->deployment() == m_context->deployment()) {
                if (network->policyAsset() == m_asset->id()) {
                    m_liquid_asset = false;
                    break;
                }
            }
        }
    } else {
        m_liquid_asset = false;
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

    if (m_liquid_asset) {
        if (input.contains("text")) {
            Q_ASSERT(input.value("text").typeId() == QMetaType::QString);
            const auto text = input.value("text").toString();
            const auto precision = m_asset->data().value("precision").toInt(0);
            const auto satoshi = static_cast<qint64>(text.toDouble() * qPow(10, precision));
            setResult({{ "satoshi", QLocale::c().toString(satoshi) }});
        } else if (input.contains("satoshi")) {
            Q_ASSERT(input.value("satoshi").typeId() == QMetaType::QString);
            const auto satoshi = input.value("satoshi").toString();
            setResult({{ "satoshi", satoshi }});
        } else {
            setResult({{ "satoshi", "0" }});
        }
        return;
    }

    auto details = QJsonObject::fromVariantMap(input);
    if (details.contains("text")) {
        const auto text = details.take("text").toString();
        const auto unit_key = m_unit == "\u00B5BTC" ? "ubtc" : m_unit.toLower();
        if (!text.isEmpty()) details.insert(unit_key, text);
    }

    auto satoshi = details.value("satoshi");
    if (satoshi.isString()) {
        details["satoshi"] = satoshi.toString().toLongLong();
    }
    if (details.isEmpty()) {
        details["satoshi"] = 0;
    }

    using Watcher = QFutureWatcher<QJsonObject>;
    const auto watcher = new Watcher(this);
    const auto session = m_account ? m_account->session() : m_context->primarySession();
    watcher->setFuture(QtConcurrent::run([=] {
        GA_json* output;
        const int rc = GA_convert_amount(session->m_session, Json::fromObject(details).get(), &output);
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
        QJsonObject result = watcher->result();
        auto satoshi = result.value("satoshi");
        if (!satoshi.isNull()) {
            result["satoshi"] = QLocale::c().toString(satoshi.toInteger());
        }
        setResult(result);
    });
}

bool Convert::mainnet() const
{
    if (!m_context && !m_account) return false;
    const auto context = m_context ? m_context : m_account->context();
    return context->deployment() == "mainnet";
}

void Convert::timerEvent(QTimerEvent *event)
{
    if (event->timerId() == m_timer_id) {
        killTimer(m_timer_id);
        m_timer_id = -1;
        update();
    }
}

