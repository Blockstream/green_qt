#pragma once

#include <algorithm>
#include <bit>
#include <chrono>
#include <cstdint>
#include <exception>
#include <functional>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <stdexcept>
#include <streambuf>
#include <type_traits>
#include <variant>
#include <vector>

#include "glsdk_scaffolding.hpp"

namespace glsdk {
struct Config;
struct Credentials;
struct DeveloperCert;
struct Handle;
struct Node;
struct NodeBuilder;
struct NodeEventStream;
struct Scheduler;
struct Signer;
struct FundChannel;
struct FundOutput;
struct GetInfoResponse;
struct Invoice;
struct InvoicePaidEvent;
struct ListFundsResponse;
struct ListInvoicesResponse;
struct ListPaymentsRequest;
struct ListPaysResponse;
struct ListPeerChannelsResponse;
struct ListPeersResponse;
struct LnUrlErrorData;
struct LnUrlPayErrorData;
struct LnUrlPayRequest;
struct LnUrlPayRequestData;
struct LnUrlPaySuccessData;
struct LnUrlWithdrawRequest;
struct LnUrlWithdrawRequestData;
struct LnUrlWithdrawSuccessData;
struct LogEntry;
struct NodeState;
struct OnchainFeeRates;
struct OnchainReceiveResponse;
struct OnchainSendResponse;
struct Outpoint;
struct ParsedInvoice;
struct Pay;
struct Payment;
struct Peer;
struct PeerChannel;
struct PreparedOnchainSend;
struct ReceiveResponse;
struct SendResponse;
enum class ChannelSide;
enum class ChannelState;
struct Error;
enum class InvoiceStatus;
enum class ListIndex;
struct LnUrlPayResult;
struct LnUrlWithdrawResult;
enum class LogLevel;
enum class Network;
struct NodeEvent;
struct OnchainBalanceState;
enum class OutputStatus;
struct ParsedInput;
enum class PayStatus;
enum class PaymentStatus;
enum class PaymentType;
enum class PaymentTypeFilter;
struct ResolvedInput;
struct SuccessActionProcessed;
struct LogListener;
struct NodeEventListener;


/**
 * Successful LNURL-withdraw result data.
 */
struct LnUrlWithdrawSuccessData {
    /**
     * The BOLT11 invoice that was submitted for withdrawal.
     */
    std::string invoice;
};


/**
 * Error returned by an LNURL service endpoint.
 */
struct LnUrlErrorData {
    std::string reason;
};


struct Peer {
    /**
     * Peer node public key as lowercase hex (66 chars).
     */
    std::string id;
    bool connected;
    std::optional<uint32_t> num_channels;
    std::vector<std::string> netaddr;
    std::optional<std::string> remote_addr;
    std::optional<std::vector<uint8_t>> features;
};


/**
 * Log level for filtering messages.
 */
enum class LogLevel: int32_t {
    kError = 1,
    kWarn = 2,
    kInfo = 3,
    kDebug = 4,
    kTrace = 5
};


/**
 * Details of a paid invoice.
 */
struct InvoicePaidEvent {
    /**
     * Payment hash of the paid invoice as lowercase hex (64 chars).
     */
    std::string payment_hash;
    /**
     * The bolt11 invoice string.
     */
    std::string bolt11;
    /**
     * Preimage that proves payment as lowercase hex (64 chars).
     */
    std::string preimage;
    /**
     * The label assigned to the invoice.
     */
    std::string label;
    /**
     * Amount received in millisatoshis.
     */
    uint64_t amount_msat;
};


enum class OutputStatus: int32_t {
    kUnconfirmed = 1,
    kConfirmed = 2,
    kSpent = 3,
    kImmature = 4
};


/**
 * Data from an LNURL-pay endpoint (LUD-06).
 *
 * Contains the service's accepted amount range and metadata.
 * Returned inside `InputType::LnUrlPay` after `parse_input` resolves
 * an LNURL or Lightning Address.
 */
struct LnUrlPayRequestData {
    /**
     * The callback URL to request an invoice from.
     */
    std::string callback;
    /**
     * Minimum amount the service accepts, in millisatoshis.
     */
    uint64_t min_sendable;
    /**
     * Maximum amount the service accepts, in millisatoshis.
     */
    uint64_t max_sendable;
    /**
     * Raw metadata JSON string (array of `["mime", "content"]` pairs).
     */
    std::string metadata;
    /**
     * Maximum comment length the service accepts. 0 means no comments.
     */
    uint64_t comment_allowed;
    /**
     * Human-readable description extracted from metadata.
     */
    std::string description;
    /**
     * The original LNURL or lightning address that was resolved.
     */
    std::string lnurl;
};


/**
 * Which side of a channel performed a given action (e.g. initiated close).
 */
enum class ChannelSide: int32_t {
    kLocal = 1,
    kRemote = 2
};

namespace uniffi {
struct FfiConverterSuccessActionProcessed;
} // namespace uniffi

/**
 * A processed success action from an LNURL-pay callback.
 *
 * For Message and Url this is passed through as-is. For Aes the
 * ciphertext has been decrypted using the payment preimage.
 */
struct SuccessActionProcessed {
    friend uniffi::FfiConverterSuccessActionProcessed;
    /**
     * Display a message to the user.
     */
    struct kMessage {
        std::string message;
    };
    /**
     * Display a URL to the user.
     */
    struct kUrl {
        std::string description;
        std::string url;
    };
    /**
     * Decrypted AES payload (LUD-10).
     */
    struct kAes {
        std::string description;
        std::string plaintext;
    };
    SuccessActionProcessed(kMessage variant): variant(variant) {}
    SuccessActionProcessed(kUrl variant): variant(variant) {}
    SuccessActionProcessed(kAes variant): variant(variant) {}

    SuccessActionProcessed(const SuccessActionProcessed &other): variant(other.variant) {}
    SuccessActionProcessed(SuccessActionProcessed &&other): variant(std::move(other.variant)) {}

    SuccessActionProcessed &operator=(const SuccessActionProcessed &other) {
        variant = other.variant;
        return *this;
    }

    SuccessActionProcessed &operator=(SuccessActionProcessed &&other) {
        variant = std::move(other.variant);
        return *this;
    }

    /**
     * Returns the variant of this enum
     */
    const std::variant<kMessage, kUrl, kAes> &get_variant() const {
        return variant;
    }

private:
    std::variant<kMessage, kUrl, kAes> variant;

    SuccessActionProcessed();
};


/**
 * Data from an LNURL-withdraw endpoint (LUD-03).
 *
 * Contains the service's accepted withdrawal range and session key.
 * Returned inside `InputType::LnUrlWithdraw` after `parse_input`
 * resolves an LNURL.
 */
struct LnUrlWithdrawRequestData {
    /**
     * The callback URL to submit the invoice to.
     */
    std::string callback;
    /**
     * Ephemeral secret linking this wallet session to the service.
     */
    std::string k1;
    /**
     * Default description for the invoice.
     */
    std::string default_description;
    /**
     * Minimum withdrawable amount in millisatoshis.
     */
    uint64_t min_withdrawable;
    /**
     * Maximum withdrawable amount in millisatoshis.
     */
    uint64_t max_withdrawable;
    /**
     * The original LNURL that was resolved.
     */
    std::string lnurl;
};


enum class PaymentType: int32_t {
    kSent = 1,
    kReceived = 2
};


enum class PaymentStatus: int32_t {
    kPending = 1,
    kComplete = 2,
    kFailed = 3
};


/**
 * Details of a failed LNURL-pay attempt on the pay phase.
 */
struct LnUrlPayErrorData {
    /**
     * Hex-encoded payment hash of the invoice the service returned.
     */
    std::string payment_hash;
    /**
     * Human-readable reason the pay attempt failed.
     */
    std::string reason;
};


/**
 * A specific on-chain output, identified by its outpoint.
 */
struct Outpoint {
    /**
     * Transaction id as lowercase hex (64 chars).
     */
    std::string txid;
    /**
     * Output index within that transaction.
     */
    uint32_t vout;
};


enum class ChannelState: int32_t {
    kOpeningd = 1,
    kChanneldAwaitingLockin = 2,
    kChanneldNormal = 3,
    kChanneldShuttingDown = 4,
    kClosingdSigexchange = 5,
    kClosingdComplete = 6,
    kAwaitingUnilateral = 7,
    kFundingSpendSeen = 8,
    kOnchain = 9,
    kDualopendOpenInit = 10,
    kDualopendAwaitingLockin = 11,
    kDualopendOpenCommitted = 12,
    kDualopendOpenCommitReady = 13,
    /**
     * A state reported by the node that this SDK doesn't recognize.
     * Returned when CLN introduces a new channel state after this SDK
     * was built. Treated as neither open nor closing by balance math.
     */
    kUnknown = 14
};


enum class PayStatus: int32_t {
    kComplete = 1,
    kPending = 2,
    kFailed = 3
};


enum class PaymentTypeFilter: int32_t {
    kSent = 1,
    kReceived = 2
};


/**
 * Parsed BOLT11 invoice with extracted fields.
 */
struct ParsedInvoice {
    /**
     * The original invoice string.
     */
    std::string bolt11;
    /**
     * Recipient public key as lowercase hex (66 chars), recovered from the invoice signature.
     */
    std::optional<std::string> payee_pubkey;
    /**
     * Payment hash as lowercase hex (64 chars) identifying this payment.
     */
    std::string payment_hash;
    /**
     * Invoice description. None if the invoice uses a description hash.
     */
    std::optional<std::string> description;
    /**
     * Requested amount in millisatoshis. None for "any amount" invoices.
     */
    std::optional<uint64_t> amount_msat;
    /**
     * Seconds from creation until the invoice expires.
     */
    uint64_t expiry;
    /**
     * Unix timestamp (seconds) when the invoice was created.
     */
    uint64_t timestamp;
};


enum class InvoiceStatus: int32_t {
    kUnpaid = 1,
    kPaid = 2,
    kExpired = 3
};


struct Pay {
    /**
     * Payment hash as lowercase hex (64 chars).
     */
    std::string payment_hash;
    PayStatus status;
    /**
     * Recipient node pubkey as lowercase hex (66 chars), if known.
     */
    std::optional<std::string> destination_pubkey;
    std::optional<uint64_t> amount_msat;
    std::optional<uint64_t> amount_sent_msat;
    std::optional<std::string> label;
    std::optional<std::string> bolt11;
    std::optional<std::string> description;
    std::optional<std::string> bolt12;
    /**
     * Payment preimage as lowercase hex (64 chars), if the payment completed.
     */
    std::optional<std::string> preimage;
    uint64_t created_at;
    std::optional<uint64_t> completed_at;
    std::optional<uint64_t> number_of_parts;
};


/**
 * Successful LNURL-pay result data.
 */
struct LnUrlPaySuccessData {
    /**
     * The payment preimage (proof of payment), hex-encoded.
     */
    std::string payment_preimage;
    /**
     * Optional success action from the service (LUD-09).
     */
    std::optional<SuccessActionProcessed> success_action;
};


struct Invoice {
    std::string label;
    std::string description;
    /**
     * Payment hash as lowercase hex (64 chars).
     */
    std::string payment_hash;
    InvoiceStatus status;
    std::optional<uint64_t> amount_msat;
    std::optional<uint64_t> amount_received_msat;
    std::optional<std::string> bolt11;
    std::optional<std::string> bolt12;
    std::optional<uint64_t> paid_at;
    uint64_t expires_at;
    /**
     * Payment preimage as lowercase hex (64 chars), if the invoice has been paid.
     */
    std::optional<std::string> payment_preimage;
    /**
     * Recipient node pubkey as lowercase hex (66 chars), recovered from the bolt11.
     */
    std::optional<std::string> destination_pubkey;
};


/**
 * Preview of an on-chain send: the inputs CLN would select at the
 * given fee rate, the resulting fee, and the amount the recipient
 * would receive. Inputs are NOT reserved — the wallet is free to
 * spend them via other paths until `onchain_send` actually broadcasts.
 *
 * Pass `utxos` and `sat_per_vbyte` back to `onchain_send` to broadcast
 * with identical inputs and fee.
 *
 * Amounts are in satoshis: on-chain transactions cannot carry sub-sat
 * precision, so msat denomination would be misleading here.
 */
struct PreparedOnchainSend {
    /**
     * UTXOs that would be spent, in selection order.
     */
    std::vector<Outpoint> utxos;
    /**
     * Sum of all input UTXO values, in satoshis.
     */
    uint64_t total_input_sat;
    /**
     * Fee that would be paid, in satoshis.
     */
    uint64_t fee_sat;
    /**
     * Amount the recipient would receive, in satoshis.
     * For a sweep ("all") this equals `total_input_sat - fee_sat`.
     * For a fixed amount this equals the requested amount.
     */
    uint64_t recipient_sat;
    /**
     * Effective fee rate (sat per virtual byte) the node used to
     * compute this preview. Equal to the caller's `sat_per_vbyte` if
     * one was supplied; otherwise the rate the node picked at
     * "normal" priority. Pass this back to `onchain_send` to
     * reproduce the previewed fee.
     */
    uint32_t sat_per_vbyte;
};

namespace uniffi {
struct FfiConverterLnUrlWithdrawResult;
} // namespace uniffi

/**
 * Result of an LNURL-withdraw operation.
 */
struct LnUrlWithdrawResult {
    friend uniffi::FfiConverterLnUrlWithdrawResult;
    /**
     * The service accepted our invoice and will pay it.
     */
    struct kOk {
        LnUrlWithdrawSuccessData data;
    };
    /**
     * The LNURL service returned an error.
     */
    struct kErrorStatus {
        LnUrlErrorData data;
    };
    LnUrlWithdrawResult(kOk variant): variant(variant) {}
    LnUrlWithdrawResult(kErrorStatus variant): variant(variant) {}

