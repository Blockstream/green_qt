#include "config.h"
#include "glsdk.hpp"
#include "lightningclient.h"
#include "util.h"

#include <QByteArray>
#include <QDateTime>
#include <QDebug>
#include <QFile>
#include <QLoggingCategory>

#include <exception>
#include <memory>
#include <mutex>
#include <string>
#include <variant>
#include <vector>

Q_LOGGING_CATEGORY(lcGlsdk, "glsdk")

namespace {

// GL-SDK setup helpers.
class GlSdkLogListener final : public glsdk::LogListener
{
public:
    void on_log(const glsdk::LogEntry& entry) override
    {
        const auto target = QString::fromStdString(entry.target);
        const auto message = QStringLiteral("[%1] %2")
            .arg(target, QString::fromStdString(entry.message));

        switch (entry.level) {
        case glsdk::LogLevel::kError: qCCritical(lcGlsdk) << message; break;
        case glsdk::LogLevel::kWarn: qCWarning(lcGlsdk) << message; break;
        case glsdk::LogLevel::kInfo: qCInfo(lcGlsdk) << message; break;
        case glsdk::LogLevel::kDebug:
        case glsdk::LogLevel::kTrace: qCDebug(lcGlsdk) << message; break;
        }
    }
};

glsdk::LogLevel GlsdkMinLogLevel()
{
    const auto value = qEnvironmentVariable("GREEN_GLSDK_LOG_LEVEL", "info").toLower();
    if (value == QByteArrayLiteral("error")) return glsdk::LogLevel::kError;
    if (value == QByteArrayLiteral("warn") || value == QByteArrayLiteral("warning")) return glsdk::LogLevel::kWarn;
    if (value == QByteArrayLiteral("debug")) return glsdk::LogLevel::kDebug;
    if (value == QByteArrayLiteral("trace")) return glsdk::LogLevel::kTrace;
    return glsdk::LogLevel::kInfo;
}

void InitializeGlSdkLogger()
{
    static std::once_flag once;
    std::call_once(once, [] {
        auto listener = std::make_shared<GlSdkLogListener>();
        glsdk::set_logger(GlsdkMinLogLevel(), listener);
    });
}

std::optional<std::vector<uint8_t>> LoadBase64Path(const QString& path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return std::nullopt;
    }

    const auto content = file.readAll().trimmed();
    if (content.isEmpty()) {
        return std::nullopt;
    }

    const auto decoded = QByteArray::fromBase64(content, QByteArray::Base64Encoding);
    if (decoded.isEmpty()) {
        return std::nullopt;
    }

    return std::vector<uint8_t>(decoded.begin(), decoded.end());
}

LightningValueResult<std::shared_ptr<glsdk::Config>> BuildGlsdkConfig()
{
    const auto device_cert = LoadBase64Path(QStringLiteral(":/greenlight/greenlight_device_cert.txt"));
    const auto device_key = LoadBase64Path(QStringLiteral(":/greenlight/greenlight_device_key.txt"));
    if (!device_cert || !device_key) {
        const auto error = QStringLiteral("Missing Lightning credentials at assets/greenlight/greenlight_device_cert.txt and assets/greenlight/greenlight_device_key.txt");
        qWarning() << Q_FUNC_INFO << error;
        return { std::nullopt, error };
    }

    auto config = glsdk::Config::init();
    auto developer_cert = glsdk::DeveloperCert::init(*device_cert, *device_key);

    return { config->with_developer_cert(developer_cert), {} };
}

std::optional<uint64_t> SatoshiToMsat(const std::optional<quint64>& satoshi)
{
    if (!satoshi) return std::nullopt;
    return (*satoshi) * 1000ULL;
}

quint64 MsatToSatoshi(const uint64_t msat)
{
    return msat / 1000ULL;
}

std::optional<quint64> MsatToSatoshi(const std::optional<uint64_t>& msat)
{
    if (!msat) return std::nullopt;
    return MsatToSatoshi(*msat);
}

// GL-SDK to client type conversions.
std::optional<QString> ToOptionalQString(const std::optional<std::string>& value)
{
    if (!value) return std::nullopt;
    return QString::fromStdString(*value);
}

LightningPayStatus ToLightningPayStatus(const glsdk::PayStatus status)
{
    switch (status) {
    case glsdk::PayStatus::kComplete: return LightningPayStatus::Complete;
    case glsdk::PayStatus::kPending: return LightningPayStatus::Pending;
    case glsdk::PayStatus::kFailed: return LightningPayStatus::Failed;
    }
    return LightningPayStatus::Unknown;
}

