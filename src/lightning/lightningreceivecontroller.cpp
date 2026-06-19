#include "lightningreceivecontroller.h"

#include "analytics.h"
#include "context.h"
#include "lightningsession.h"
#include "transaction.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonValue>

namespace {
std::optional<quint64> ParseRemoteConfigSatoshi(const QString& key)
{
    const auto value = Analytics::instance()->getRemoteConfigString(key);
    const auto trimmed = value.trimmed();
    if (trimmed.isEmpty()) return std::nullopt;

    bool ok = false;
    const auto direct = trimmed.toULongLong(&ok);
    if (ok) return direct;

    return std::nullopt;
}

quint64 InboundLiquidity(Context* context)
{
    const auto lightning_session = context ? context->lightningSession() : nullptr;
    return lightning_session ? quint64(lightning_session->nodeInfo().value(QStringLiteral("inbound_liquidity")).toInteger(0)) : 0;
}
}

LightningReceiveController::LightningReceiveController(QObject* parent)
    : Controller(parent)
{
    connect(Analytics::instance(), &Analytics::remoteConfigChanged, this, [this] {
        updateLimits();
        emit updated();
    });
    updateLimits();
}

void LightningReceiveController::setSatoshi(const QString& satoshi)
{
    if (m_satoshi == satoshi) return;
    m_satoshi = satoshi;
    m_error = {};
    resetInvoice();
    emit updated();
}

void LightningReceiveController::setDescription(const QString& description)
{
    if (m_description == description) return;
    m_description = description;
    emit updated();
}

QString LightningReceiveController::error() const
{
    if (!m_error.isEmpty()) return m_error;

    const auto amount_satoshi = amount();
    if (amount_satoshi == 0) return {};
    if (m_max_satoshi && amount_satoshi > *m_max_satoshi) return QStringLiteral("maximum");

    const auto inbound_liquidity = InboundLiquidity(context());
    if (m_min_satoshi && inbound_liquidity <= 0 && amount_satoshi < *m_min_satoshi) return QStringLiteral("minimum");

    return {};
}

QVariant LightningReceiveController::minSatoshi() const
{
    return m_min_satoshi ? QVariant::fromValue(*m_min_satoshi) : QVariant();
}

QVariant LightningReceiveController::recommendedSatoshi() const
{
    return m_recommended_satoshi ? QVariant::fromValue(*m_recommended_satoshi) : QVariant();
}

QVariant LightningReceiveController::maxSatoshi() const
{
    return m_max_satoshi ? QVariant::fromValue(*m_max_satoshi) : QVariant();
}

QString LightningReceiveController::validationState() const
{
    if (!m_error.isEmpty()) return QStringLiteral("error");

    const auto amount_satoshi = amount();
    if (amount_satoshi == 0) return {};
    if (!error().isEmpty()) return QStringLiteral("error");

    const auto inbound_liquidity = InboundLiquidity(context());
    const auto needs_funding = inbound_liquidity <= 0 || amount_satoshi > inbound_liquidity;
    if (m_recommended_satoshi && needs_funding && amount_satoshi < *m_recommended_satoshi) {
        return QStringLiteral("warning");
    }
    if (needs_funding) {
        return QStringLiteral("info");
    }

    return {};
}

bool LightningReceiveController::canCreate() const
{
    return !m_busy && amount() > 0 && error().isEmpty();
}

void LightningReceiveController::createInvoice()
{
    if (!canCreate()) return;
    if (!context()) return;

    const auto lightning_session = context()->lightningSession();
    if (!lightning_session) {
        setError(QStringLiteral("Lightning session is not available"));
        return;
    }

    setError({});
    resetInvoice();
    setBusy(true);

    const auto satoshi = amount();
    const auto description = m_description;

    auto future = lightning_session->createInvoice(satoshi, description);
    future.then(this, [=, this](LightningCreateInvoiceResult result) {
        if (!result.error.isEmpty()) {
            setError(result.error);
            setBusy(false);
            return;
        }

        m_invoice = result.invoice;
        m_opening_fee_satoshi = result.opening_fee;
        m_expires_at = result.expires_at;

        setBusy(false);
        emit updated();
    });

    waitForFuture(future);
}

void LightningReceiveController::resetInvoice()
{
    if (m_invoice.isEmpty()
        && m_opening_fee_satoshi == 0
        && !m_expires_at.isValid()) {
        return;
    }
    m_invoice = {};
    m_opening_fee_satoshi = 0;
    m_expires_at = {};
    emit updated();
}

quint64 LightningReceiveController::amount() const
{
    bool ok = false;
    const auto value = m_satoshi.toULongLong(&ok);
    return ok ? value : 0;
}

void LightningReceiveController::setBusy(const bool busy)
{
    if (m_busy == busy) return;
    m_busy = busy;
    emit updated();
}

void LightningReceiveController::setError(const QString& error)
{
    if (m_error == error) return;
    m_error = error;
    emit updated();
}

void LightningReceiveController::updateLimits()
{
    m_min_satoshi = ParseRemoteConfigSatoshi(QStringLiteral("ln_min_satoshis"));
    m_recommended_satoshi = ParseRemoteConfigSatoshi(QStringLiteral("ln_recommended_satoshis"));
    m_max_satoshi = ParseRemoteConfigSatoshi(QStringLiteral("ln_max_satoshis"));
}