    LnUrlWithdrawResult(const LnUrlWithdrawResult &other): variant(other.variant) {}
    LnUrlWithdrawResult(LnUrlWithdrawResult &&other): variant(std::move(other.variant)) {}

    LnUrlWithdrawResult &operator=(const LnUrlWithdrawResult &other) {
        variant = other.variant;
        return *this;
    }

    LnUrlWithdrawResult &operator=(LnUrlWithdrawResult &&other) {
        variant = std::move(other.variant);
        return *this;
    }

    /**
     * Returns the variant of this enum
     */
    const std::variant<kOk, kErrorStatus> &get_variant() const {
        return variant;
    }

private:
    std::variant<kOk, kErrorStatus> variant;

    LnUrlWithdrawResult();
};

namespace uniffi {
struct FfiConverterNodeEvent;
} // namespace uniffi

/**
 * A real-time event from the node.
 */
struct NodeEvent {
    friend uniffi::FfiConverterNodeEvent;
    /**
     * An invoice was paid.
     */
    struct kInvoicePaid {
        InvoicePaidEvent details;
    };
    NodeEvent(kInvoicePaid variant): variant(variant) {}

    NodeEvent(const NodeEvent &other): variant(other.variant) {}
    NodeEvent(NodeEvent &&other): variant(std::move(other.variant)) {}

    NodeEvent &operator=(const NodeEvent &other) {
        variant = other.variant;
        return *this;
    }

    NodeEvent &operator=(NodeEvent &&other) {
        variant = std::move(other.variant);
        return *this;
    }

    /**
     * Returns the variant of this enum
     */
    const std::variant<kInvoicePaid> &get_variant() const {
        return variant;
    }

private:
    std::variant<kInvoicePaid> variant;

    NodeEvent();
};


struct FundOutput {
    /**
     * Transaction id as lowercase hex (64 chars).
     */
    std::string txid;
    uint32_t output;
    uint64_t amount_msat;
    OutputStatus status;
    std::optional<std::string> address;
    std::optional<uint32_t> blockheight;
    /**
     * True when this UTXO is currently reserved by an in-flight PSBT
     * (e.g. a channel-open or fund-send that has not been broadcast or
     * abandoned). Reserved UTXOs are not spendable and must be excluded
     * from the wallet's spendable balance.
     */
    bool reserved;
};


struct PeerChannel {
    /**
     * Peer node public key as lowercase hex (66 chars).
     */
    std::string peer_id;
    bool peer_connected;
    ChannelState state;
    std::optional<std::string> short_channel_id;
    /**
     * Channel id as lowercase hex (64 chars).
     */
    std::optional<std::string> channel_id;
    /**
     * Funding transaction id as lowercase hex (64 chars).
     */
    std::optional<std::string> funding_txid;
    std::optional<uint32_t> funding_outnum;
    std::optional<uint64_t> to_us_msat;
    std::optional<uint64_t> total_msat;
    std::optional<uint64_t> spendable_msat;
    std::optional<uint64_t> receivable_msat;
    /**
     * Which side initiated the close, if the channel is closing or closed.
     */
    std::optional<ChannelSide> closer;
    /**
     * Human-readable status strings from CLN, ordered oldest to newest.
     * For a channel in `Onchain` state, the last entry indicates whether
     * our payout is still timelocked (`DELAYED_OUTPUT_TO_US`) or already
     * available in the on-chain balance.
     */
    std::vector<std::string> status;
};


struct Payment {
    std::string id;
    PaymentType payment_type;
    uint64_t payment_time;
    uint64_t amount_msat;
    uint64_t fee_msat;
    PaymentStatus status;
    std::optional<std::string> description;
    std::optional<std::string> bolt11;
    /**
     * Payment preimage as lowercase hex (64 chars), when known.
     */
    std::optional<std::string> preimage;
    /**
     * Pubkey of the counterparty in the payment, as lowercase hex
     * (66 chars).
     *
     * For `PaymentType::Sent`: the recipient node we paid (when CLN
     * reports it).
     *
     * For `PaymentType::Received`: always `None`. Lightning's privacy
     * model does not reveal the sender's pubkey to the recipient — the
     * HTLC arrives via one of our channel peers, but that peer is
     * usually just a router, not the original payer. The only pubkey
     * derivable from a paid invoice is the *payee* (i.e. our own
     * node), which is uninteresting to display per-row.
     */
    std::optional<std::string> destination;
};


struct ListPeersResponse {
    std::vector<Peer> peers;
};


struct ListPaymentsRequest {
    /**
     * Filter by payment type (Sent, Received). None or empty = all.
     */
    std::optional<std::vector<PaymentTypeFilter>> filters;
    /**
     * Include only payments after this epoch timestamp (seconds).
     */
    std::optional<uint64_t> from_timestamp;
    /**
     * Include only payments before this epoch timestamp (seconds).
     */
    std::optional<uint64_t> to_timestamp;
    /**
     * Include failed payments. Default: false.
     */
    std::optional<bool> include_failures;
    /**
     * Pagination offset.
     */
    std::optional<uint32_t> offset;
    /**
     * Pagination limit.
     */
    std::optional<uint32_t> limit;
};

namespace uniffi {
struct FfiConverterResolvedInput;
} // namespace uniffi

/**
 * The result of `resolve_input`: a fully-resolved input ready for
 * the caller's next action. LNURL bech32 strings and Lightning
 * Addresses are resolved over HTTP into typed pay or withdraw
 * request data; BOLT11 and node IDs pass through unchanged.
 */
struct ResolvedInput {
    friend uniffi::FfiConverterResolvedInput;
    /**
     * A BOLT11 Lightning invoice. No HTTP was performed.
     */
    struct kBolt11 {
        ParsedInvoice invoice;
    };
    /**
     * A Lightning node public key. No HTTP was performed.
     */
    struct kNodeId {
        std::string node_id;
    };
    /**
     * An LNURL-pay endpoint with the service's parameters fetched.
     */
    struct kLnUrlPay {
        LnUrlPayRequestData data;
    };
    /**
     * An LNURL-withdraw endpoint with the service's parameters fetched.
     */
    struct kLnUrlWithdraw {
        LnUrlWithdrawRequestData data;
    };
    ResolvedInput(kBolt11 variant): variant(variant) {}
    ResolvedInput(kNodeId variant): variant(variant) {}
    ResolvedInput(kLnUrlPay variant): variant(variant) {}
    ResolvedInput(kLnUrlWithdraw variant): variant(variant) {}

    ResolvedInput(const ResolvedInput &other): variant(other.variant) {}
    ResolvedInput(ResolvedInput &&other): variant(std::move(other.variant)) {}

    ResolvedInput &operator=(const ResolvedInput &other) {
        variant = other.variant;
        return *this;
    }

    ResolvedInput &operator=(ResolvedInput &&other) {
        variant = std::move(other.variant);
        return *this;
    }

    /**
     * Returns the variant of this enum
     */
    const std::variant<kBolt11, kNodeId, kLnUrlPay, kLnUrlWithdraw> &get_variant() const {
        return variant;
    }

private:
    std::variant<kBolt11, kNodeId, kLnUrlPay, kLnUrlWithdraw> variant;

    ResolvedInput();
};

namespace uniffi {
struct FfiConverterParsedInput;
} // namespace uniffi

/**
 * The result of `parse_input`: an offline classification of the
 * input. No HTTP, no I/O. LNURL bech32 strings are returned as their
 * decoded URL; Lightning Addresses as the unparsed `user@host` form.
 */
struct ParsedInput {
    friend uniffi::FfiConverterParsedInput;
    /**
     * A BOLT11 Lightning invoice.
     */
    struct kBolt11 {
        ParsedInvoice invoice;
    };
    /**
     * A Lightning node public key.
     */
    struct kNodeId {
        std::string node_id;
    };
    /**
     * An LNURL bech32 string (LUD-01) decoded to its underlying URL.
     * Pass to `resolve_input` (or fetch yourself) to determine
     * whether it's a pay, withdraw, or auth endpoint.
     */
    struct kLnUrl {
        std::string url;
    };
    /**
     * A Lightning Address (LUD-16) in the form `user@host`. The
     * well-known URL is not constructed offline; call `resolve_input`
     * to fetch and classify.
     */
    struct kLnUrlAddress {
        std::string address;
    };
    ParsedInput(kBolt11 variant): variant(variant) {}
    ParsedInput(kNodeId variant): variant(variant) {}
    ParsedInput(kLnUrl variant): variant(variant) {}
    ParsedInput(kLnUrlAddress variant): variant(variant) {}

    ParsedInput(const ParsedInput &other): variant(other.variant) {}
    ParsedInput(ParsedInput &&other): variant(std::move(other.variant)) {}

    ParsedInput &operator=(const ParsedInput &other) {
        variant = other.variant;
        return *this;
    }

    ParsedInput &operator=(ParsedInput &&other) {
        variant = std::move(other.variant);
        return *this;
    }

    /**
     * Returns the variant of this enum
     */
    const std::variant<kBolt11, kNodeId, kLnUrl, kLnUrlAddress> &get_variant() const {
        return variant;
    }

private:
    std::variant<kBolt11, kNodeId, kLnUrl, kLnUrlAddress> variant;

