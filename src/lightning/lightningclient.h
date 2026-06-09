#ifndef BLOCKSTREAM_LIGHTNING_CLIENT_H
#define BLOCKSTREAM_LIGHTNING_CLIENT_H

#include <QByteArray>
#include <QString>

#include <cstdint>
#include <memory>
#include <optional>
#include <vector>

namespace glsdk {
struct Node;
struct NodeEventListener;
}

// Public status types.
enum class LightningPayStatus {
    Complete,
    Pending,
    Failed,
    Unknown,
};

enum class LightningPaymentType {
    Sent,
    Received,
    Unknown,
};

// Shared result wrappers.
struct LightningOperationResult {
    bool success{false};
    QString error;

    explicit operator bool() const { return success; }
};

template <typename T>
struct LightningValueResult {
    std::optional<T> value;
    QString error;

    bool success() const { return value.has_value(); }
    explicit operator bool() const { return success(); }
};

// Public data wrappers.
struct LightningParsedInvoice {
    QString bolt11;
    std::optional<QString> payee_pubkey;
    QString payment_hash;
    std::optional<QString> description;
    std::optional<quint64> amount;
    quint64 expiry{0};
    quint64 timestamp{0};
};

struct LightningPayment {
    QString id;
    LightningPaymentType payment_type{LightningPaymentType::Unknown};
    quint64 payment_time{0};
    quint64 amount{0};
    quint64 fee{0};
    std::optional<QString> description;
    std::optional<QString> bolt11;
    std::optional<QString> preimage;
    std::optional<QString> destination;
};

struct LightningSendResponse {
    LightningPayStatus status{LightningPayStatus::Unknown};
    QString preimage;
    QString payment_hash;
    std::optional<QString> destination_pubkey;
    quint64 amount{0};
    quint64 amount_sent{0};
    quint32 parts{0};
};

struct LightningReceiveResponse {
    QString bolt11;
    quint64 opening_fee{0};
};

struct LightningOnchainReceiveResponse {
    QString bech32;
    QString p2tr;
};

struct LightningOnchainSendResponse {
    QByteArray tx;
    QString txid;
    QString psbt;
};

struct LightningNodeInfo {
    QString id;
    quint32 block_height{0};
    quint64 channel_balance{0};
    quint64 onchain_balance{0};
    quint64 inbound_liquidity{0};
    quint64 max_payable{0};
    quint64 max_receivable{0};
};

// Stateless Lightning client facade.
class LightningClient final
{
public:
    LightningClient();
    ~LightningClient();

    LightningValueResult<std::shared_ptr<glsdk::Node>> connectNode(const QString& mnemonic, const std::shared_ptr<glsdk::NodeEventListener>& listener);
    void disconnectNode(const std::shared_ptr<glsdk::Node>& node);

    LightningValueResult<LightningNodeInfo> refreshNodeInfo(const std::shared_ptr<glsdk::Node>& node);
    LightningValueResult<std::vector<LightningPayment>> listPayments(const std::shared_ptr<glsdk::Node>& node) const;
    LightningValueResult<LightningParsedInvoice> parseInvoice(const QString& input) const;
    LightningValueResult<LightningReceiveResponse> createInvoice(const std::shared_ptr<glsdk::Node>& node, quint64 satoshi, const QString& description);
    LightningValueResult<LightningSendResponse> sendPayment(const std::shared_ptr<glsdk::Node>& node, const QString& bolt11, const std::optional<quint64>& satoshi, const std::optional<LightningNodeInfo>& node_info);

    LightningValueResult<LightningOnchainReceiveResponse> onchainReceive(const std::shared_ptr<glsdk::Node>& node);
    LightningValueResult<LightningOnchainSendResponse> redeemAllOnchainFunds(const std::shared_ptr<glsdk::Node>& node, const QString& destination);

private:
    LightningOperationResult checkInvoice(const LightningParsedInvoice& invoice, const std::optional<quint64>& amount_satoshi, const std::optional<LightningNodeInfo>& node_info) const;
};

#endif // BLOCKSTREAM_LIGHTNING_CLIENT_H
