#include "lightningsendcontroller.h"

#include "account.h"
#include "asset.h"
#include "context.h"
#include "lightningsession.h"
#include "lightningutil.h"
#include "network.h"
#include "wallet.h"

#include <QDateTime>
#include <QJsonObject>

namespace {

quint64 NodeInfoValue(Context* context, const QString& key)
{
    return context ? static_cast<quint64>(context->lightningNodeInfo().value(key).toInteger(0)) : 0;
}

quint64 AccountPolicyBalance(Account* account)
{
    if (!account || !account->network()) return 0;
    const auto policy_asset = account->network()->policyAsset();
    return static_cast<quint64>(account->json().value(QStringLiteral("satoshi")).toObject().value(policy_asset).toInteger(0));
}

QJsonObject PaymentStatusObject(const LightningSendResponse& result)
{
    QString status;
    switch (result.status) {
    case LightningPayStatus::Complete:
        status = QStringLiteral("complete");
        break;
    case LightningPayStatus::Pending:
        status = QStringLiteral("pending");
        break;
    case LightningPayStatus::Failed:
        status = QStringLiteral("failed");
        break;
    case LightningPayStatus::Unknown:
        status = QStringLiteral("unknown");
        break;
    }

    return {
        { QStringLiteral("status"), status },
        { QStringLiteral("payment_hash"), result.payment_hash },
        { QStringLiteral("preimage"), result.preimage },
        { QStringLiteral("amount"), static_cast<qint64>(LightningMsatToDisplaySatoshi(result.amount_msat)) },
        { QStringLiteral("amount_sent"), static_cast<qint64>(LightningMsatToDisplaySatoshi(result.amount_sent_msat)) },
        { QStringLiteral("parts"), static_cast<qint64>(result.parts) },
    };
}

} // namespace

PaymentSource::PaymentSource(Type type, Account* account, Asset* asset, qint64 balance, qint64 max_payable, QObject* parent)
    : QObject(parent)
    , m_type(type)
    , m_account(account)
    , m_asset(asset)
    , m_balance(balance)
    , m_max_payable(max_payable)
{
}

LightningSendController::LightningSendController(QObject* parent)
    : Controller(parent)
{
    connect(this, &Controller::contextChanged, this, &LightningSendController::refresh);
}

LightningSendController::~LightningSendController()
{
    clearSources();
}

void LightningSendController::setInvoice(const QString& invoice)
{
    if (m_invoice == invoice) return;
    m_invoice = invoice;
    m_payment = {};
    setError({});
    update();
}

void LightningSendController::setInput(const QString& input)
{
    if (m_input == input) return;
    m_input = input;
    emit updated();
}

void LightningSendController::setLightningOnly(const bool lightning_only)
{
    if (m_lightning_only == lightning_only) return;
    m_lightning_only = lightning_only;
    update();
}

void LightningSendController::setEnteredSatoshi(const QString& entered_satoshi)
{
    if (m_entered_satoshi == entered_satoshi) return;
    m_entered_satoshi = entered_satoshi;
    m_payment = {};
    setError({});
    if (amountless()) {
        emit updated();
        return;
    }
    update();
}

bool LightningSendController::amountless() const
{
    return m_parsed_invoice && !m_parsed_invoice->amount_msat.has_value();
}

QVariant LightningSendController::invoiceAmount() const
{
    const auto amount = m_parsed_invoice ? LightningMsatToDisplaySatoshi(m_parsed_invoice->amount_msat) : std::nullopt;
    return amount ? QVariant::fromValue(*amount) : QVariant();
}

QString LightningSendController::error() const
{
    if (!m_error.isEmpty()) return m_error;
    if (m_invoice.isEmpty()) return {};

    if (!m_parsed_invoice) {
        return QStringLiteral("Invalid Lightning invoice");
    }

    const auto expiry_at = m_parsed_invoice->timestamp + m_parsed_invoice->expiry;
    if (expiry_at <= QDateTime::currentSecsSinceEpoch()) {
        return QStringLiteral("Invoice expired");
    }

    if (amountless() && !m_selected_source) {
        return QStringLiteral("Amountless invoices require Lightning account");
    }

    if (amountless() && m_selected_source && m_selected_source->type() != PaymentSource::Type::Lightning) {
        return QStringLiteral("Amountless invoices require Lightning account");
    }

    const auto payment_amount = amount();
    if (!payment_amount) {
        return amountless() ? QString() : QStringLiteral("Invoice amount is missing");
    }

    if (m_selected_source && *payment_amount > static_cast<quint64>(m_selected_source->maxPayable())) {
        return QStringLiteral("id_insufficient_funds");
    }

    if (m_sources.isEmpty()) {
        return QStringLiteral("id_insufficient_funds");
    }

    return {};
}

bool LightningSendController::canPay() const
{
    return !m_busy
        && m_selected_source
        && m_selected_source->type() == PaymentSource::Type::Lightning
        && amount().has_value()
        && error().isEmpty();
}