    ParsedInput();
};


struct FundChannel {
    /**
     * Peer node public key as lowercase hex (66 chars).
     */
    std::string peer_id;
    uint64_t our_amount_msat;
    uint64_t amount_msat;
    /**
     * Funding transaction id as lowercase hex (64 chars).
     */
    std::string funding_txid;
    uint32_t funding_output;
    bool connected;
    ChannelState state;
    std::optional<std::string> short_channel_id;
    /**
     * Channel id as lowercase hex (64 chars).
     */
    std::optional<std::string> channel_id;
};


/**
 * Request to execute an LNURL-pay flow.
 *
 * Combines the resolved service data with the user's chosen amount.
 */
struct LnUrlPayRequest {
    /**
     * The resolved pay request data from `parse_input()`.
     */
    LnUrlPayRequestData data;
    /**
     * Amount to pay in millisatoshis.
     */
    uint64_t amount_msat;
    /**
     * Optional comment to send with the payment.
     */
    std::optional<std::string> comment;
    /**
     * When true (the default), a URL success action is rejected if its
     * domain differs from the callback's domain.
     *
     * This is a wallet-side safety convention, not a LUD-09 requirement:
     * LUD-09 does not mandate same-domain URLs, but a divergent domain
     * can be used to phish users, so the SDK rejects it by default.
     * Set to `Some(false)` only if you have a specific reason to trust
     * cross-domain success-action URLs from this service.
     */
    std::optional<bool> validate_success_action_url;
};


/**
 * Request to execute an LNURL-withdraw flow.
 *
 * Combines the resolved service data with the user's chosen amount.
 */
struct LnUrlWithdrawRequest {
    /**
     * The resolved withdraw request data from `parse_input()`.
     */
    LnUrlWithdrawRequestData data;
    /**
     * Amount to withdraw in millisatoshis.
     */
    uint64_t amount_msat;
    /**
     * Optional description for the invoice (overrides default).
     */
    std::optional<std::string> description;
};


/**
 * A single log message from the SDK.
 */
struct LogEntry {
    LogLevel level;
    std::string message;
    /**
     * The module that produced this log (e.g. "gl_client::scheduler").
     */
    std::string target;
    /**
     * Source file path, if the log macro recorded one.
     */
    std::optional<std::string> file;
    /**
     * Source line number, if the log macro recorded one.
     */
    std::optional<uint32_t> line;
};


struct SendResponse {
    PayStatus status;
    /**
     * Payment preimage (proof of payment) as lowercase hex (64 chars).
     */
    std::string preimage;
    /**
     * Payment hash as lowercase hex (64 chars).
     */
    std::string payment_hash;
    /**
     * Recipient node pubkey as lowercase hex (66 chars), if known.
     */
    std::optional<std::string> destination_pubkey;
    uint64_t amount_msat;
    uint64_t amount_sent_msat;
    uint32_t parts;
};


/**
 * A point-in-time snapshot of the node's balances, capacity, and
 * connectivity. Returned by `node_state()`.
 *
 * All amounts are in millisatoshis (1 sat = 1000 msat).
 */
struct NodeState {
    /**
     * The node's public key as a lowercase hex string (66 chars).
     */
    std::string id;
    /**
     * Latest block height the node has synced to.
     */
    uint32_t block_height;
    /**
     * The Bitcoin network this node is running on (e.g. "bitcoin", "regtest").
     */
    std::string network;
    /**
     * CLN version string (e.g. "v24.11").
     */
    std::string version;
    /**
     * Human-readable node alias, if set.
     */
    std::optional<std::string> alias;
    /**
     * 3-byte RGB color of the node, as a lowercase hex string (6 chars).
     */
    std::string color;
    /**
     * Number of channels that are open and operational. These are the
     * channels that contribute to `channels_balance_msat`,
     * `max_payable_msat`, `total_channel_capacity_msat`, and
     * `total_inbound_liquidity_msat`.
     */
    uint32_t num_active_channels;
    /**
     * Number of channels that are being opened but not yet confirmed.
     * Pending channels do not contribute to any balance or capacity
     * field on this snapshot; their funds show up only after they
     * transition to active.
     */
    uint32_t num_pending_channels;
    /**
     * Number of channels that are open but the peer is offline.
     * Inactive channels hold balance but cannot be used for payments
     * until the peer reconnects; they do not contribute to
     * `max_payable_msat` or `total_inbound_liquidity_msat` (those are
     * computed from the live `spendable_msat` / `receivable_msat`
     * reported by CLN, which goes to zero when the peer is offline).
     */
    uint32_t num_inactive_channels;
    /**
     * Total our-side balance across all open channels, including amounts
     * that protocol reserves make unspendable.
     *
     * This is the field a wallet's home screen should show as the
     * user's "Lightning balance" — it reflects what they own off-chain,
     * matching what they'd expect to see at a glance.
     *
     * Do **not** use this to gate a send button: some of it is locked
     * in channel reserves. Use `max_payable_msat` for that.
     */
    uint64_t channels_balance_msat;
    /**
     * Aggregate spendable amount across all open channels. Equal to
     * `channels_balance_msat - max_chan_reserve_msat`.
     *
     * This is the field a send screen should gate against — it is what
     * the user can actually move right now over Lightning in total.
     *
     * Caveat: a single Lightning payment is additionally bounded by
     * the largest channel's own `spendable_msat`. Reaching this full
     * aggregate amount in one payment requires multi-path-payment
     * support from the recipient and a working route.
     */
    uint64_t max_payable_msat;
    /**
     * Sum of all open channel capacities (your side + remote side).
     */
    uint64_t total_channel_capacity_msat;
    /**
     * Amount locked in protocol channel reserves, computed as
     * `channels_balance_msat - max_payable_msat`. These sats are yours
     * on paper but cannot be spent until the channel closes.
     */
    uint64_t max_chan_reserve_msat;
    /**
     * Confirmed on-chain balance available for spending or opening channels.
     */
    uint64_t onchain_balance_msat;
    /**
     * On-chain balance from transactions that have not yet been confirmed.
     */
    uint64_t unconfirmed_onchain_balance_msat;
    /**
     * On-chain balance confirmed but not yet spendable (e.g. coinbase
     * outputs inside the 100-block maturation window).
     */
    uint64_t immature_onchain_balance_msat;
    /**
     * On-chain balance locked in channels that are being closed.
     * These funds will become available once the close is confirmed.
     */
    uint64_t pending_onchain_balance_msat;
    /**
     * Largest single Lightning payment the node can receive without
     * splitting across channels. Bounded by the inbound capacity of
     * the largest open channel.
     */
    uint64_t max_receivable_single_payment_msat;
    /**
     * Total amount you can receive across all open channels combined.
     */
    uint64_t total_inbound_liquidity_msat;
    /**
     * Lowercase hex public keys of peers we have at least one channel
     * with and are currently connected to. Peers we're connected to but
     * have no channel with are not represented here; for routing-node
     * use cases, query `list_peers()` directly.
     */
    std::vector<std::string> connected_channel_peers;
    /**
     * Unspent on-chain outputs owned by the node's wallet. Excludes
     * spent outputs; includes confirmed, unconfirmed, immature, and
     * reserved UTXOs (callers can filter by `status` and `reserved`).
     */
    std::vector<FundOutput> utxos;
    /**
     * All non-pending on-chain balance buckets summed:
     * `onchain_balance_msat + unconfirmed_onchain_balance_msat + immature_onchain_balance_msat`.
     * Excludes funds locked in closing channels (`pending_onchain_balance_msat`)
     * since those are not yet on-chain UTXOs.
     */
    uint64_t total_onchain_msat;
    /**
     * Everything the user owns, summed: channel balance (including
     * protocol reserves) + all on-chain buckets + funds locked in
     * closing channels. The "total holdings" number a wallet home
     * screen typically shows.
     */
    uint64_t total_balance_msat;
    /**
     * What the user can spend *right now*:
     * `max_payable_msat + onchain_balance_msat`. Excludes reserves,
     * unconfirmed, immature, and pending amounts. The number a
     * send-money screen should gate against.
     */
    uint64_t spendable_balance_msat;
};


struct ListPaysResponse {
    std::vector<Pay> pays;
};

namespace uniffi {
struct FfiConverterLnUrlPayResult;
} // namespace uniffi

/**
 * Result of an LNURL-pay operation.
 */
struct LnUrlPayResult {
    friend uniffi::FfiConverterLnUrlPayResult;
    /**
     * Payment succeeded.
     */
    struct kEndpointSuccess {
        LnUrlPaySuccessData data;
    };
    /**
     * The LNURL service returned an error before the invoice was paid.
     */
    struct kEndpointError {
        LnUrlErrorData data;
    };
    /**
     * The invoice was fetched successfully but paying it failed.
     */
    struct kPayError {
        LnUrlPayErrorData data;
    };
    LnUrlPayResult(kEndpointSuccess variant): variant(variant) {}
    LnUrlPayResult(kEndpointError variant): variant(variant) {}
    LnUrlPayResult(kPayError variant): variant(variant) {}

    LnUrlPayResult(const LnUrlPayResult &other): variant(other.variant) {}
    LnUrlPayResult(LnUrlPayResult &&other): variant(std::move(other.variant)) {}

    LnUrlPayResult &operator=(const LnUrlPayResult &other) {
        variant = other.variant;
        return *this;
    }

    LnUrlPayResult &operator=(LnUrlPayResult &&other) {
        variant = std::move(other.variant);
        return *this;
    }

    /**
     * Returns the variant of this enum
     */
    const std::variant<kEndpointSuccess, kEndpointError, kPayError> &get_variant() const {
        return variant;
    }

private:
    std::variant<kEndpointSuccess, kEndpointError, kPayError> variant;

    LnUrlPayResult();
};


struct ListFundsResponse {
    std::vector<FundOutput> outputs;
    std::vector<FundChannel> channels;
};


struct ListPeerChannelsResponse {
    std::vector<PeerChannel> channels;
};


struct ListInvoicesResponse {
    std::vector<Invoice> invoices;
};


namespace uniffi {
    struct FfiConverterConfig;
} // namespace uniffi

struct Config



{
    friend uniffi::FfiConverterConfig;

    Config() = delete;

    Config(Config &&) = delete;

    Config &operator=(const Config &) = delete;
    Config &operator=(Config &&) = delete;

    ~Config();
    /**
     * Create a Config with default settings: BITCOIN network, no developer certificate.
     */
    static std::shared_ptr<Config> init();
    /**
     * Return a new Config with the given developer certificate.
     * Nodes registered through this config will be associated with the developer's account.
     */
    std::shared_ptr<Config> with_developer_cert(const std::shared_ptr<DeveloperCert> &cert);
    /**
     * Return a new Config with the given network.
     */
    std::shared_ptr<Config> with_network(const Network &network);

    private:
    Config(const Config &);

    Config(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterCredentials;
} // namespace uniffi

/**
 * `Credentials` is a container for `node_id`, the mTLS client
 * certificate used to authenticate a client against a node, as well
 * as the seed secret if present. If no seed is present in the
 * credentials, then the `Client` will not start a signer in the
 * background.
 */
struct Credentials



{
    friend uniffi::FfiConverterCredentials;

    Credentials() = delete;

    Credentials(Credentials &&) = delete;

    Credentials &operator=(const Credentials &) = delete;
    Credentials &operator=(Credentials &&) = delete;

    ~Credentials();
    static std::shared_ptr<Credentials> load(const std::vector<uint8_t> &raw);
    std::vector<uint8_t> node_id();
    std::vector<uint8_t> save();

    private:
    Credentials(const Credentials &);

    Credentials(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterDeveloperCert;
} // namespace uniffi

/**
 * A developer certificate obtained from the Greenlight Developer
 * Console (GDC). When provided to a `Scheduler` via
 * `with_developer_cert()`, nodes registered through that scheduler
 * will be associated with the developer's account.
 *
 * If no developer certificate is provided, the scheduler falls back
 * to the compiled-in default certificate, which may be sufficient
 * when using an invite code instead.
 */
struct DeveloperCert



{
    friend uniffi::FfiConverterDeveloperCert;

    DeveloperCert() = delete;

    DeveloperCert(DeveloperCert &&) = delete;

    DeveloperCert &operator=(const DeveloperCert &) = delete;
    DeveloperCert &operator=(DeveloperCert &&) = delete;

    ~DeveloperCert();
    /**
     * Create a new `DeveloperCert` from the certificate and private
     * key PEM bytes obtained from the Greenlight Developer Console.
     */
    static std::shared_ptr<DeveloperCert> init(const std::vector<uint8_t> &cert, const std::vector<uint8_t> &key);

    private:
    DeveloperCert(const DeveloperCert &);

    DeveloperCert(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterHandle;
} // namespace uniffi

/**
 * A handle to interact with a signer loop running and processing
 * requests in the background. Used primarily to stop the loop and
 * exiting the signer.
 */
struct Handle



{
    friend uniffi::FfiConverterHandle;

    Handle() = delete;

    Handle(Handle &&) = delete;

    Handle &operator=(const Handle &) = delete;
    Handle &operator=(Handle &&) = delete;

    ~Handle();
    void stop();

    private:
    Handle(const Handle &);