LightningPaymentType ToLightningPaymentType(const glsdk::PaymentType type)
{
    switch (type) {
    case glsdk::PaymentType::kSent: return LightningPaymentType::Sent;
    case glsdk::PaymentType::kReceived: return LightningPaymentType::Received;
    }
    return LightningPaymentType::Unknown;
}

QString CurrentGlsdkExceptionMessage()
{
    try {
        throw;
    } catch (const std::exception& error) {
        return QString::fromUtf8(error.what());
    } catch (...) {
        return QStringLiteral("Unexpected GL-SDK failure");
    }
}

LightningNodeInfo ToLightningNodeInfo(const glsdk::NodeState& node_state)
{
    LightningNodeInfo info;
    info.id = QString::fromStdString(node_state.id);
    info.block_height = node_state.block_height;
    info.channel_balance = node_state.channels_balance_msat / 1000ULL;
    info.onchain_balance = node_state.onchain_balance_msat / 1000ULL;
    info.inbound_liquidity = node_state.total_inbound_liquidity_msat / 1000ULL;
    info.max_payable = node_state.max_payable_msat / 1000ULL;
    info.max_receivable = node_state.max_receivable_single_payment_msat / 1000ULL;
    return info;
}

}

LightningClient::LightningClient()
{
    InitializeGlSdkLogger();
}

LightningClient::~LightningClient()
{
    qDebug() << Q_FUNC_INFO << "Lightning client destroyed";
}

LightningValueResult<std::shared_ptr<glsdk::Node>> LightningClient::connectNode(const QString& mnemonic, const std::shared_ptr<glsdk::NodeEventListener>& listener)
{
    if (mnemonic.trimmed().isEmpty()) {
        const auto error = QStringLiteral("Unable to connect lightning node without mnemonic");
        qWarning() << Q_FUNC_INFO << error;
        return { std::nullopt, error };
    }

    try {
        auto config = BuildGlsdkConfig();
        if (!config) return { std::nullopt, config.error };

        auto builder = glsdk::NodeBuilder::init(*config.value);
        if (listener) {
            builder = builder->with_event_listener(listener);
        }

        return { builder->register_or_recover(mnemonic.toStdString(), std::nullopt), {} };
    } catch (...) {
        return { std::nullopt, CurrentGlsdkExceptionMessage() };
    }
}

void LightningClient::disconnectNode(const std::shared_ptr<glsdk::Node>& node)
{
    if (!node) return;

    try {
        node->stop();
        node->disconnect();
    } catch (...) {
        // Ignore disconnect failures to guarantee local teardown.
    }
}

LightningValueResult<LightningNodeInfo> LightningClient::refreshNodeInfo(const std::shared_ptr<glsdk::Node>& node)
{
    if (!node) return { std::nullopt, QStringLiteral("GL-SDK node is not connected") };

    try {
        return { ToLightningNodeInfo(node->node_state()), {} };
    } catch (...) {
        return { std::nullopt, CurrentGlsdkExceptionMessage() };
    }
}

LightningValueResult<LightningParsedInvoice> LightningClient::parseInvoice(const QString& input) const
{
    try {
        const auto resolved = glsdk::resolve_input(input.toStdString());
        const auto& variant = resolved.get_variant();
        if (std::holds_alternative<glsdk::ResolvedInput::kBolt11>(variant)) {
            const auto& invoice = std::get<glsdk::ResolvedInput::kBolt11>(variant).invoice;
            return { LightningParsedInvoice{
                QString::fromStdString(invoice.bolt11),
                ToOptionalQString(invoice.payee_pubkey),
                QString::fromStdString(invoice.payment_hash),
                ToOptionalQString(invoice.description),
                MsatToSatoshi(invoice.amount_msat),
                invoice.expiry,
                invoice.timestamp,
            }, {} };
        }

        return { std::nullopt, QStringLiteral("Input is not a valid lightning invoice") };
    } catch (...) {
        return { std::nullopt, CurrentGlsdkExceptionMessage() };
    }
}

LightningValueResult<std::vector<LightningPayment>> LightningClient::listPayments(const std::shared_ptr<glsdk::Node>& node) const
{
    if (!node) return { std::nullopt, QStringLiteral("GL-SDK node is not connected") };

    try {
        glsdk::ListPaymentsRequest request;
        request.include_failures = false;
        const auto payments = node->list_payments(request);
        std::vector<LightningPayment> result;
        result.reserve(payments.size());
        for (const auto& payment : payments) {
            if (payment.status != glsdk::PaymentStatus::kComplete) continue;

            result.emplace_back(LightningPayment{
                QString::fromStdString(payment.id),
                ToLightningPaymentType(payment.payment_type),
                payment.payment_time,
                MsatToSatoshi(payment.amount_msat),
                MsatToSatoshi(payment.fee_msat),
                ToOptionalQString(payment.description),
                ToOptionalQString(payment.bolt11),
                ToOptionalQString(payment.preimage),
                ToOptionalQString(payment.destination),
            });
        }
        return { result, {} };
    } catch (...) {
        return { std::nullopt, CurrentGlsdkExceptionMessage() };
    }
}

