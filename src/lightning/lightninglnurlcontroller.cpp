#include "lightninglnurlcontroller.h"

#include "context.h"
#include "lightninglnurl.h"
#include "lightningsession.h"
#include "lightningutil.h"

namespace {

QVariantMap AmountError(const QString& text, const quint64 amount)
{
    return {
        { QStringLiteral("text"), text },
        { QStringLiteral("amount"), QVariant::fromValue(amount) },
    };
}

} // namespace

LightningLnurlController::LightningLnurlController(QObject* parent)
    : Controller(parent)
{
    connect(this, &Controller::contextChanged, this, &LightningLnurlController::resolve);
}

QString LightningLnurlController::mapError(const QString& error) const
{
    return LightningLnurlUserFacingError(error);
}

void LightningLnurlController::setInput(const QString& input)
{
    if (m_input == input) return;
    m_input = input;
    m_entered_satoshi = {};
    m_comment = {};
    ++m_pay_id;
    ++m_resolve_id;
    clearRequest();
    clearPayment();
    setError({});
    setBusy(false);
    emit updated();
    resolve();
}

QVariantMap LightningLnurlController::request() const
{
    if (!m_request) return {};

    return {
        { QStringLiteral("callback"), m_request->callback },
        { QStringLiteral("minSendable"), QVariant::fromValue(LightningMsatToDisplaySatoshi(m_request->min_sendable_msat)) },
        { QStringLiteral("maxSendable"), QVariant::fromValue(LightningMsatToSatoshi(m_request->max_sendable_msat)) },
        { QStringLiteral("commentAllowed"), QVariant::fromValue(m_request->comment_allowed) },
        { QStringLiteral("description"), m_request->description },
        { QStringLiteral("metadata"), m_request->metadata },
        { QStringLiteral("lnurl"), m_request->lnurl },
        { QStringLiteral("domain"), m_request->domain },
        { QStringLiteral("image"), m_request->image },
    };
}

void LightningLnurlController::setEnteredSatoshi(const QString& entered_satoshi)
{
    if (m_busy) return;
    if (m_entered_satoshi == entered_satoshi) return;
    m_entered_satoshi = entered_satoshi;
    ++m_pay_id;
    clearPayment();
    setError({});
    emit updated();
}

void LightningLnurlController::setComment(const QString& comment)
{
    if (m_busy) return;
    if (m_comment == comment) return;
    m_comment = comment;
    ++m_pay_id;
    clearPayment();
    emit updated();
}

QVariantMap LightningLnurlController::amountError() const
{
    if (!m_request) return {};

    const auto amount_satoshi = amount();
    if (amount_satoshi == 0) return {};

    const auto min_satoshi = LightningMsatToDisplaySatoshi(m_request->min_sendable_msat);
    if (amount_satoshi < min_satoshi) {
        return AmountError(QStringLiteral("id_amount_below_minimum_allowed"), min_satoshi);
    }

    const auto max_satoshi = LightningMsatToSatoshi(m_request->max_sendable_msat);
    if (amount_satoshi > max_satoshi) {
        return AmountError(QStringLiteral("id_amount_above_maximum_allowed"), max_satoshi);
    }

    const auto max_payable = maxPayable();
    // No spendable Lightning liquidity (e.g. only channel reserves). This is not an
    // LNURL/endpoint max — ask the user to receive more before sending.
    if (max_payable == 0) {
        return AmountError(QStringLiteral("Lightning balance too low to send. Receive more sats to make it spendable."), 0);
    }

    const auto channel_balance = channelBalance();
    if (amount_satoshi > channel_balance) {
        return AmountError(QStringLiteral("id_insufficient_funds"), channel_balance);
    }

    if (amount_satoshi > max_payable) {
        return AmountError(QStringLiteral("id_amount_above_maximum_allowed"), max_payable);
    }

    return {};
}

QString LightningLnurlController::commentError() const
{
    if (!m_request) return {};

    if (m_request->comment_allowed == 0 && !m_comment.trimmed().isEmpty()) {
        return QStringLiteral("Comment is not allowed");
    }

    if (m_request->comment_allowed > 0 && LightningLnurlCommentLength(m_comment) > m_request->comment_allowed) {
        return QStringLiteral("Comment is too long");
    }

    return {};
}

bool LightningLnurlController::canContinue() const
{
    return !m_busy
        && m_request
        && !m_request->callback.isEmpty()
        && amount() > 0
        && amountError().isEmpty()
        && commentError().isEmpty()
        && m_error.isEmpty();
}

bool LightningLnurlController::canPay() const
{
    return canContinue();
}

void LightningLnurlController::resolve()
{
    if (m_input.trimmed().isEmpty() || !context()) {
        clearRequest();
        emit updated();
        return;
    }

    const auto lightning_session = context()->lightningSession();
    if (!lightning_session) {
        setError(QStringLiteral("Lightning session is not available"));
        return;
    }

    setError({});
    setBusy(true);

    const auto input = m_input;
    const auto resolve_id = ++m_resolve_id;
    auto future = lightning_session->resolveLnurlPay(input);
    future.then(this, [=, this](LightningValueResult<LightningLnurlPayRequest> result) {
        if (resolve_id != m_resolve_id) return;
        if (!result) {
            clearRequest();
            setError(result.error);
            setBusy(false);
            return;
        }

        m_request = *result.value;
        setBusy(false);
        emit updated();
    });

    waitForFuture(future);
}

void LightningLnurlController::pay()
{
    if (!canPay()) return;
    if (!context() || !m_request) return;

    const auto lightning_session = context()->lightningSession();
    if (!lightning_session) {
        setError(QStringLiteral("Lightning session is not available"));
        emit failed(QStringLiteral("Lightning session is not available"));
        return;
    }

    setError({});
    clearPayment();
    setBusy(true);

    const auto request = *m_request;
    const auto amount_msat = LightningSatoshiToMsat(amount());
    const auto comment = m_comment.trimmed();
    const auto pay_id = ++m_pay_id;
    auto future = lightning_session->lnurlPay(request, amount_msat, comment);
    future.then(this, [=, this](LightningValueResult<LightningLnurlPayResult> result) {
        if (pay_id != m_pay_id) return;
        if (!result) {
            setError(result.error);
            setBusy(false);
            emit failed(mapError(result.error));
            return;
        }

        m_success_action = result.value->success_action;
        setBusy(false);
        emit updated();
        emit paid();
    });

    waitForFuture(future);
}

quint64 LightningLnurlController::amount() const
{
    bool ok = false;
    const auto value = m_entered_satoshi.toULongLong(&ok);
    return ok ? value : 0;
}

quint64 LightningLnurlController::channelBalance() const
{
    if (!context()) return 0;
    return static_cast<quint64>(context()->lightningNodeInfo().value(QStringLiteral("channel_balance")).toInteger(0));
}

quint64 LightningLnurlController::maxPayable() const
{
    if (!context()) return 0;
    return static_cast<quint64>(context()->lightningNodeInfo().value(QStringLiteral("max_payable")).toInteger(0));
}

void LightningLnurlController::clearRequest()
{
    m_request = std::nullopt;
}

void LightningLnurlController::clearPayment()
{
    if (m_success_action.isEmpty()) return;
    m_success_action = {};
}

void LightningLnurlController::setBusy(const bool busy)
{
    if (m_busy == busy) return;
    m_busy = busy;
    emit updated();
}

void LightningLnurlController::setError(const QString& error)
{
    const auto mapped = mapError(error);
    if (m_error == mapped) return;
    m_error = mapped;
    emit updated();
}