    Handle(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterNode;
} // namespace uniffi

/**
 * The `Node` is an RPC stub representing the node running in the
 * cloud. It is the main entrypoint to interact with the node.
 */
struct Node



{
    friend uniffi::FfiConverterNode;

    Node() = delete;

    Node(Node &&) = delete;

    Node &operator=(const Node &) = delete;
    Node &operator=(Node &&) = delete;

    ~Node();
    /**
     * Returns the serialized credentials for this node.
     * The app should persist these bytes and pass them to connect() on next launch.
     */
    std::vector<uint8_t> credentials();
    /**
     * Disconnects from the node and stops the signer if running.
     * After disconnect, all RPC methods will return an error.
     * Safe to call multiple times.
     */
    void disconnect();
    /**
     * Collect a diagnostic snapshot of the node and SDK state.
     *
     * Returns a pretty-printed JSON string with shape:
     * `{ "timestamp": <unix-secs>, "node": { ... }, "sdk": { "version": ..., "node_state": ... } }`.
     * The `node` object contains one entry per CLN RPC (`getinfo`,
     * `listpeerchannels`, `listfunds`); each value is the serialized
     * response, or `{ "error": "..." }` if that RPC failed. Payment and
     * invoice history are deliberately excluded to avoid leaking
     * preimages, payment hashes, bolt11 strings, and labels into support
     * dumps. Intended for support tickets.
     */
    std::string generate_diagnostic_data();
    /**
     * Get information about the node.
     *
     * Returns basic information about the node including its ID,
     * alias, network, and channel counts.
     */
    GetInfoResponse get_info();
    /**
     * List all funds available to the node.
     *
     * Returns information about on-chain outputs and channel funds
     * that are available or pending.
     */
    ListFundsResponse list_funds();
    /**
     * List invoices (received payment requests).
     * All parameters are optional filters; pass None to fetch all.
     */
    ListInvoicesResponse list_invoices(std::optional<std::string> label, std::optional<std::string> invstring, std::optional<std::vector<uint8_t>> payment_hash, std::optional<std::string> offer_id, std::optional<ListIndex> index, std::optional<uint64_t> start, std::optional<uint32_t> limit);
    /**
     * List payments (sent and received), merged into a single timeline.
     *
     * Fetches invoices and outgoing payments from the node, merges
     * them into a unified list, and applies optional filters.
     * Use `list_invoices`/`list_pays` for direct CLN access.
     * Results are sorted newest-first.
     */
    std::vector<Payment> list_payments(const ListPaymentsRequest &req);
    /**
     * List outgoing payments.
     * All parameters are optional filters; pass None to fetch all.
     */
    ListPaysResponse list_pays(std::optional<std::string> bolt11, std::optional<std::vector<uint8_t>> payment_hash, std::optional<PayStatus> status, std::optional<ListIndex> index, std::optional<uint64_t> start, std::optional<uint32_t> limit);
    /**
     * List all channels with peers.
     *
     * Returns detailed information about all channels including their
     * state, capacity, and balances.
     */
    ListPeerChannelsResponse list_peer_channels();
    /**
     * List all peers connected to this node.
     *
     * Returns information about all peers including their connection
     * status.
     */
    ListPeersResponse list_peers();
    /**
     * Execute an LNURL-pay flow (LUD-06).
     *
     * Sends the chosen amount (and optional comment) to the service's
     * callback, receives and validates a BOLT11 invoice, pays it, and
     * processes any success action (LUD-09/10).
     *
     * Call the top-level `parse_input` first to obtain the
     * `LnUrlPayRequestData`, then build an `LnUrlPayRequest` with the
     * user's chosen amount.
     */
    LnUrlPayResult lnurl_pay(const LnUrlPayRequest &request);
    /**
     * Execute an LNURL-withdraw flow (LUD-03).
     *
     * Creates an invoice on this node for the requested amount, sends
     * it to the service's callback URL, and the service pays it
     * asynchronously.
     *
     * Call the top-level `parse_input` first to obtain the
     * `LnUrlWithdrawRequestData`, then build an `LnUrlWithdrawRequest`
     * with the user's chosen amount.
     */
    LnUrlWithdrawResult lnurl_withdraw(const LnUrlWithdrawRequest &request);
    /**
     * Get a snapshot of the node's balances, capacity, and connectivity.
     *
     * Aggregates data from multiple RPCs into a single `NodeState`.
     * Queries the node live on each call — not cached.
     */
    NodeState node_state();
    /**
     * Classify the on-chain wallet for the withdraw entry-point UI.
     *
     * Runs three RPCs concurrently:
     * * `list_funds` — current confirmed/unconfirmed/immature on-chain
     * balances.
     * * `list_peer_channels` — pending channel-close payouts that
     * haven't yet hit the wallet.
     * * `fund_psbt(satoshi=All, reserve=0, normal feerate)` — a
     * non-locking probe whose response tells us **exactly** how
     * much CLN will carve as the anchor-channel emergency reserve
     * for this specific node, no client-side guessing required.
     * The carved amount is computed from the response as
     * `total_inputs − excess − fee`, which is identical to what
     * CLN would carve on a real broadcast.
     *
     * Cheaper to call than `node_state()` and answers a different
     * question. Wallets typically call it once per render of the
     * home screen.
     *
     * For the *exact* post-fee recipient amount of a withdraw, use
     * `prepare_onchain_send`; the `withdrawable_sat` returned here
     * is a pre-fee, reserve-aware figure for the entry-point label.
     */
    OnchainBalanceState onchain_balance_state();
    /**
     * On-chain fee rates, in sats per virtual byte, at several
     * confirmation targets.
     *
     * Sourced from the connected node's view of the network — no
     * 3rd-party HTTP calls. Use as the basis for a fee-picker UI;
     * `minimum_relay_sat_per_vbyte` is the relay floor enforced at
     * broadcast time and should be the lower bound of any slider.
     */
    OnchainFeeRates onchain_fee_rates();
    /**
     * Generate a fresh on-chain Bitcoin address for receiving funds.
     *
     * Returns both a bech32 (SegWit v0) and a p2tr (Taproot) address.
     * Either can be shared with a sender. Deposited funds will appear
     * in `node_state().onchain_balance_msat` once confirmed.
     */
    OnchainReceiveResponse onchain_receive();
    /**
     * Send bitcoin on-chain to a destination address.
     *
     * # Arguments
     * * `destination` — A Bitcoin address (bech32, p2sh, or p2tr).
     * * `amount_or_all` — Amount to send. Accepts:
     * - `"50000"` or `"50000sat"` — 50,000 satoshis
     * - `"50000msat"` — 50,000 millisatoshis
     * - `"all"` — sweep the entire on-chain balance
     * * `sat_per_vbyte` — Optional fee rate in sats per virtual byte.
     * Pass `None` to let the node pick. Pass the value from a prior
     * `prepare_onchain_send` to reproduce the previewed fee.
     * * `utxos` — Optional pinned input set. Pass the `utxos` returned
     * by `prepare_onchain_send` (together with the same
     * `sat_per_vbyte`) to broadcast a transaction with the exact
     * inputs and fee shown in the preview. Pass `None` to let the
     * node coin-select.
     *
     * Returns the raw transaction, txid, and PSBT once broadcast.
     * The transaction is broadcast immediately — this is not a dry run.
     */
    OnchainSendResponse onchain_send(const std::string &destination, const std::string &amount_or_all, std::optional<uint32_t> sat_per_vbyte, std::optional<std::vector<Outpoint>> utxos);
    /**
     * Preview an on-chain send without broadcasting or reserving UTXOs.
     *
     * Runs CLN's coin selection at the given fee rate and returns the
     * inputs that would be spent, the fee, and the amount the recipient
     * would receive. Safe to call repeatedly (e.g. while the user
     * adjusts a fee slider) — nothing is locked.
     *
     * To broadcast with the previewed values, pass the returned
     * `utxos` and `sat_per_vbyte` back to `onchain_send`. Identical
     * inputs at the same fee rate yield the same fee.
     *
     * **Use this for "Send Max" UIs.** `recipient_sat` is the only
     * authoritative post-fee amount the destination will receive
     * for a sweep. `NodeState.onchain_balance_msat` includes the
     * emergency reserve and the fee — neither of which leaves the
     * wallet with the recipient. For the entry-point button label
     * (a pre-fee approximation that updates without an RPC), use
     * `OnchainBalanceState::Available.withdrawable_sat`.
     *
     * # Arguments
     * * `destination` — A Bitcoin address (bech32, p2sh, or p2tr).
     * * `amount_or_all` — Amount to send. Accepts:
     * - `"50000"` or `"50000sat"` — 50,000 satoshis
     * - `"50000msat"` — 50,000 millisatoshis
     * - `"all"` — sweep the entire on-chain balance
     * * `sat_per_vbyte` — Fee rate in sats per virtual byte. Pass
     * `None` to use the node's "normal" priority feerate; the
     * effective rate CLN picked is reported back in the result's
     * `sat_per_vbyte` field, which can be passed to `onchain_send`
     * to reproduce it.
     */
    PreparedOnchainSend prepare_onchain_send(const std::string &destination, const std::string &amount_or_all, std::optional<uint32_t> sat_per_vbyte);
    /**
     * Receive an off-chain payment.
     *
     * This method generates a request for a payment, also called an
     * invoice, that encodes all the information, including amount
     * and destination, for a prospective sender to send a lightning
     * payment. The invoice includes negotiation of an LSPS2 / JIT
     * channel, meaning that if there is no channel sufficient to
     * receive the requested funds, the node will negotiate an
     * opening, and when/if executed the payment will cause a channel
     * to be created, and the incoming payment to be forwarded.
     */
    ReceiveResponse receive(const std::string &label, const std::string &description, std::optional<uint64_t> amount_msat);
    SendResponse send(const std::string &invoice, std::optional<uint64_t> amount_msat);
    /**
     * Stop the node if it is currently running.
     */
    void stop();
    /**
     * Stream real-time events from the node.
     *
     * Returns a `NodeEventStream` iterator. Call `next()` repeatedly
     * to receive events as they occur (e.g., invoice payments).
     *
     * The `next()` method blocks the calling thread until an event
     * is available, but does not block the underlying async runtime,
     * so other node methods can be called concurrently from other
     * threads.
     */
    std::shared_ptr<NodeEventStream> stream_node_events();

    private:
    Node(const Node &);

    Node(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterNodeBuilder;
} // namespace uniffi

/**
 * Configurable Node construction. See module docs.
 *
 * All fields are immutable after construction. Each `with_*` setter
 * returns a fresh `Arc<NodeBuilder>` that shares ownership of any
 * previously-installed modifiers via `Arc<dyn …>`. No interior
 * mutability, no locks — the builder is a value, not a state
 * machine.
 */
struct NodeBuilder



{
    friend uniffi::FfiConverterNodeBuilder;

    NodeBuilder() = delete;

    NodeBuilder(NodeBuilder &&) = delete;

    NodeBuilder &operator=(const NodeBuilder &) = delete;
    NodeBuilder &operator=(NodeBuilder &&) = delete;

    ~NodeBuilder();
    /**
     * Create a builder for a Node with `config`. No I/O happens
     * until you call `connect` / `register` / `recover` /
     * `register_or_recover`.
     */
    static std::shared_ptr<NodeBuilder> init(const std::shared_ptr<Config> &config);
    /**
     * Connect to an existing node using saved credentials and return
     * a connected Node with any configured modifiers applied.
     *
     * If `mnemonic` is `Some(...)`, the SDK spawns a signer for the
     * connected Node. If `None`, the Node is signerless and signing
     * happens elsewhere (paired device, CLN node's local signer,
     * hardware signer).
     */
    std::shared_ptr<Node> connect(const std::vector<uint8_t> &credentials, std::optional<std::string> mnemonic);
    /**
     * Recover credentials for an existing node and return a
     * connected Node with any configured modifiers applied.
     *
     * `mnemonic` is required — recovery drives the signer to
     * authenticate.
     */
    std::shared_ptr<Node> recover(const std::string &mnemonic);
    /**
     * Register a new Greenlight node and return a connected Node
     * with the SDK signer running and any configured modifiers
     * applied.
     *
     * `mnemonic` is required — registration drives the signer to
     * sign the registration challenge, so the SDK must hold the
     * seed for this call.
     */
    std::shared_ptr<Node> register_node(const std::string &mnemonic, std::optional<std::string> invite_code);
    /**
     * Try to recover; if the node doesn't exist, register a new one.
     *
     * `mnemonic` is required — both recover and register drive the
     * signer.
     */
    std::shared_ptr<Node> register_or_recover(const std::string &mnemonic, std::optional<std::string> invite_code);
    /**
     * Install a node event listener. Events fire from the moment the
     * gRPC stream is established by the build call (`register` /
     * `recover` / `connect` / …), so attach the listener via the
     * builder rather than after the fact to capture events from the
     * very first moment.
     *
     * Returns a new builder that shares the rest of the
     * configuration. Build calls on the returned builder will
     * install the listener; the original builder is unchanged.
     */
    std::shared_ptr<NodeBuilder> with_event_listener(const std::shared_ptr<NodeEventListener> &listener);