QQmlListProperty<PaymentSource> LightningSendController::sources()
{
    return { this, &m_sources };
}

void LightningSendController::setSelectedSource(PaymentSource* selected_source)
{
    if (m_selected_source == selected_source) return;
    m_selected_source = selected_source;
    emit updated();
}

void LightningSendController::pay()
{
    if (!canPay()) return;
    if (!context()) return;

    const auto lightning_session = context()->lightningSession();
    if (!lightning_session) {
        emit failed(QStringLiteral("Lightning session is not available"));
        return;
    }

    const auto payment_amount_msat = m_parsed_invoice && m_parsed_invoice->amount_msat
        ? m_parsed_invoice->amount_msat
        : LightningSatoshiToMsat(amount());
    setError({});
    setBusy(true);

    auto future = lightning_session->sendPayment(m_invoice, payment_amount_msat);
    future.then(this, [=, this](LightningValueResult<LightningSendResponse> result) {
        if (!result) {
            qWarning() << Q_FUNC_INFO << "Failed to send payment: '" << result.error << "'";
            setBusy(false);
            emit failed(result.error);
            return;
        }
        const auto response = *result.value;
        if (response.status != LightningPayStatus::Complete) {
            const auto error = response.status == LightningPayStatus::Pending
                ? QStringLiteral("Payment is pending")
                : QStringLiteral("Payment failed");
            setBusy(false);
            emit failed(error);
            return;
        }

        m_payment = PaymentStatusObject(response);
        setBusy(false);
        emit updated();
        emit paid();
    });

    waitForFuture(future);
}

void LightningSendController::refresh()
{
    update();
}

std::optional<quint64> LightningSendController::amount() const
{
    if (m_parsed_invoice && m_parsed_invoice->amount_msat) return LightningMsatToDisplaySatoshi(m_parsed_invoice->amount_msat);

    bool ok = false;
    const auto value = m_entered_satoshi.toULongLong(&ok);
    if (ok && value > 0) return value;
    return std::nullopt;
}

void LightningSendController::clearSources()
{
    const auto sources = m_sources;
    m_sources.clear();
    m_selected_source = nullptr;
    for (auto source : sources) {
        source->deleteLater();
    }
}

void LightningSendController::setBusy(const bool busy)
{
    if (m_busy == busy) return;
    m_busy = busy;
    emit updated();
}

void LightningSendController::setError(const QString& error)
{
    if (m_error == error) return;
    m_error = error;
    emit updated();
}

void LightningSendController::update()
{
    m_parsed_invoice = std::nullopt;
    clearSources();

    if (m_invoice.trimmed().isEmpty() || !context()) {
        emit updated();
        return;
    }

    const auto lightning_session = context()->lightningSession();
    const auto parsed = lightning_session ? lightning_session->parseInvoice(m_invoice) : LightningValueResult<LightningParsedInvoice>{};
    if (!parsed) {
        setError(parsed.error);
        emit updated();
        return;
    }

    m_parsed_invoice = *parsed.value;
    buildSources();
    emit updated();
}

void LightningSendController::buildSources()
{
    if (!context() || !m_parsed_invoice) return;

    const auto payment_amount = amount();
    auto lightning_asset = context()->getOrCreateAsset(QStringLiteral("lnbtc"));

    // Include Liquid accounts to perform Liquid -> Lightning swaps
    if (!m_lightning_only && payment_amount && !amountless()) {
        const auto accounts = context()->getAccounts();
        for (auto account : accounts) {
            if (!account || account->isHidden() || !account->network()->isLiquid()) continue;

            const auto balance = AccountPolicyBalance(account);
            if (*payment_amount > balance) continue;

            auto asset = context()->getOrCreateAsset(account->network()->policyAsset());
            m_sources.append(new PaymentSource(PaymentSource::Type::GdkAccount, account, asset, static_cast<qint64>(balance), static_cast<qint64>(balance), this));
        }
    }

    if (context()->lightningEnabled()) {
        const auto max_payable = NodeInfoValue(context(), QStringLiteral("max_payable"));
        const auto balance = NodeInfoValue(context(), QStringLiteral("channel_balance"));
        if (!payment_amount || amountless() || *payment_amount <= max_payable) {
            m_sources.append(new PaymentSource(PaymentSource::Type::Lightning, nullptr, lightning_asset, static_cast<qint64>(balance), static_cast<qint64>(max_payable), this));
        }
    }

    // Select the Lightning source if lightningOnly
    if (m_lightning_only) {
        for (auto source : m_sources) {
            if (source->type() == PaymentSource::Type::Lightning) {
                m_selected_source = source;
                return;
            }
        }
        return;
    }

    // Select the first source automatically if there is only one source available
    if (m_sources.size() == 1) {
        m_selected_source = m_sources.first();
    }
}