LightningOperationResult LightningClient::checkInvoice(const LightningParsedInvoice& invoice, const std::optional<quint64>& amount_satoshi, const std::optional<LightningNodeInfo>& node_info) const
{
    const auto expiry_at = invoice.timestamp + invoice.expiry;
    if (expiry_at <= QDateTime::currentSecsSinceEpoch()) {
        return { false, QStringLiteral("Invoice has expired") };
    }

    const auto amount = invoice.amount.value_or(amount_satoshi.value_or(0));
    if (amount == 0) {
        return { false, QStringLiteral("Invoice amount is missing") };
    }

    if (node_info && amount > node_info->max_payable) {
        return { false, QStringLiteral("Invoice amount exceeds max payable amount") };
    }
    return { true, {} };
}

LightningValueResult<LightningSendResponse> LightningClient::sendPayment(const std::shared_ptr<glsdk::Node>& node, const QString& bolt11, const std::optional<quint64>& satoshi, const std::optional<LightningNodeInfo>& node_info)
{
    if (!node) return { std::nullopt, QStringLiteral("GL-SDK node is not connected") };

    const auto invoice = parseInvoice(bolt11);
    if (!invoice) return { std::nullopt, invoice.error };

    const auto invoice_check = checkInvoice(*invoice.value, satoshi, node_info);
    if (!invoice_check) return { std::nullopt, invoice_check.error };

    try {
        const auto response = node->send(bolt11.toStdString(), SatoshiToMsat(satoshi));
        return { LightningSendResponse{
            ToLightningPayStatus(response.status),
            QString::fromStdString(response.preimage),
            QString::fromStdString(response.payment_hash),
            ToOptionalQString(response.destination_pubkey),
            MsatToSatoshi(response.amount_msat),
            MsatToSatoshi(response.amount_sent_msat),
            response.parts,
        }, {} };
    } catch (...) {
        return { std::nullopt, CurrentGlsdkExceptionMessage() };
    }
}

LightningValueResult<LightningReceiveResponse> LightningClient::createInvoice(const std::shared_ptr<glsdk::Node>& node, const quint64 satoshi, const QString& description)
{
    if (!node) return { std::nullopt, QStringLiteral("GL-SDK node is not connected") };

    try {
        const auto label = QStringLiteral("inv-%1").arg(QDateTime::currentMSecsSinceEpoch());
        const auto response = node->receive(label.toStdString(), description.toStdString(), satoshi * 1000ULL);
        return { LightningReceiveResponse{
            QString::fromStdString(response.bolt11),
            MsatToSatoshi(response.opening_fee_msat),
        }, {} };
    } catch (...) {
        return { std::nullopt, CurrentGlsdkExceptionMessage() };
    }
}

LightningValueResult<LightningOnchainReceiveResponse> LightningClient::onchainReceive(const std::shared_ptr<glsdk::Node>& node)
{
    if (!node) return { std::nullopt, QStringLiteral("GL-SDK node is not connected") };

    try {
        const auto response = node->onchain_receive();
        return { LightningOnchainReceiveResponse{
            QString::fromStdString(response.bech32),
            QString::fromStdString(response.p2tr),
        }, {} };
    } catch (...) {
        return { std::nullopt, CurrentGlsdkExceptionMessage() };
    }
}

LightningValueResult<LightningOnchainSendResponse> LightningClient::redeemAllOnchainFunds(const std::shared_ptr<glsdk::Node>& node, const QString& destination)
{
    if (!node) return { std::nullopt, QStringLiteral("GL-SDK node is not connected") };

    try {
        const auto response = node->onchain_send(destination.toStdString(), "all", std::nullopt, std::nullopt);
        return { LightningOnchainSendResponse{
            QByteArray(reinterpret_cast<const char*>(response.tx.data()), static_cast<qsizetype>(response.tx.size())),
            QString::fromStdString(response.txid),
            QString::fromStdString(response.psbt),
        }, {} };
    } catch (...) {
        return { std::nullopt, CurrentGlsdkExceptionMessage() };
    }
}