    private:
    NodeBuilder(const NodeBuilder &);

    NodeBuilder(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterNodeEventStream;
} // namespace uniffi

/**
 * A stream of node events. Call `next()` to receive the next event.
 *
 * The stream is backed by a gRPC streaming connection to the node.
 * Each call to `next()` blocks the calling thread until an event is
 * available, but does not block the tokio runtime - other node
 * operations can proceed concurrently from other threads.
 */
struct NodeEventStream



{
    friend uniffi::FfiConverterNodeEventStream;

    NodeEventStream() = delete;

    NodeEventStream(NodeEventStream &&) = delete;

    NodeEventStream &operator=(const NodeEventStream &) = delete;
    NodeEventStream &operator=(NodeEventStream &&) = delete;

    ~NodeEventStream();
    /**
     * Get the next event from the stream.
     *
     * Blocks the calling thread until an event is available or the
     * stream ends. Returns `None` when the stream is exhausted or
     * the connection is lost.
     */
    std::optional<NodeEvent> next();

    private:
    NodeEventStream(const NodeEventStream &);

    NodeEventStream(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterScheduler;
} // namespace uniffi

struct Scheduler



{
    friend uniffi::FfiConverterScheduler;

    Scheduler() = delete;

    Scheduler(Scheduler &&) = delete;

    Scheduler &operator=(const Scheduler &) = delete;
    Scheduler &operator=(Scheduler &&) = delete;

    ~Scheduler();
    /**
     * Create a `Scheduler` instance configured with the Greenlight
     * production service pre-configured.
     */
    static std::shared_ptr<Scheduler> init(const Network &network);
    std::shared_ptr<Credentials> recover(const std::shared_ptr<Signer> &signer);
    std::shared_ptr<Credentials> register_node(const std::shared_ptr<Signer> &signer, std::optional<std::string> code);
    /**
     * Configure a developer certificate obtained from the Greenlight
     * Developer Console. Nodes registered through this scheduler
     * will be associated with the developer's account.
     *
     * Returns a new `Scheduler` instance with the developer
     * certificate configured.
     */
    std::shared_ptr<Scheduler> with_developer_cert(const std::shared_ptr<DeveloperCert> &cert);

    private:
    Scheduler(const Scheduler &);

    Scheduler(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterSigner;
} // namespace uniffi

struct Signer



{
    friend uniffi::FfiConverterSigner;

    Signer() = delete;

    Signer(Signer &&) = delete;

    Signer &operator=(const Signer &) = delete;
    Signer &operator=(Signer &&) = delete;

    ~Signer();
    static std::shared_ptr<Signer> init(const std::string &phrase);
    static std::shared_ptr<Signer> new_from_seed(const std::vector<uint8_t> &seed);
    std::shared_ptr<Signer> authenticate(const std::shared_ptr<Credentials> &creds);
    std::vector<uint8_t> node_id();
    std::shared_ptr<Handle> start();

    private:
    Signer(const Signer &);

    Signer(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


struct GetInfoResponse {
    /**
     * Node public key as lowercase hex (66 chars).
     */
    std::string id;
    std::optional<std::string> alias;
    /**
     * 3-byte RGB color as lowercase hex (6 chars).
     */
    std::string color;
    uint32_t num_peers;
    uint32_t num_pending_channels;
    uint32_t num_active_channels;
    uint32_t num_inactive_channels;
    std::string version;
    std::string lightning_dir;
    uint32_t blockheight;
    std::string network;
    uint64_t fees_collected_msat;
};


/**
 * On-chain fee rates in sats per virtual byte at various
 * confirmation targets, derived from the connected node's view of
 * network mempool conditions. Use as the basis for a fee-picker UI.
 */
struct OnchainFeeRates {
    /**
     * Target the next block (~10 min).
     */
    uint64_t next_block_sat_per_vbyte;
    /**
     * ~30 minute confirmation target (3 blocks).
     */
    uint64_t half_hour_sat_per_vbyte;
    /**
     * ~1 hour confirmation target (6 blocks).
     */
    uint64_t hour_sat_per_vbyte;
    /**
     * ~1 day confirmation target (144 blocks). Suitable for
     * non-urgent sweeps.
     */
    uint64_t day_sat_per_vbyte;
    /**
     * Network minimum relay fee. Anything below this will be
     * rejected by mempool policy at broadcast time. Use as the
     * lower bound of any user-facing fee slider.
     */
    uint64_t minimum_relay_sat_per_vbyte;
};


/**
 * A pair of on-chain addresses for receiving funds.
 */
struct OnchainReceiveResponse {
    /**
     * SegWit v0 (bech32) address — starts with `bc1q` on mainnet.
     */
    std::string bech32;
    /**
     * Taproot (bech32m) address — starts with `bc1p` on mainnet.
     */
    std::string p2tr;
};


/**
 * Result of an on-chain send. The transaction has already been broadcast.
 */
struct OnchainSendResponse {
    /**
     * The raw signed transaction bytes.
     */
    std::vector<uint8_t> tx;
    /**
     * The transaction id as lowercase hex (64 chars).
     */
    std::string txid;
    /**
     * The transaction as a Partially Signed Bitcoin Transaction string.
     */
    std::string psbt;
};


struct ReceiveResponse {
    std::string bolt11;
    /**
     * The fee charged by the LSP for opening a JIT channel, in
     * millisatoshi. This is 0 if no JIT channel was needed.
     */
    uint64_t opening_fee_msat;
};

namespace uniffi {
struct FfiConverterError;
} // namespace uniffi

struct Error: std::runtime_error {
    friend uniffi::FfiConverterError;

    Error() : std::runtime_error("") {}
    Error(const std::string &what_arg) : std::runtime_error(what_arg) {}

    virtual ~Error() = default;

    virtual void throw_underlying() {
        throw *this;
    }

protected:
    virtual int32_t get_variant_idx() const {
        return 0;
    };
};
/**
 * Contains variants of Error
 */
namespace error {

struct DuplicateNode: Error {
    int32_t code;
    std::string msg;
    std::unordered_map<std::string, std::string> values;

    DuplicateNode() : Error("") {}
    DuplicateNode(const std::string &what_arg) : Error(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 1;
    }
};

struct NoSuchNode: Error {
    int32_t code;
    std::string msg;
    std::unordered_map<std::string, std::string> values;

    NoSuchNode() : Error("") {}
    NoSuchNode(const std::string &what_arg) : Error(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 2;
    }
};

struct UnparseableCreds: Error {
    int32_t code;
    std::string msg;
    std::unordered_map<std::string, std::string> values;

    UnparseableCreds() : Error("") {}
    UnparseableCreds(const std::string &what_arg) : Error(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 3;
    }
};

struct PhraseCorrupted: Error {
    int32_t code;
    std::string msg;
    std::unordered_map<std::string, std::string> values;

    PhraseCorrupted() : Error("") {}
    PhraseCorrupted(const std::string &what_arg) : Error(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 4;
    }
};

struct Rpc: Error {
    int32_t code;
    std::string msg;
    std::unordered_map<std::string, std::string> values;

    Rpc() : Error("") {}
    Rpc(const std::string &what_arg) : Error(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 5;
    }
};

struct Argument: Error {
    int32_t code;
    std::string msg;
    std::unordered_map<std::string, std::string> values;

    Argument() : Error("") {}
    Argument(const std::string &what_arg) : Error(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 6;
    }
};

struct Other: Error {
    int32_t code;
    std::string msg;
    std::unordered_map<std::string, std::string> values;

    Other() : Error("") {}
    Other(const std::string &what_arg) : Error(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 7;
    }
};
} // namespace error


/**
 * Index field used by CLN's paginated list RPCs.
 */
enum class ListIndex: int32_t {
    kCreated = 1,
    kUpdated = 2
};


enum class Network: int32_t {
    kBitcoin = 1,
    kRegtest = 2
};

namespace uniffi {
struct FfiConverterOnchainBalanceState;
} // namespace uniffi

/**
 * Classifies the on-chain wallet into discrete cases that a wallet
 * UI can switch on to render the correct entry-point for the
 * withdraw flow. Derived purely from `NodeState` — no RPC.
 */
struct OnchainBalanceState {
    friend uniffi::FfiConverterOnchainBalanceState;
    /**
     * No funds on-chain in any form (confirmed, unconfirmed,
     * immature, or pending channel-close payouts are all zero).
     * Don't render a withdraw entry point.
     */
    struct kUnavailable {
    };
    /**
     * Funds are spendable now. Render the withdraw entry point
     * enabled with `withdrawable_sat` as the headline.
     */
    struct kAvailable {
        /**
         * `onchain_balance_sat - emergency_reserve_sat`. Use as
         * the displayed amount on the entry point.
         */
        uint64_t withdrawable_sat;
        /**
         * Held back by CLN for anchor-channel safety; cannot be
         * withdrawn without closing channels first.
         */
        uint64_t emergency_reserve_sat;
        /**
         * Inbound on-chain funds not yet confirmed. Informational
         * only — not part of `withdrawable_sat`.
         */
        uint64_t unconfirmed_sat;
    };
    /**
     * On-chain funds exist but are entirely locked as the
     * anchor-channel emergency reserve. Render the entry point
     * disabled with an explainer (e.g. "close channels to free
     * these funds").
     */
    struct kReserveOnly {
        uint64_t reserve_sat;
    };
    /**
     * Inbound on-chain funds are awaiting confirmation. Render a
     * "pending" indicator instead of an enabled withdraw button.
     */
    struct kPendingConfirmation {
        uint64_t unconfirmed_sat;
    };
    /**
     * Funds exist as CSV-timelocked outputs from a recent channel
     * close and can't be spent until the relative locktime
     * expires. Render the entry point disabled with a
     * "channel closing" explainer.
     */
    struct kImmature {
        uint64_t immature_sat;
    };
    OnchainBalanceState(kUnavailable variant): variant(variant) {}
    OnchainBalanceState(kAvailable variant): variant(variant) {}
    OnchainBalanceState(kReserveOnly variant): variant(variant) {}
    OnchainBalanceState(kPendingConfirmation variant): variant(variant) {}
    OnchainBalanceState(kImmature variant): variant(variant) {}

    OnchainBalanceState(const OnchainBalanceState &other): variant(other.variant) {}
    OnchainBalanceState(OnchainBalanceState &&other): variant(std::move(other.variant)) {}

    OnchainBalanceState &operator=(const OnchainBalanceState &other) {
        variant = other.variant;
        return *this;
    }

    OnchainBalanceState &operator=(OnchainBalanceState &&other) {
        variant = std::move(other.variant);
        return *this;
    }

    /**
     * Returns the variant of this enum
     */
    const std::variant<kUnavailable, kAvailable, kReserveOnly, kPendingConfirmation, kImmature> &get_variant() const {
        return variant;
    }

private:
    std::variant<kUnavailable, kAvailable, kReserveOnly, kPendingConfirmation, kImmature> variant;

    OnchainBalanceState();
};



/**
 * Callback interface for receiving log messages.
 *
 * `on_log` is invoked on the thread that emitted the log — which can
 * be any tokio worker or background thread inside the SDK. Keep the
 * implementation cheap and non-blocking; if you need UI updates,
 * hand the entry off to your app's main thread.
 */
struct LogListener {
    virtual ~LogListener() {}
    virtual
    void on_log(const LogEntry &entry) = 0;
};

namespace uniffi {
    struct UniffiCallbackInterfaceLogListener {
        static void on_log(uint64_t uniffi_handle,RustBuffer entry,void * uniffi_out_return,RustCallStatus *out_status);

        static void uniffi_free(uint64_t uniffi_handle);
        static void init();
    private:
        static inline UniffiVTableCallbackInterfaceLogListener vtable = UniffiVTableCallbackInterfaceLogListener {
            .on_log = reinterpret_cast<void *>(&on_log),
            .uniffi_free = reinterpret_cast<void *>(&uniffi_free)
        };
    };
}



/**
 * Callback interface for receiving node events.
 *
 * `on_event` is invoked from the SDK's internal event-dispatch task.
 * Implementations should be cheap and non-blocking; to update UI,
 * dispatch to the main thread from inside the handler.
 *
 * Installed via `NodeBuilder::with_event_listener(...)` so events
 * emitted during node bring-up are captured. The polling-style
 * `Node::stream_node_events()` API is still available for callers
 * that prefer to drive events themselves.
 */
struct NodeEventListener {
    virtual ~NodeEventListener() {}
    virtual
    void on_event(NodeEvent event) = 0;
};

namespace uniffi {
    struct UniffiCallbackInterfaceNodeEventListener {
        static void on_event(uint64_t uniffi_handle,RustBuffer event,void * uniffi_out_return,RustCallStatus *out_status);

        static void uniffi_free(uint64_t uniffi_handle);
        static void init();
    private:
        static inline UniffiVTableCallbackInterfaceNodeEventListener vtable = UniffiVTableCallbackInterfaceNodeEventListener {
            .on_event = reinterpret_cast<void *>(&on_event),
            .uniffi_free = reinterpret_cast<void *>(&uniffi_free)
        };
    };
}

namespace uniffi {struct RustStreamBuffer: std::basic_streambuf<char> {
    RustStreamBuffer(RustBuffer *buf) {
        char* data = reinterpret_cast<char*>(buf->data);
        this->setg(data, data, data + buf->len);
        this->setp(data, data + buf->capacity);
    }
    ~RustStreamBuffer() = default;

private:
    RustStreamBuffer() = delete;
    RustStreamBuffer(const RustStreamBuffer &) = delete;
    RustStreamBuffer(RustStreamBuffer &&) = delete;

    RustStreamBuffer &operator=(const RustStreamBuffer &) = delete;
    RustStreamBuffer &operator=(RustStreamBuffer &&) = delete;
};

struct RustStream: std::basic_iostream<char> {
    RustStream(RustBuffer *buf):
        std::basic_iostream<char>(&streambuf), streambuf(RustStreamBuffer(buf)) { }

    template <typename T, typename = std::enable_if_t<std::is_arithmetic_v<T>>>
    RustStream &operator>>(T &val) {
        read(reinterpret_cast<char *>(&val), sizeof(T));

        if (std::endian::native != std::endian::big) {
            auto bytes = reinterpret_cast<char *>(&val);

            std::reverse(bytes, bytes + sizeof(T));
        }

        return *this;
    }

    template <typename T, typename = std::enable_if_t<std::is_arithmetic_v<T>>>
    RustStream &operator<<(T val) {
        if (std::endian::native != std::endian::big) {
            auto bytes = reinterpret_cast<char *>(&val);

            std::reverse(bytes, bytes + sizeof(T));
        }

        write(reinterpret_cast<char *>(&val), sizeof(T));

        return *this;
    }
private:
    RustStreamBuffer streambuf;
};


RustBuffer rustbuffer_alloc(uint64_t);
RustBuffer rustbuffer_from_bytes(const ForeignBytes &);
void rustbuffer_free(RustBuffer);
template <typename T> struct HandleMap {
    HandleMap() = default;

    std::shared_ptr<T> at(uint64_t handle) {
        std::lock_guard<std::mutex> guard(this->mutex);

        return this->map.at(handle);
    }

    uint64_t insert(std::shared_ptr<T> impl) {
        std::lock_guard<std::mutex> guard(this->mutex);

        auto handle = this->cur_handle;

        this->map.insert({ handle, impl });
        this->cur_handle += 1;

        return handle;
    }

    void erase(uint64_t handle) {
        // We store the object here to avoid re-entrant locking
        std::shared_ptr<T> cleanup;
        {
            std::lock_guard<std::mutex> guard(this->mutex);
            auto it = this->map.find(handle);
            if (it != this->map.end()) {
                cleanup = it->second;
                this->map.erase(it);
            }
        }
    }
    private:
        HandleMap(const HandleMap<T> &) = delete;
        HandleMap(HandleMap<T> &&) = delete;

        HandleMap<T> &operator=(const HandleMap<T> &) = delete;
        HandleMap<T> &operator=(HandleMap<T> &&) = delete;

        std::mutex mutex;
        uint64_t cur_handle = 0;
        std::map<uint64_t, std::shared_ptr<T>> map;
};
struct FfiConverterUInt32 {
    static uint32_t lift(uint32_t);
    static uint32_t lower(uint32_t);
    static uint32_t read(RustStream &);
    static void write(RustStream &, uint32_t);
    static uint64_t allocation_size(uint32_t);
};
struct FfiConverterInt32 {
    static int32_t lift(int32_t);
    static int32_t lower(int32_t);
    static int32_t read(RustStream &);
    static void write(RustStream &, int32_t);
    static uint64_t allocation_size(int32_t);
};
struct FfiConverterUInt64 {
    static uint64_t lift(uint64_t);
    static uint64_t lower(uint64_t);
    static uint64_t read(RustStream &);
    static void write(RustStream &, uint64_t);
    static uint64_t allocation_size(uint64_t);
};
struct FfiConverterBool {
    static bool lift(uint8_t);
    static uint8_t lower(bool);
    static bool read(RustStream &);
    static void write(RustStream &, bool);
    static uint64_t allocation_size(bool);
};
struct FfiConverterString {
    static std::string lift(RustBuffer buf);
    static RustBuffer lower(const std::string &);
    static std::string read(RustStream &);
    static void write(RustStream &, const std::string &);
    static uint64_t allocation_size(const std::string &);
};

struct FfiConverterBytes {
    static std::vector<uint8_t> lift(RustBuffer);
    static RustBuffer lower(const std::vector<uint8_t> &);
    static std::vector<uint8_t> read(RustStream &);
    static void write(RustStream &, const std::vector<uint8_t> &);
    static uint64_t allocation_size(const std::vector<uint8_t> &);
};


struct FfiConverterConfig {
    static std::shared_ptr<Config> lift(void *);
    static void *lower(const std::shared_ptr<Config> &);
    static std::shared_ptr<Config> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Config> &);
    static uint64_t allocation_size(const std::shared_ptr<Config> &);
private:
};


struct FfiConverterCredentials {
    static std::shared_ptr<Credentials> lift(void *);
    static void *lower(const std::shared_ptr<Credentials> &);
    static std::shared_ptr<Credentials> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Credentials> &);
    static uint64_t allocation_size(const std::shared_ptr<Credentials> &);
private:
};


struct FfiConverterDeveloperCert {
    static std::shared_ptr<DeveloperCert> lift(void *);
    static void *lower(const std::shared_ptr<DeveloperCert> &);
    static std::shared_ptr<DeveloperCert> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<DeveloperCert> &);
    static uint64_t allocation_size(const std::shared_ptr<DeveloperCert> &);
private:
};


struct FfiConverterHandle {
    static std::shared_ptr<Handle> lift(void *);
    static void *lower(const std::shared_ptr<Handle> &);
    static std::shared_ptr<Handle> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Handle> &);
    static uint64_t allocation_size(const std::shared_ptr<Handle> &);
private:
};


struct FfiConverterNode {
    static std::shared_ptr<Node> lift(void *);
    static void *lower(const std::shared_ptr<Node> &);
    static std::shared_ptr<Node> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Node> &);
    static uint64_t allocation_size(const std::shared_ptr<Node> &);
private:
};


struct FfiConverterNodeBuilder {
    static std::shared_ptr<NodeBuilder> lift(void *);
    static void *lower(const std::shared_ptr<NodeBuilder> &);
    static std::shared_ptr<NodeBuilder> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<NodeBuilder> &);
    static uint64_t allocation_size(const std::shared_ptr<NodeBuilder> &);
private:
};


struct FfiConverterNodeEventStream {
    static std::shared_ptr<NodeEventStream> lift(void *);
    static void *lower(const std::shared_ptr<NodeEventStream> &);
    static std::shared_ptr<NodeEventStream> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<NodeEventStream> &);
    static uint64_t allocation_size(const std::shared_ptr<NodeEventStream> &);
private:
};


struct FfiConverterScheduler {
    static std::shared_ptr<Scheduler> lift(void *);
    static void *lower(const std::shared_ptr<Scheduler> &);
    static std::shared_ptr<Scheduler> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Scheduler> &);
    static uint64_t allocation_size(const std::shared_ptr<Scheduler> &);
private:
};


struct FfiConverterSigner {
    static std::shared_ptr<Signer> lift(void *);
    static void *lower(const std::shared_ptr<Signer> &);
    static std::shared_ptr<Signer> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Signer> &);
    static uint64_t allocation_size(const std::shared_ptr<Signer> &);
private:
};

struct FfiConverterTypeFundChannel {
    static FundChannel lift(RustBuffer);
    static RustBuffer lower(const FundChannel &);
    static FundChannel read(RustStream &);
    static void write(RustStream &, const FundChannel &);
    static uint64_t allocation_size(const FundChannel &);
};

struct FfiConverterTypeFundOutput {
    static FundOutput lift(RustBuffer);
    static RustBuffer lower(const FundOutput &);
    static FundOutput read(RustStream &);
    static void write(RustStream &, const FundOutput &);
    static uint64_t allocation_size(const FundOutput &);
};

struct FfiConverterTypeGetInfoResponse {
    static GetInfoResponse lift(RustBuffer);
    static RustBuffer lower(const GetInfoResponse &);
    static GetInfoResponse read(RustStream &);
    static void write(RustStream &, const GetInfoResponse &);
    static uint64_t allocation_size(const GetInfoResponse &);
};

struct FfiConverterTypeInvoice {
    static Invoice lift(RustBuffer);
    static RustBuffer lower(const Invoice &);
    static Invoice read(RustStream &);
    static void write(RustStream &, const Invoice &);
    static uint64_t allocation_size(const Invoice &);
};

struct FfiConverterTypeInvoicePaidEvent {
    static InvoicePaidEvent lift(RustBuffer);
    static RustBuffer lower(const InvoicePaidEvent &);
    static InvoicePaidEvent read(RustStream &);
    static void write(RustStream &, const InvoicePaidEvent &);
    static uint64_t allocation_size(const InvoicePaidEvent &);
};

struct FfiConverterTypeListFundsResponse {
    static ListFundsResponse lift(RustBuffer);
    static RustBuffer lower(const ListFundsResponse &);
    static ListFundsResponse read(RustStream &);
    static void write(RustStream &, const ListFundsResponse &);
    static uint64_t allocation_size(const ListFundsResponse &);
};

struct FfiConverterTypeListInvoicesResponse {
    static ListInvoicesResponse lift(RustBuffer);
    static RustBuffer lower(const ListInvoicesResponse &);
    static ListInvoicesResponse read(RustStream &);
    static void write(RustStream &, const ListInvoicesResponse &);
    static uint64_t allocation_size(const ListInvoicesResponse &);
};

struct FfiConverterTypeListPaymentsRequest {
    static ListPaymentsRequest lift(RustBuffer);
    static RustBuffer lower(const ListPaymentsRequest &);
    static ListPaymentsRequest read(RustStream &);
    static void write(RustStream &, const ListPaymentsRequest &);
    static uint64_t allocation_size(const ListPaymentsRequest &);
};

struct FfiConverterTypeListPaysResponse {
    static ListPaysResponse lift(RustBuffer);
    static RustBuffer lower(const ListPaysResponse &);
    static ListPaysResponse read(RustStream &);
    static void write(RustStream &, const ListPaysResponse &);
    static uint64_t allocation_size(const ListPaysResponse &);
};

struct FfiConverterTypeListPeerChannelsResponse {
    static ListPeerChannelsResponse lift(RustBuffer);
    static RustBuffer lower(const ListPeerChannelsResponse &);
    static ListPeerChannelsResponse read(RustStream &);
    static void write(RustStream &, const ListPeerChannelsResponse &);
    static uint64_t allocation_size(const ListPeerChannelsResponse &);
};

struct FfiConverterTypeListPeersResponse {
    static ListPeersResponse lift(RustBuffer);
    static RustBuffer lower(const ListPeersResponse &);
    static ListPeersResponse read(RustStream &);
    static void write(RustStream &, const ListPeersResponse &);
    static uint64_t allocation_size(const ListPeersResponse &);
};

struct FfiConverterTypeLnUrlErrorData {
    static LnUrlErrorData lift(RustBuffer);
    static RustBuffer lower(const LnUrlErrorData &);
    static LnUrlErrorData read(RustStream &);
    static void write(RustStream &, const LnUrlErrorData &);
    static uint64_t allocation_size(const LnUrlErrorData &);
};

struct FfiConverterTypeLnUrlPayErrorData {
    static LnUrlPayErrorData lift(RustBuffer);
    static RustBuffer lower(const LnUrlPayErrorData &);
    static LnUrlPayErrorData read(RustStream &);
    static void write(RustStream &, const LnUrlPayErrorData &);
    static uint64_t allocation_size(const LnUrlPayErrorData &);
};

struct FfiConverterTypeLnUrlPayRequest {
    static LnUrlPayRequest lift(RustBuffer);
    static RustBuffer lower(const LnUrlPayRequest &);
    static LnUrlPayRequest read(RustStream &);
    static void write(RustStream &, const LnUrlPayRequest &);
    static uint64_t allocation_size(const LnUrlPayRequest &);
};

struct FfiConverterTypeLnUrlPayRequestData {
    static LnUrlPayRequestData lift(RustBuffer);
    static RustBuffer lower(const LnUrlPayRequestData &);
    static LnUrlPayRequestData read(RustStream &);
    static void write(RustStream &, const LnUrlPayRequestData &);
    static uint64_t allocation_size(const LnUrlPayRequestData &);
};

struct FfiConverterTypeLnUrlPaySuccessData {
    static LnUrlPaySuccessData lift(RustBuffer);
    static RustBuffer lower(const LnUrlPaySuccessData &);
    static LnUrlPaySuccessData read(RustStream &);
    static void write(RustStream &, const LnUrlPaySuccessData &);
    static uint64_t allocation_size(const LnUrlPaySuccessData &);
};

struct FfiConverterTypeLnUrlWithdrawRequest {
    static LnUrlWithdrawRequest lift(RustBuffer);
    static RustBuffer lower(const LnUrlWithdrawRequest &);
    static LnUrlWithdrawRequest read(RustStream &);
    static void write(RustStream &, const LnUrlWithdrawRequest &);
    static uint64_t allocation_size(const LnUrlWithdrawRequest &);
};

struct FfiConverterTypeLnUrlWithdrawRequestData {
    static LnUrlWithdrawRequestData lift(RustBuffer);
    static RustBuffer lower(const LnUrlWithdrawRequestData &);
    static LnUrlWithdrawRequestData read(RustStream &);
    static void write(RustStream &, const LnUrlWithdrawRequestData &);
    static uint64_t allocation_size(const LnUrlWithdrawRequestData &);
};

struct FfiConverterTypeLnUrlWithdrawSuccessData {
    static LnUrlWithdrawSuccessData lift(RustBuffer);
    static RustBuffer lower(const LnUrlWithdrawSuccessData &);
    static LnUrlWithdrawSuccessData read(RustStream &);
    static void write(RustStream &, const LnUrlWithdrawSuccessData &);
    static uint64_t allocation_size(const LnUrlWithdrawSuccessData &);
};

struct FfiConverterTypeLogEntry {
    static LogEntry lift(RustBuffer);
    static RustBuffer lower(const LogEntry &);
    static LogEntry read(RustStream &);
    static void write(RustStream &, const LogEntry &);
    static uint64_t allocation_size(const LogEntry &);
};

struct FfiConverterTypeNodeState {
    static NodeState lift(RustBuffer);
    static RustBuffer lower(const NodeState &);
    static NodeState read(RustStream &);
    static void write(RustStream &, const NodeState &);
    static uint64_t allocation_size(const NodeState &);
};

struct FfiConverterTypeOnchainFeeRates {
    static OnchainFeeRates lift(RustBuffer);
    static RustBuffer lower(const OnchainFeeRates &);
    static OnchainFeeRates read(RustStream &);
    static void write(RustStream &, const OnchainFeeRates &);
    static uint64_t allocation_size(const OnchainFeeRates &);
};

struct FfiConverterTypeOnchainReceiveResponse {
    static OnchainReceiveResponse lift(RustBuffer);
    static RustBuffer lower(const OnchainReceiveResponse &);
    static OnchainReceiveResponse read(RustStream &);
    static void write(RustStream &, const OnchainReceiveResponse &);
    static uint64_t allocation_size(const OnchainReceiveResponse &);
};

struct FfiConverterTypeOnchainSendResponse {
    static OnchainSendResponse lift(RustBuffer);
    static RustBuffer lower(const OnchainSendResponse &);
    static OnchainSendResponse read(RustStream &);
    static void write(RustStream &, const OnchainSendResponse &);
    static uint64_t allocation_size(const OnchainSendResponse &);
};

struct FfiConverterTypeOutpoint {
    static Outpoint lift(RustBuffer);
    static RustBuffer lower(const Outpoint &);
    static Outpoint read(RustStream &);
    static void write(RustStream &, const Outpoint &);
    static uint64_t allocation_size(const Outpoint &);
};

struct FfiConverterTypeParsedInvoice {
    static ParsedInvoice lift(RustBuffer);
    static RustBuffer lower(const ParsedInvoice &);
    static ParsedInvoice read(RustStream &);
    static void write(RustStream &, const ParsedInvoice &);
    static uint64_t allocation_size(const ParsedInvoice &);
};

struct FfiConverterTypePay {
    static Pay lift(RustBuffer);
    static RustBuffer lower(const Pay &);
    static Pay read(RustStream &);
    static void write(RustStream &, const Pay &);
    static uint64_t allocation_size(const Pay &);
};

struct FfiConverterTypePayment {
    static Payment lift(RustBuffer);
    static RustBuffer lower(const Payment &);
    static Payment read(RustStream &);
    static void write(RustStream &, const Payment &);
    static uint64_t allocation_size(const Payment &);
};

struct FfiConverterTypePeer {
    static Peer lift(RustBuffer);
    static RustBuffer lower(const Peer &);
    static Peer read(RustStream &);
    static void write(RustStream &, const Peer &);
    static uint64_t allocation_size(const Peer &);
};

struct FfiConverterTypePeerChannel {
    static PeerChannel lift(RustBuffer);
    static RustBuffer lower(const PeerChannel &);
    static PeerChannel read(RustStream &);
    static void write(RustStream &, const PeerChannel &);
    static uint64_t allocation_size(const PeerChannel &);
};

struct FfiConverterTypePreparedOnchainSend {
    static PreparedOnchainSend lift(RustBuffer);
    static RustBuffer lower(const PreparedOnchainSend &);
    static PreparedOnchainSend read(RustStream &);
    static void write(RustStream &, const PreparedOnchainSend &);
    static uint64_t allocation_size(const PreparedOnchainSend &);
};

struct FfiConverterTypeReceiveResponse {
    static ReceiveResponse lift(RustBuffer);
    static RustBuffer lower(const ReceiveResponse &);
    static ReceiveResponse read(RustStream &);
    static void write(RustStream &, const ReceiveResponse &);
    static uint64_t allocation_size(const ReceiveResponse &);
};

struct FfiConverterTypeSendResponse {
    static SendResponse lift(RustBuffer);
    static RustBuffer lower(const SendResponse &);
    static SendResponse read(RustStream &);
    static void write(RustStream &, const SendResponse &);
    static uint64_t allocation_size(const SendResponse &);
};
struct FfiConverterChannelSide {
    static ChannelSide lift(RustBuffer);
    static RustBuffer lower(const ChannelSide &);
    static ChannelSide read(RustStream &);
    static void write(RustStream &, const ChannelSide &);
    static uint64_t allocation_size(const ChannelSide &);
};
struct FfiConverterChannelState {
    static ChannelState lift(RustBuffer);
    static RustBuffer lower(const ChannelState &);
    static ChannelState read(RustStream &);
    static void write(RustStream &, const ChannelState &);
    static uint64_t allocation_size(const ChannelState &);
};

struct FfiConverterError {
    static std::shared_ptr<Error> lift(RustBuffer buf);
    static RustBuffer lower(const Error &);
    static std::shared_ptr<Error> read(RustStream &stream);
    static void write(RustStream &stream, const Error &);
    static uint64_t allocation_size(const Error &);
};
struct FfiConverterInvoiceStatus {
    static InvoiceStatus lift(RustBuffer);
    static RustBuffer lower(const InvoiceStatus &);
    static InvoiceStatus read(RustStream &);
    static void write(RustStream &, const InvoiceStatus &);
    static uint64_t allocation_size(const InvoiceStatus &);
};
struct FfiConverterListIndex {
    static ListIndex lift(RustBuffer);
    static RustBuffer lower(const ListIndex &);
    static ListIndex read(RustStream &);
    static void write(RustStream &, const ListIndex &);
    static uint64_t allocation_size(const ListIndex &);
};
struct FfiConverterLnUrlPayResult {
    static LnUrlPayResult lift(RustBuffer);
    static RustBuffer lower(const LnUrlPayResult &);
    static LnUrlPayResult read(RustStream &);
    static void write(RustStream &, const LnUrlPayResult &);
    static uint64_t allocation_size(const LnUrlPayResult &);
};
struct FfiConverterLnUrlWithdrawResult {
    static LnUrlWithdrawResult lift(RustBuffer);
    static RustBuffer lower(const LnUrlWithdrawResult &);
    static LnUrlWithdrawResult read(RustStream &);
    static void write(RustStream &, const LnUrlWithdrawResult &);
    static uint64_t allocation_size(const LnUrlWithdrawResult &);
};
struct FfiConverterLogLevel {
    static LogLevel lift(RustBuffer);
    static RustBuffer lower(const LogLevel &);
    static LogLevel read(RustStream &);
    static void write(RustStream &, const LogLevel &);
    static uint64_t allocation_size(const LogLevel &);
};
struct FfiConverterNetwork {
    static Network lift(RustBuffer);
    static RustBuffer lower(const Network &);
    static Network read(RustStream &);
    static void write(RustStream &, const Network &);
    static uint64_t allocation_size(const Network &);
};
struct FfiConverterNodeEvent {
    static NodeEvent lift(RustBuffer);
    static RustBuffer lower(const NodeEvent &);
    static NodeEvent read(RustStream &);
    static void write(RustStream &, const NodeEvent &);
    static uint64_t allocation_size(const NodeEvent &);
};
struct FfiConverterOnchainBalanceState {
    static OnchainBalanceState lift(RustBuffer);
    static RustBuffer lower(const OnchainBalanceState &);
    static OnchainBalanceState read(RustStream &);
    static void write(RustStream &, const OnchainBalanceState &);
    static uint64_t allocation_size(const OnchainBalanceState &);
};
struct FfiConverterOutputStatus {
    static OutputStatus lift(RustBuffer);
    static RustBuffer lower(const OutputStatus &);
    static OutputStatus read(RustStream &);
    static void write(RustStream &, const OutputStatus &);
    static uint64_t allocation_size(const OutputStatus &);
};
struct FfiConverterParsedInput {
    static ParsedInput lift(RustBuffer);
    static RustBuffer lower(const ParsedInput &);
    static ParsedInput read(RustStream &);
    static void write(RustStream &, const ParsedInput &);
    static uint64_t allocation_size(const ParsedInput &);
};
struct FfiConverterPayStatus {
    static PayStatus lift(RustBuffer);
    static RustBuffer lower(const PayStatus &);
    static PayStatus read(RustStream &);
    static void write(RustStream &, const PayStatus &);
    static uint64_t allocation_size(const PayStatus &);
};
struct FfiConverterPaymentStatus {
    static PaymentStatus lift(RustBuffer);
    static RustBuffer lower(const PaymentStatus &);
    static PaymentStatus read(RustStream &);
    static void write(RustStream &, const PaymentStatus &);
    static uint64_t allocation_size(const PaymentStatus &);
};
struct FfiConverterPaymentType {
    static PaymentType lift(RustBuffer);
    static RustBuffer lower(const PaymentType &);
    static PaymentType read(RustStream &);
    static void write(RustStream &, const PaymentType &);
    static uint64_t allocation_size(const PaymentType &);
};
struct FfiConverterPaymentTypeFilter {
    static PaymentTypeFilter lift(RustBuffer);
    static RustBuffer lower(const PaymentTypeFilter &);
    static PaymentTypeFilter read(RustStream &);
    static void write(RustStream &, const PaymentTypeFilter &);
    static uint64_t allocation_size(const PaymentTypeFilter &);
};
struct FfiConverterResolvedInput {
    static ResolvedInput lift(RustBuffer);
    static RustBuffer lower(const ResolvedInput &);
    static ResolvedInput read(RustStream &);
    static void write(RustStream &, const ResolvedInput &);
    static uint64_t allocation_size(const ResolvedInput &);
};
struct FfiConverterSuccessActionProcessed {
    static SuccessActionProcessed lift(RustBuffer);
    static RustBuffer lower(const SuccessActionProcessed &);
    static SuccessActionProcessed read(RustStream &);
    static void write(RustStream &, const SuccessActionProcessed &);
    static uint64_t allocation_size(const SuccessActionProcessed &);
};


struct FfiConverterLogListener {
    static std::shared_ptr<LogListener> lift(uint64_t);
    static uint64_t lower(const std::shared_ptr<LogListener> &);
    static std::shared_ptr<LogListener> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<LogListener> &);
    static uint64_t allocation_size(const std::shared_ptr<LogListener> &);

    inline static HandleMap<LogListener> handle_map = {};
};


struct FfiConverterNodeEventListener {
    static std::shared_ptr<NodeEventListener> lift(uint64_t);
    static uint64_t lower(const std::shared_ptr<NodeEventListener> &);
    static std::shared_ptr<NodeEventListener> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<NodeEventListener> &);
    static uint64_t allocation_size(const std::shared_ptr<NodeEventListener> &);

    inline static HandleMap<NodeEventListener> handle_map = {};
};
struct FfiConverterOptionalUInt32 {
    static std::optional<uint32_t> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<uint32_t>& val);
    static std::optional<uint32_t> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<uint32_t>& value);
    static uint64_t allocation_size(const std::optional<uint32_t> &val);
};
struct FfiConverterOptionalUInt64 {
    static std::optional<uint64_t> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<uint64_t>& val);
    static std::optional<uint64_t> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<uint64_t>& value);
    static uint64_t allocation_size(const std::optional<uint64_t> &val);
};
struct FfiConverterOptionalBool {
    static std::optional<bool> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<bool>& val);
    static std::optional<bool> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<bool>& value);
    static uint64_t allocation_size(const std::optional<bool> &val);
};
struct FfiConverterOptionalString {
    static std::optional<std::string> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<std::string>& val);
    static std::optional<std::string> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<std::string>& value);
    static uint64_t allocation_size(const std::optional<std::string> &val);
};
struct FfiConverterOptionalBytes {
    static std::optional<std::vector<uint8_t>> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<std::vector<uint8_t>>& val);
    static std::optional<std::vector<uint8_t>> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<std::vector<uint8_t>>& value);
    static uint64_t allocation_size(const std::optional<std::vector<uint8_t>> &val);
};
struct FfiConverterOptionalChannelSide {
    static std::optional<ChannelSide> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<ChannelSide>& val);
    static std::optional<ChannelSide> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<ChannelSide>& value);
    static uint64_t allocation_size(const std::optional<ChannelSide> &val);
};
struct FfiConverterOptionalListIndex {
    static std::optional<ListIndex> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<ListIndex>& val);
    static std::optional<ListIndex> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<ListIndex>& value);
    static uint64_t allocation_size(const std::optional<ListIndex> &val);
};
struct FfiConverterOptionalNodeEvent {
    static std::optional<NodeEvent> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<NodeEvent>& val);
    static std::optional<NodeEvent> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<NodeEvent>& value);
    static uint64_t allocation_size(const std::optional<NodeEvent> &val);
};
struct FfiConverterOptionalPayStatus {
    static std::optional<PayStatus> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<PayStatus>& val);
    static std::optional<PayStatus> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<PayStatus>& value);
    static uint64_t allocation_size(const std::optional<PayStatus> &val);
};
struct FfiConverterOptionalSuccessActionProcessed {
    static std::optional<SuccessActionProcessed> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<SuccessActionProcessed>& val);
    static std::optional<SuccessActionProcessed> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<SuccessActionProcessed>& value);
    static uint64_t allocation_size(const std::optional<SuccessActionProcessed> &val);
};
struct FfiConverterOptionalSequenceTypeOutpoint {
    static std::optional<std::vector<Outpoint>> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<std::vector<Outpoint>>& val);
    static std::optional<std::vector<Outpoint>> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<std::vector<Outpoint>>& value);
    static uint64_t allocation_size(const std::optional<std::vector<Outpoint>> &val);
};
struct FfiConverterOptionalSequencePaymentTypeFilter {
    static std::optional<std::vector<PaymentTypeFilter>> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<std::vector<PaymentTypeFilter>>& val);
    static std::optional<std::vector<PaymentTypeFilter>> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<std::vector<PaymentTypeFilter>>& value);
    static uint64_t allocation_size(const std::optional<std::vector<PaymentTypeFilter>> &val);
};

struct FfiConverterSequenceString {
    static std::vector<std::string> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::string> &);
    static std::vector<std::string> read(RustStream &);
    static void write(RustStream &, const std::vector<std::string> &);
    static uint64_t allocation_size(const std::vector<std::string> &);
};

struct FfiConverterSequenceTypeFundChannel {
    static std::vector<FundChannel> lift(RustBuffer);
    static RustBuffer lower(const std::vector<FundChannel> &);
    static std::vector<FundChannel> read(RustStream &);
    static void write(RustStream &, const std::vector<FundChannel> &);
    static uint64_t allocation_size(const std::vector<FundChannel> &);
};

struct FfiConverterSequenceTypeFundOutput {
    static std::vector<FundOutput> lift(RustBuffer);
    static RustBuffer lower(const std::vector<FundOutput> &);
    static std::vector<FundOutput> read(RustStream &);
    static void write(RustStream &, const std::vector<FundOutput> &);
    static uint64_t allocation_size(const std::vector<FundOutput> &);
};

struct FfiConverterSequenceTypeInvoice {
    static std::vector<Invoice> lift(RustBuffer);
    static RustBuffer lower(const std::vector<Invoice> &);
    static std::vector<Invoice> read(RustStream &);
    static void write(RustStream &, const std::vector<Invoice> &);
    static uint64_t allocation_size(const std::vector<Invoice> &);
};

struct FfiConverterSequenceTypeOutpoint {
    static std::vector<Outpoint> lift(RustBuffer);
    static RustBuffer lower(const std::vector<Outpoint> &);
    static std::vector<Outpoint> read(RustStream &);
    static void write(RustStream &, const std::vector<Outpoint> &);
    static uint64_t allocation_size(const std::vector<Outpoint> &);
};

struct FfiConverterSequenceTypePay {
    static std::vector<Pay> lift(RustBuffer);
    static RustBuffer lower(const std::vector<Pay> &);
    static std::vector<Pay> read(RustStream &);
    static void write(RustStream &, const std::vector<Pay> &);
    static uint64_t allocation_size(const std::vector<Pay> &);
};

struct FfiConverterSequenceTypePayment {
    static std::vector<Payment> lift(RustBuffer);
    static RustBuffer lower(const std::vector<Payment> &);
    static std::vector<Payment> read(RustStream &);
    static void write(RustStream &, const std::vector<Payment> &);
    static uint64_t allocation_size(const std::vector<Payment> &);
};

struct FfiConverterSequenceTypePeer {
    static std::vector<Peer> lift(RustBuffer);
    static RustBuffer lower(const std::vector<Peer> &);
    static std::vector<Peer> read(RustStream &);
    static void write(RustStream &, const std::vector<Peer> &);
    static uint64_t allocation_size(const std::vector<Peer> &);
};

struct FfiConverterSequenceTypePeerChannel {
    static std::vector<PeerChannel> lift(RustBuffer);
    static RustBuffer lower(const std::vector<PeerChannel> &);
    static std::vector<PeerChannel> read(RustStream &);
    static void write(RustStream &, const std::vector<PeerChannel> &);
    static uint64_t allocation_size(const std::vector<PeerChannel> &);
};

struct FfiConverterSequencePaymentTypeFilter {
    static std::vector<PaymentTypeFilter> lift(RustBuffer);
    static RustBuffer lower(const std::vector<PaymentTypeFilter> &);
    static std::vector<PaymentTypeFilter> read(RustStream &);
    static void write(RustStream &, const std::vector<PaymentTypeFilter> &);
    static uint64_t allocation_size(const std::vector<PaymentTypeFilter> &);
};

struct FfiConverterMapStringString {
    static std::unordered_map<std::string, std::string> lift(RustBuffer);
    static RustBuffer lower(const std::unordered_map<std::string, std::string> &);
    static std::unordered_map<std::string, std::string> read(RustStream &);
    static void write(RustStream &, const std::unordered_map<std::string, std::string> &);
    static uint64_t allocation_size(const std::unordered_map<std::string, std::string> &);
};
} // namespace uniffi

/**
 * Synchronously classify the input. **No HTTP, no I/O.**
 *
 * Recognises BOLT11 invoices, node IDs, LNURL bech32 strings, and
 * Lightning Addresses. Strips `lightning:` / `LIGHTNING:` prefixes
 * automatically. LNURL inputs are decoded to their underlying URL
 * but **not fetched** — the caller chooses whether to resolve
 * further (via `resolve_input`) or to surface the URL to the user
 * as-is.
 *
 * Use this for offline operations like clipboard validation or
 * invoice sanity checks. Use `resolve_input` for the QR-scan flow
 * where you want the resolved pay/withdraw data in one call.
 */
ParsedInput parse_input(const std::string &input);
/**
 * Classify and resolve the input.
 *
 * Internally calls `parse_input` for offline classification, then
 * for LNURL bech32 strings and Lightning Addresses performs the
 * HTTP GET to the LNURL endpoint and returns typed pay or withdraw
 * request data. For BOLT11 invoices and node IDs it returns
 * immediately without I/O.
 *
 * Strips `lightning:` / `LIGHTNING:` prefixes automatically.
 *
 * # Blocking
 *
 * This function blocks the calling thread while any network I/O
 * completes. The SDK exposes a **synchronous-only** public API so
 * that every language binding (Python, Kotlin, Swift, Ruby, C++)
 * works without requiring an async runtime on the caller side.
 * Async work is executed internally on a shared Tokio runtime
 * managed by the SDK.
 */
ResolvedInput resolve_input(const std::string &input);
/**
 * Change the log filter at runtime without reinstalling the listener.
 */
void set_log_level(const LogLevel &level);
/**
 * Set up SDK logging. Call once before any other SDK function.
 *
 * The listener receives all log messages from the SDK and the
 * underlying Greenlight client library. Call once, as early as
 * possible, so early logs are captured. Returns an error if a logger
 * has already been installed in this process. To change the filter
 * after installation, use `set_log_level`.
 */
void set_logger(const LogLevel &level, const std::shared_ptr<LogListener> &listener);
} // namespace glsdk