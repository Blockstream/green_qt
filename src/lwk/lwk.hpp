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

#include "lwk_scaffolding.hpp"

namespace lwk {
struct Address;
struct AddressResult;
struct Amp0;
struct Amp0Connected;
struct Amp0LoggedIn;
struct Amp0Pset;
struct Amp0SignerData;
struct Amp2;
struct Amp2Descriptor;
struct AnyClient;
struct AssetAmount;
struct AssetBlindingFactor;
struct Bip;
struct Bip21;
struct Bip321;
struct BitcoinAddress;
struct BlockHeader;
struct Bolt11Invoice;
struct BoltzSession;
struct Contract;
struct CurrencyCode;
struct ElectrumClient;
struct EsploraClient;
struct ExternalUtxo;
struct ForeignStore;
struct ForeignStoreLink;
struct InvoiceResponse;
struct Issuance;
struct LightningPayment;
struct LockupResponse;
struct Logging;
struct LoggingLink;
struct LwkTestEnv;
struct LwkTestStore;
struct Mnemonic;
struct Network;
struct OutPoint;
struct Payment;
struct PosConfig;
struct Precision;
struct PreparePayResponse;
struct Pset;
struct PsetBalance;
struct PsetDetails;
struct PsetInput;
struct PsetOutput;
struct PsetSignatures;
struct QuoteBuilder;
struct Recipient;
struct Script;
struct SecretKey;
struct Signer;
struct SwapList;
struct Transaction;
struct TxBuilder;
struct TxIn;
struct TxOut;
struct TxOutSecrets;
struct Txid;
struct UnvalidatedLiquidexProposal;
struct Update;
struct ValidatedLiquidexProposal;
struct ValueBlindingFactor;
struct WalletTx;
struct WalletTxOut;
struct WebHook;
struct Wollet;
struct WolletBuilder;
struct WolletDescriptor;
struct BoltzSessionBuilder;
struct EsploraClientBuilder;
struct LiquidBip21;
struct LnUrlPayResponse;
struct Quote;
enum class Chain;
enum class DescriptorBlindingKey;
enum class LogLevel;
struct LwkError;
enum class PaymentKind;
enum class PaymentState;
enum class Singlesig;
enum class SwapAsset;
typedef std::string AssetId;




/**
 * An exported trait for handling logging messages.
 *
 * Implement this trait to receive and handle logging messages from the lightning session.
 */
struct Logging {
    virtual ~Logging() {}
    /**
     * Log a message with the given level
     */
    virtual
    void log(const LogLevel &level, const std::string &message) = 0;
};

namespace uniffi {
    struct UniffiCallbackInterfaceLogging {
        static void log(uint64_t uniffi_handle,RustBuffer level,RustBuffer message,void * uniffi_out_return,RustCallStatus *out_status);

        static void uniffi_free(uint64_t uniffi_handle);
        static void init();
    private:
        static inline UniffiVTableCallbackInterfaceLogging vtable = UniffiVTableCallbackInterfaceLogging {
            .log = reinterpret_cast<void *>(&log),
            .uniffi_free = reinterpret_cast<void *>(&uniffi_free)
        };
    };
}

namespace uniffi {
    struct FfiConverterLogging;
} // namespace uniffi

/**
 * An exported trait for handling logging messages.
 *
 * Implement this trait to receive and handle logging messages from the lightning session.
 */
struct LoggingImpl

 : public Logging 

{
    friend uniffi::FfiConverterLogging;

    LoggingImpl() = delete;

    LoggingImpl(LoggingImpl &&) = delete;

    LoggingImpl &operator=(const LoggingImpl &) = delete;
    LoggingImpl &operator=(LoggingImpl &&) = delete;

    ~LoggingImpl();
    /**
     * Log a message with the given level
     */
    void log(const LogLevel &level, const std::string &message);

    private:
    LoggingImpl(const LoggingImpl &);

    LoggingImpl(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterNetwork;
} // namespace uniffi

/**
 * The network of the elements blockchain.
 */
struct Network



{
    friend uniffi::FfiConverterNetwork;

    Network() = delete;

    Network(Network &&) = delete;

    Network &operator=(const Network &) = delete;
    Network &operator=(Network &&) = delete;

    ~Network();
    /**
     * Return the mainnet network
     */
    static std::shared_ptr<Network> mainnet();
    /**
     * Return the regtest network with the given policy asset
     */
    static std::shared_ptr<Network> regtest(const AssetId &policy_asset);
    /**
     * Return the default regtest network with the default policy asset
     */
    static std::shared_ptr<Network> regtest_default();
    /**
     * Return the testnet network
     */
    static std::shared_ptr<Network> testnet();
    /**
     * Return the default electrum client for this network
     */
    std::shared_ptr<ElectrumClient> default_electrum_client();
    /**
     * Return the default esplora client for this network
     */
    std::shared_ptr<EsploraClient> default_esplora_client();
    /**
     * Return the genesis block hash for this network as hex string.
     */
    std::string genesis_block_hash();
    /**
     * Return true if the network is the mainnet network
     */
    bool is_mainnet();
    /**
     * Return the policy asset (eg LBTC for mainnet) for this network
     */
    AssetId policy_asset();
    /**
     * Return a new `TxBuilder` for this network
     */
    std::shared_ptr<TxBuilder> tx_builder();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;
    /**
     * Equality check, internally calls Rust's `Eq` trait.
     */
    bool eq(const std::shared_ptr<Network> &other) const;
    /**
     * Inequality check, internally calls Rust's `Ne` trait.
     */
    bool ne(const std::shared_ptr<Network> &other) const;
    /**
     * Returns a hash of the object, internally calls Rust's `Hash` trait.
     */
    uint64_t hash() const;

    private:
    Network(const Network &);

    Network(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterMnemonic;
} // namespace uniffi

/**
 * Wrapper over [`bip39::Mnemonic`]
 */
struct Mnemonic



{
    friend uniffi::FfiConverterMnemonic;

    Mnemonic() = delete;

    Mnemonic(Mnemonic &&) = delete;

    Mnemonic &operator=(const Mnemonic &) = delete;
    Mnemonic &operator=(Mnemonic &&) = delete;

    ~Mnemonic();
    /**
     * Construct a Mnemonic type
     */
    static std::shared_ptr<Mnemonic> init(const std::string &s);
    /**
     * Creates a Mnemonic from entropy, at least 16 bytes are needed.
     */
    static std::shared_ptr<Mnemonic> from_entropy(const std::vector<uint8_t> &b);
    /**
     * Creates a random Mnemonic of given words (12,15,18,21,24)
     */
    static std::shared_ptr<Mnemonic> from_random(uint8_t word_count);
    /**
     * Get the number of words in this mnemonic
     */
    uint8_t word_count();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    Mnemonic(const Mnemonic &);

    Mnemonic(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterAddress;
} // namespace uniffi

/**
 * A Liquid address
 */
struct Address



{
    friend uniffi::FfiConverterAddress;

    Address() = delete;

    Address(Address &&) = delete;

    Address &operator=(const Address &) = delete;
    Address &operator=(Address &&) = delete;

    ~Address();
    /**
     * Construct an Address object
     */
    static std::shared_ptr<Address> init(const std::string &s);
    /**
     * Return true if the address is blinded.
     */
    bool is_blinded();
    /**
     * Returns the network of the address
     */
    std::shared_ptr<Network> network();
    /**
     * Returns a string of the QR code printable in a terminal environment
     */
    std::string qr_code_text();
    /**
     * Returns a string encoding an image in a uri
     *
     * The string can be open in the browser or be used as `src` field in `img` in HTML
     *
     * For max efficiency we suggest to pass `None` to `pixel_per_module`, get a very small image
     * and use styling to scale up the image in the browser. eg
     * `style="image-rendering: pixelated; border: 20px solid white;"`
     */
    std::string qr_code_uri(std::optional<uint8_t> pixel_per_module);
    /**
     * Return the script pubkey of the address.
     */
    std::shared_ptr<Script> script_pubkey();
    /**
     * Return the unconfidential address.
     */
    std::shared_ptr<Address> to_unconfidential();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    Address(const Address &);

    Address(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterAnyClient;
} // namespace uniffi

struct AnyClient



{
    friend uniffi::FfiConverterAnyClient;

    AnyClient() = delete;

    AnyClient(AnyClient &&) = delete;

    AnyClient &operator=(const AnyClient &) = delete;
    AnyClient &operator=(AnyClient &&) = delete;

    ~AnyClient();
    static std::shared_ptr<AnyClient> from_electrum(const std::shared_ptr<ElectrumClient> &client);
    static std::shared_ptr<AnyClient> from_esplora(const std::shared_ptr<EsploraClient> &client);

    private:
    AnyClient(const AnyClient &);

    AnyClient(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterForeignStoreLink;
} // namespace uniffi

/**
 * A bridge that connects a [`ForeignStore`] to [`lwk_common::Store`].
 */
struct ForeignStoreLink



{
    friend uniffi::FfiConverterForeignStoreLink;

    ForeignStoreLink() = delete;

    ForeignStoreLink(ForeignStoreLink &&) = delete;

    ForeignStoreLink &operator=(const ForeignStoreLink &) = delete;
    ForeignStoreLink &operator=(ForeignStoreLink &&) = delete;

    ~ForeignStoreLink();
    /**
     * Create a new `ForeignStoreLink` from a foreign store implementation.
     */
    static std::shared_ptr<ForeignStoreLink> init(const std::shared_ptr<ForeignStore> &store);

    private:
    ForeignStoreLink(const ForeignStoreLink &);

    ForeignStoreLink(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


/**
 * A builder for the `EsploraClient`
 */
struct EsploraClientBuilder {
    std::string base_url;
    std::shared_ptr<Network> network;
    bool waterfalls = false;
    std::optional<uint32_t> concurrency = std::nullopt;
    std::optional<uint8_t> timeout = std::nullopt;
    bool utxo_only = false;
};


/**
 * A builder for the `BoltzSession`
 */
struct BoltzSessionBuilder {
    std::shared_ptr<Network> network;
    std::shared_ptr<AnyClient> client;
    std::optional<uint64_t> timeout = std::nullopt;
    std::shared_ptr<Mnemonic> mnemonic = nullptr;
    std::shared_ptr<Logging> logging = nullptr;
    bool polling = false;
    std::optional<uint64_t> timeout_advance = std::nullopt;
    std::optional<uint32_t> next_index_to_use = std::nullopt;
    std::optional<std::string> referral_id = std::nullopt;
    /**
     * Optional Boltz API base URL override.
     *
     * The caller is responsible for ensuring the provider behind this URL matches `network`.
     *
     * If this is used together with `store`, the caller must use a different store per provider.
     * Persisted swap data is not namespaced by provider, so reusing the same store across
     * different `api_url` values can mix swaps from different providers.
     */
    std::optional<std::string> api_url = std::nullopt;
    std::optional<std::string> bitcoin_electrum_client_url = std::nullopt;
    bool random_preimages = false;
    /**
     * Optional store for persisting swap data
     *
     * When set, swap data will be automatically persisted to the store after creation
     * and on each state change. This enables automatic restoration of pending swaps.
     *
     * The store is not namespaced by provider, so if different `api_url` values are used the
     * caller must use a different store per provider to avoid mixing swaps from different
     * providers.
     */
    std::shared_ptr<ForeignStoreLink> store = nullptr;
};


/**
 * Liquid BIP21 payment details
 */
struct LiquidBip21 {
    /**
     * The Liquid address
     */
    std::shared_ptr<Address> address;
    /**
     * The asset identifier
     */
    AssetId asset;
    /**
     * The amount in satoshis
     */
    std::optional<uint64_t> satoshi;
};


namespace uniffi {
    struct FfiConverterAddressResult;
} // namespace uniffi

/**
 * Value returned from asking an address to the wallet.
 * Containing the confidential address and its
 * derivation index (the last element in the derivation path)
 */
struct AddressResult



{
    friend uniffi::FfiConverterAddressResult;

    AddressResult() = delete;

    AddressResult(AddressResult &&) = delete;

    AddressResult &operator=(const AddressResult &) = delete;
    AddressResult &operator=(AddressResult &&) = delete;

    ~AddressResult();
    /**
     * Return the address.
     */
    std::shared_ptr<Address> address();
    /**
     * Return the derivation index of the address.
     */
    uint32_t index();

    private:
    AddressResult(const AddressResult &);

    AddressResult(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterAmp0;
} // namespace uniffi

/**
 * Context for actions related to an AMP0 (sub)account
 */
struct Amp0



{
    friend uniffi::FfiConverterAmp0;

    Amp0() = delete;

    Amp0(Amp0 &&) = delete;

    Amp0 &operator=(const Amp0 &) = delete;
    Amp0 &operator=(Amp0 &&) = delete;

    ~Amp0();
    /**
     * Construct an AMP0 context
     */
    static std::shared_ptr<Amp0> init(const std::shared_ptr<Network> &network, const std::string &username, const std::string &password, const std::string &amp_id);
    /**
     * Get an address
     *
     * If `index` is None, a new address is returned.
     */
    std::shared_ptr<AddressResult> address(std::optional<uint32_t> index);
    /**
     * AMP ID
     */
    std::string amp_id();
    /**
     * Index of the last returned address
     */
    uint32_t last_index();
    /**
     * Ask AMP0 server to cosign
     */
    std::shared_ptr<Transaction> sign(const std::shared_ptr<Amp0Pset> &pset);
    /**
     * Wollet descriptor
     */
    std::shared_ptr<WolletDescriptor> wollet_descriptor();

    private:
    Amp0(const Amp0 &);

    Amp0(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterAmp0Connected;
} // namespace uniffi

/**
 * Session connecting to AMP0
 */
struct Amp0Connected



{
    friend uniffi::FfiConverterAmp0Connected;

    Amp0Connected() = delete;

    Amp0Connected(Amp0Connected &&) = delete;

    Amp0Connected &operator=(const Amp0Connected &) = delete;
    Amp0Connected &operator=(Amp0Connected &&) = delete;

    ~Amp0Connected();
    /**
     * Connect and register to AMP0
     */
    static std::shared_ptr<Amp0Connected> init(const std::shared_ptr<Network> &network, const std::shared_ptr<Amp0SignerData> &signer_data);
    /**
     * Obtain a login challenge
     *
     * This must be signed with [`Signer::amp0_sign_challenge()`].
     */
    std::string get_challenge();
    /**
     * Log in
     *
     * `sig` must be obtained from [`Signer::amp0_sign_challenge()`] called with the value returned
     * by [`Amp0Connected::get_challenge()`]
     */
    std::shared_ptr<Amp0LoggedIn> login(const std::string &sig);

    private:
    Amp0Connected(const Amp0Connected &);

    Amp0Connected(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterAmp0LoggedIn;
} // namespace uniffi

/**
 * Session logged in AMP0
 */
struct Amp0LoggedIn



{
    friend uniffi::FfiConverterAmp0LoggedIn;

    Amp0LoggedIn() = delete;

    Amp0LoggedIn(Amp0LoggedIn &&) = delete;

    Amp0LoggedIn &operator=(const Amp0LoggedIn &) = delete;
    Amp0LoggedIn &operator=(Amp0LoggedIn &&) = delete;

    ~Amp0LoggedIn();
    /**
     * Create a new AMP0 account
     *
     * `account_xpub` must be obtained from [`Signer::amp0_account_xpub()`] called with the value obtained from
     * [`Amp0LoggedIn::next_account()`]
     */
    std::string create_amp0_account(uint32_t pointer, const std::string &account_xpub);
    /**
     * Create a new Watch-Only entry for this wallet
     */
    void create_watch_only(const std::string &username, const std::string &password);
    /**
     * List of AMP IDs.
     */
    std::vector<std::string> get_amp_ids();
    /**
     * Get the next account for AMP0 account creation
     *
     * This must be given to [`Signer::amp0_account_xpub()`] to obtain the xpub to pass to
     * [`Amp0LoggedIn::create_amp0_account()`]
     */
    uint32_t next_account();

    private:
    Amp0LoggedIn(const Amp0LoggedIn &);

    Amp0LoggedIn(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterAmp0Pset;
} // namespace uniffi

/**
 * A PSET to use with AMP0
 */
struct Amp0Pset



{
    friend uniffi::FfiConverterAmp0Pset;

    Amp0Pset() = delete;

    Amp0Pset(Amp0Pset &&) = delete;

    Amp0Pset &operator=(const Amp0Pset &) = delete;
    Amp0Pset &operator=(Amp0Pset &&) = delete;

    ~Amp0Pset();
    /**
     * Construct a PSET to use with AMP0
     */
    static std::shared_ptr<Amp0Pset> init(const std::shared_ptr<Pset> &pset, const std::vector<std::string> &blinding_nonces);
    /**
     * Get blinding nonces
     */
    std::vector<std::string> blinding_nonces();
    /**
     * Get the PSET
     */
    std::shared_ptr<Pset> pset();

    private:
    Amp0Pset(const Amp0Pset &);

    Amp0Pset(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterAmp0SignerData;
} // namespace uniffi

/**
 * Signer information necessary for full login to AMP0
 */
struct Amp0SignerData



{
    friend uniffi::FfiConverterAmp0SignerData;

    Amp0SignerData() = delete;

    Amp0SignerData(Amp0SignerData &&) = delete;

    Amp0SignerData &operator=(const Amp0SignerData &) = delete;
    Amp0SignerData &operator=(Amp0SignerData &&) = delete;

    ~Amp0SignerData();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    Amp0SignerData(const Amp0SignerData &);

    Amp0SignerData(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterAmp2;
} // namespace uniffi

/**
 * Wrapper over [`lwk_wollet::amp2::Amp2`]
 */
struct Amp2



{
    friend uniffi::FfiConverterAmp2;

    Amp2() = delete;

    Amp2(Amp2 &&) = delete;

    Amp2 &operator=(const Amp2 &) = delete;
    Amp2 &operator=(Amp2 &&) = delete;

    ~Amp2();
    /**
     * Create a new AMP2 client
     *
     * * `server_key` - The keyorigin xpub of the AMP2 server key
     * * `url` - The URL of the AMP2 server
     */
    static std::shared_ptr<Amp2> init(const std::string &server_key, const std::string &url);
    /**
     * Construct an AMP2 context for Liquid Testnet
     */
    static std::shared_ptr<Amp2> new_testnet();
    /**
     * Ask the AMP2 server to cosign a PSET
     */
    std::shared_ptr<Pset> cosign(const std::shared_ptr<Pset> &pset);
    /**
     * Create an AMP2 wallet descriptor from the keyorigin xpub of a signer
     */
    std::shared_ptr<Amp2Descriptor> descriptor_from_str(const std::string &keyorigin_xpub, const std::string &descriptor_blinding_key);
    /**
     * Register an AMP2 wallet with the AMP2 server
     */
    std::string register_wallet(const std::shared_ptr<Amp2Descriptor> &desc);

    private:
    Amp2(const Amp2 &);

    Amp2(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterAmp2Descriptor;
} // namespace uniffi

/**
 * Wrapper over [`lwk_wollet::amp2::Amp2Descriptor`]
 */
struct Amp2Descriptor



{
    friend uniffi::FfiConverterAmp2Descriptor;

    Amp2Descriptor() = delete;

    Amp2Descriptor(Amp2Descriptor &&) = delete;

    Amp2Descriptor &operator=(const Amp2Descriptor &) = delete;
    Amp2Descriptor &operator=(Amp2Descriptor &&) = delete;

    ~Amp2Descriptor();
    std::shared_ptr<WolletDescriptor> descriptor();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    Amp2Descriptor(const Amp2Descriptor &);

    Amp2Descriptor(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterAssetAmount;
} // namespace uniffi

/**
 * An asset identifier and an amount
 */
struct AssetAmount



{
    friend uniffi::FfiConverterAssetAmount;

    AssetAmount() = delete;

    AssetAmount(AssetAmount &&) = delete;

    AssetAmount &operator=(const AssetAmount &) = delete;
    AssetAmount &operator=(AssetAmount &&) = delete;

    ~AssetAmount();
    /**
     * Return the amount of the asset
     */
    uint64_t amount();
    /**
     * Return the asset of the amount
     */
    AssetId asset();

    private:
    AssetAmount(const AssetAmount &);

    AssetAmount(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterAssetBlindingFactor;
} // namespace uniffi

/**
 * A blinding factor for asset commitments.
 */
struct AssetBlindingFactor



{
    friend uniffi::FfiConverterAssetBlindingFactor;

    AssetBlindingFactor() = delete;

    AssetBlindingFactor(AssetBlindingFactor &&) = delete;

    AssetBlindingFactor &operator=(const AssetBlindingFactor &) = delete;
    AssetBlindingFactor &operator=(AssetBlindingFactor &&) = delete;

    ~AssetBlindingFactor();
    /**
     * Create from bytes.
     */
    static std::shared_ptr<AssetBlindingFactor> from_bytes(const std::vector<uint8_t> &bytes);
    /**
     * Creates from a hex string.
     */
    static std::shared_ptr<AssetBlindingFactor> from_string(const std::string &s);
    /**
     * Get a unblinded/zero asset blinding factor
     */
    static std::shared_ptr<AssetBlindingFactor> zero();
    /**
     * Returns the bytes (32 bytes).
     */
    std::vector<uint8_t> to_bytes();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    AssetBlindingFactor(const AssetBlindingFactor &);

    AssetBlindingFactor(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterBip;
} // namespace uniffi

/**
 * wrapper over [`lwk_common::Bip`]
 */
struct Bip



{
    friend uniffi::FfiConverterBip;

    Bip() = delete;

    Bip(Bip &&) = delete;

    Bip &operator=(const Bip &) = delete;
    Bip &operator=(Bip &&) = delete;

    ~Bip();
    /**
     * For P2SH-P2WPKH wallets
     */
    static std::shared_ptr<Bip> new_bip49();
    /**
     * For P2WPKH wallets
     */
    static std::shared_ptr<Bip> new_bip84();
    /**
     * For multisig wallets
     */
    static std::shared_ptr<Bip> new_bip87();

    private:
    Bip(const Bip &);

    Bip(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterBip21;
} // namespace uniffi

/**
 * A parsed Bitcoin BIP21 URI with optional parameters.
 *
 * BIP21 URIs have the format: `bitcoin:<address>?amount=<amount>&label=<label>&message=<message>`
 * They can also include lightning parameters like `lightning=<bolt11>` or `lno=<bolt12>`.
 */
struct Bip21



{
    friend uniffi::FfiConverterBip21;

    Bip21() = delete;

    Bip21(Bip21 &&) = delete;

    Bip21 &operator=(const Bip21 &) = delete;
    Bip21 &operator=(Bip21 &&) = delete;

    ~Bip21();
    /**
     * Parse a BIP21 URI string
     */
    static std::shared_ptr<Bip21> init(const std::string &s);
    /**
     * Returns the Bitcoin address from the BIP21 URI
     */
    std::shared_ptr<BitcoinAddress> address();
    /**
     * Returns the amount in satoshis if present
     */
    std::optional<uint64_t> amount();
    /**
     * Returns the original URI string
     */
    std::string as_str();
    /**
     * Returns the label if present
     */
    std::optional<std::string> label();
    /**
     * Returns the lightning BOLT11 invoice as a string if present
     */
    std::shared_ptr<Bolt11Invoice> lightning();
    /**
     * Returns the message if present
     */
    std::optional<std::string> message();
    /**
     * Returns the BOLT12 offer as a string if present
     */
    std::optional<std::string> offer();
    /**
     * Returns the payjoin endpoint URL if present
     */
    std::optional<std::string> payjoin();
    /**
     * Returns whether payjoin output substitution is allowed (defaults to true if absent)
     */
    bool payjoin_output_substitution();
    /**
     * Returns the silent payment address (BIP-352) if present
     */
    std::optional<std::string> silent_payment_address();

    private:
    Bip21(const Bip21 &);

    Bip21(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterBip321;
} // namespace uniffi

/**
 * A parsed Bitcoin BIP321 URI with optional parameters.
 *
 * BIP321 extends BIP21 by allowing URIs without a bitcoin address in the path,
 * as long as there is at least one payment instruction in the query parameters.
 *
 * For example: `bitcoin:?ark=ark1qq...&amount=0.00000222`
 */
struct Bip321



{
    friend uniffi::FfiConverterBip321;

    Bip321() = delete;

    Bip321(Bip321 &&) = delete;

    Bip321 &operator=(const Bip321 &) = delete;
    Bip321 &operator=(Bip321 &&) = delete;

    ~Bip321();
    /**
     * Parse a BIP321 URI string
     */
    static std::shared_ptr<Bip321> init(const std::string &s);
    /**
     * Returns the amount in satoshis if present
     */
    std::optional<uint64_t> amount();
    /**
     * Returns the ark address if present
     */
    std::optional<std::string> ark();
    /**
     * Returns the original URI string
     */
    std::string as_str();
    /**
     * Returns the label if present
     */
    std::optional<std::string> label();
    /**
     * Returns the lightning BOLT11 invoice as a string if present
     */
    std::shared_ptr<Bolt11Invoice> lightning();
    /**
     * Returns the message if present
     */
    std::optional<std::string> message();
    /**
     * Returns the BOLT12 offer as a string if present
     */
    std::optional<std::string> offer();
    /**
     * Returns the payjoin endpoint URL if present
     */
    std::optional<std::string> payjoin();
    /**
     * Returns whether payjoin output substitution is allowed (defaults to true if absent)
     */
    bool payjoin_output_substitution();
    /**
     * Returns the silent payment address (BIP-352) if present
     */
    std::optional<std::string> silent_payment_address();

    private:
    Bip321(const Bip321 &);

    Bip321(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterBitcoinAddress;
} // namespace uniffi

/**
 * A valid Bitcoin address
 */
struct BitcoinAddress



{
    friend uniffi::FfiConverterBitcoinAddress;

    BitcoinAddress() = delete;

    BitcoinAddress(BitcoinAddress &&) = delete;

    BitcoinAddress &operator=(const BitcoinAddress &) = delete;
    BitcoinAddress &operator=(BitcoinAddress &&) = delete;

    ~BitcoinAddress();
    /**
     * Construct an Address object
     */
    static std::shared_ptr<BitcoinAddress> init(const std::string &s);
    /**
     * Returns the network of the address
     */
    bool is_mainnet();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    BitcoinAddress(const BitcoinAddress &);

    BitcoinAddress(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterBlockHeader;
} // namespace uniffi

/**
 * Wrapper over [`elements::BlockHeader`]
 */
struct BlockHeader



{
    friend uniffi::FfiConverterBlockHeader;

    BlockHeader() = delete;

    BlockHeader(BlockHeader &&) = delete;

    BlockHeader &operator=(const BlockHeader &) = delete;
    BlockHeader &operator=(BlockHeader &&) = delete;

    ~BlockHeader();
    /**
     * Get the block hash
     */
    std::string block_hash();
    /**
     * Get the block height
     */
    uint32_t height();
    /**
     * Get the merkle root
     */
    std::string merkle_root();
    /**
     * Get the previous block hash
     */
    std::string prev_blockhash();
    /**
     * Get the block timestamp
     */
    uint32_t time();
    /**
     * Get the block version
     */
    uint32_t version();

    private:
    BlockHeader(const BlockHeader &);

    BlockHeader(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterBolt11Invoice;
} // namespace uniffi

/**
 * Represents a syntactically and semantically correct lightning BOLT11 invoice.
 */
struct Bolt11Invoice



{
    friend uniffi::FfiConverterBolt11Invoice;

    Bolt11Invoice() = delete;

    Bolt11Invoice(Bolt11Invoice &&) = delete;

    Bolt11Invoice &operator=(const Bolt11Invoice &) = delete;
    Bolt11Invoice &operator=(Bolt11Invoice &&) = delete;

    ~Bolt11Invoice();
    /**
     * Construct a Bolt11Invoice from a string
     */
    static std::shared_ptr<Bolt11Invoice> init(const std::string &s);
    /**
     * Returns the amount in millisatoshis if present, None if it's an "any amount" invoice
     */
    std::optional<uint64_t> amount_milli_satoshis();
    /**
     * Returns the expiry time in seconds (default is 3600 seconds / 1 hour if not specified)
     */
    uint64_t expiry_time();
    /**
     * Returns the invoice description as a string
     */
    std::string invoice_description();
    /**
     * Returns the minimum CLTV expiry delta
     */
    uint64_t min_final_cltv_expiry_delta();
    /**
     * Returns the network (bitcoin, testnet, signet, regtest)
     */
    std::string network();
    /**
     * Returns the payee's public key if present as a hex string
     */
    std::optional<std::string> payee_pub_key();
    /**
     * Returns the payment hash as a hex string
     */
    std::string payment_hash();
    /**
     * Returns the payment secret as a debug string
     */
    std::string payment_secret();
    /**
     * Returns the invoice timestamp as seconds since Unix epoch
     */
    uint64_t timestamp();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    Bolt11Invoice(const Bolt11Invoice &);

    Bolt11Invoice(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterBoltzSession;
} // namespace uniffi

/**
 * A session to pay and receive lightning payments.
 *
 * Lightning payments are done via LBTC swaps using Boltz.
 *
 * See `BoltzSessionBuilder` for various options to configure the session.
 */
struct BoltzSession



{
    friend uniffi::FfiConverterBoltzSession;

    BoltzSession() = delete;

    BoltzSession(BoltzSession &&) = delete;

    BoltzSession &operator=(const BoltzSession &) = delete;
    BoltzSession &operator=(BoltzSession &&) = delete;

    ~BoltzSession();
    /**
     * Create the lightning session with default settings
     *
     * This uses default timeout and generates a random mnemonic.
     * For custom configuration, use [`BoltzSession::from_builder()`] instead.
     */
    static std::shared_ptr<BoltzSession> init(const std::shared_ptr<Network> &network, const std::shared_ptr<AnyClient> &client);
    /**
     * Create the lightning session from a builder
     */
    static std::shared_ptr<BoltzSession> from_builder(const BoltzSessionBuilder &builder);
    /**
     * Create an onchain swap to convert BTC to LBTC
     */
    std::shared_ptr<LockupResponse> btc_to_lbtc(uint64_t amount, const std::shared_ptr<BitcoinAddress> &refund_address, const std::shared_ptr<Address> &claim_address, std::shared_ptr<WebHook> webhook);
    /**
     * Get the list of completed swap IDs from the store
     *
     * Returns an error if no store is configured.
     */
    std::vector<std::string> completed_swap_ids();
    /**
     * Fetch informations, such as min and max amounts, about the reverse and submarine pairs from the boltz api.
     */
    std::string fetch_swaps_info();
    /**
     * Get the raw swap data (JSON) for a specific swap ID from the store
     *
     * Returns `None` if no store is configured or the swap doesn't exist.
     */
    std::optional<std::string> get_swap_data(const std::string &swap_id);
    /**
     * Create a new invoice for a given amount and a claim address to receive the payment
     */
    std::shared_ptr<InvoiceResponse> invoice(uint64_t amount, std::optional<std::string> description, const std::shared_ptr<Address> &claim_address, std::shared_ptr<WebHook> webhook);
    /**
     * Create an onchain swap to convert LBTC to BTC
     */
    std::shared_ptr<LockupResponse> lbtc_to_btc(uint64_t amount, const std::shared_ptr<Address> &refund_address, const std::shared_ptr<BitcoinAddress> &claim_address, std::shared_ptr<WebHook> webhook);
    /**
     * Get the next index to use for deriving keypairs
     */
    uint32_t next_index_to_use();
    /**
     * Get the list of pending swap IDs from the store
     *
     * Returns an error if no store is configured.
     */
    std::vector<std::string> pending_swap_ids();
    /**
     * Prepare to pay a bolt11 invoice
     */
    std::shared_ptr<PreparePayResponse> prepare_pay(const std::shared_ptr<LightningPayment> &lightning_payment, const std::shared_ptr<Address> &refund_address, std::shared_ptr<WebHook> webhook);
    /**
     * Create a quote builder for calculating swap fees
     *
     * This uses the cached pairs data from session initialization.
     *
     * # Example
     * ```ignore
     * let builder = session.quote(25000);
     * builder.send(SwapAsset::Lightning);
     * builder.receive(SwapAsset::Liquid);
     * let quote = builder.build()?;
     * ```
     */
    std::shared_ptr<QuoteBuilder> quote(uint64_t send_amount);
    /**
     * Create a quote builder for calculating send amount from desired receive amount
     *
     * This is the inverse of [`BoltzSession::quote()`] - given the amount you want
     * to receive, it calculates how much you need to send.
     *
     * # Example
     * ```ignore
     * let builder = session.quote_receive(24887);
     * builder.send(SwapAsset::Lightning);
     * builder.receive(SwapAsset::Liquid);
     * let quote = builder.build()?;
     * // quote.send_amount will be 25000
     * ```
     */
    std::shared_ptr<QuoteBuilder> quote_receive(uint64_t receive_amount);
    /**
     * Refresh the cached pairs data from the Boltz API
     *
     * This updates the internal cache used by [`BoltzSession::quote()`].
     * Call this if you need up-to-date fee information after the session was created.
     */
    void refresh_swap_info();
    /**
     * Remove a swap from the store
     *
     * Returns an error if no store is configured.
     */
    void remove_swap(const std::string &swap_id);
    /**
     * Generate a rescue file with lightning session mnemonic.
     *
     * The rescue file is a JSON file that contains the swaps mnemonic.
     * It can be used on the Boltz web app to bring non terminated swaps to completition.
     */
    std::string rescue_file();
    /**
     * From the swaps returned by the boltz api via [`BoltzSession::swap_restore`]:
     *
     * - filter the BTC to LBTC swaps
     * - add information from the session
     * - return typed data
     *
     * The claim and refund addresses don't need to be the same used when creating the swap.
     */
    std::vector<std::string> restorable_btc_to_lbtc_swaps(const std::shared_ptr<SwapList> &swap_list, const std::shared_ptr<Address> &claim_address, const std::shared_ptr<BitcoinAddress> &refund_address);
    /**
     * From the swaps returned by the boltz api via [`BoltzSession::swap_restore`]:
     *
     * - filter the LBTC to BTC swaps
     * - add information from the session
     * - return typed data
     *
     * The claim and refund addresses don't need to be the same used when creating the swap.
     */
    std::vector<std::string> restorable_lbtc_to_btc_swaps(const std::shared_ptr<SwapList> &swap_list, const std::shared_ptr<BitcoinAddress> &claim_address, const std::shared_ptr<Address> &refund_address);
    /**
     * From the swaps returned by the boltz api via [`BoltzSession::swap_restore`]:
     *
     * - filter the reverse swaps
     * - add information from the session
     * - return typed data
     *
     * The claim address doesn't need to be the same used when creating the swap.
     */
    std::vector<std::string> restorable_reverse_swaps(const std::shared_ptr<SwapList> &swap_list, const std::shared_ptr<Address> &claim_address);
    /**
     * From the swaps returned by the boltz api via [`BoltzSession::swap_restore`]:
     *
     * - filter the submarine swaps
     * - add information from the session
     * - return typed data
     *
     * The refund address doesn't need to be the same used when creating the swap.
     */
    std::vector<std::string> restorable_submarine_swaps(const std::shared_ptr<SwapList> &swap_list, const std::shared_ptr<Address> &refund_address);
    /**
     * Restore an invoice flow from its serialized data see `InvoiceResponse::serialize`
     */
    std::shared_ptr<InvoiceResponse> restore_invoice(const std::string &data);
    /**
     * Restore an onchain swap from its serialized data see `LockupResponse::serialize`
     */
    std::shared_ptr<LockupResponse> restore_lockup(const std::string &data);
    /**
     * Restore a payment from its serialized data see `PreparePayResponse::serialize`
     */
    std::shared_ptr<PreparePayResponse> restore_prepare_pay(const std::string &data);
    /**
     * Set the next index to use for deriving keypairs
     *
     * This may be necessary to handle multiple sessions with the same mnemonic.
     */
    void set_next_index_to_use(uint32_t next_index_to_use);
    /**
     * Returns a the list of all the swaps ever done with the session mnemonic.
     *
     * The object returned can be converted to a json String with toString()
     */
    std::shared_ptr<SwapList> swap_restore();

    private:
    BoltzSession(const BoltzSession &);

    BoltzSession(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterContract;
} // namespace uniffi

/**
 * Wrapper over [`lwk_wollet::Contract`]
 */
struct Contract



{
    friend uniffi::FfiConverterContract;

    Contract() = delete;

    Contract(Contract &&) = delete;

    Contract &operator=(const Contract &) = delete;
    Contract &operator=(Contract &&) = delete;

    ~Contract();
    /**
     * Construct a Contract object
     */
    static std::shared_ptr<Contract> init(const std::string &domain, const std::string &issuer_pubkey, const std::string &name, uint8_t precision, const std::string &ticker, uint8_t version);
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    Contract(const Contract &);

    Contract(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterCurrencyCode;
} // namespace uniffi

/**
 * Currency code as defined by ISO 4217
 */
struct CurrencyCode



{
    friend uniffi::FfiConverterCurrencyCode;

    CurrencyCode() = delete;

    CurrencyCode(CurrencyCode &&) = delete;

    CurrencyCode &operator=(const CurrencyCode &) = delete;
    CurrencyCode &operator=(CurrencyCode &&) = delete;

    ~CurrencyCode();
    /**
     * Create a CurrencyCode from an alpha3 code (e.g., "USD", "EUR")
     */
    static std::shared_ptr<CurrencyCode> init(const std::string &alpha3);
    /**
     * Get the alpha3 code (e.g., "USD")
     */
    std::string alpha3();
    /**
     * Get the number of decimals for this currency
     */
    int8_t exp();
    /**
     * Get the currency name (e.g., "US Dollar")
     */
    std::string name();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;
    /**
     * Equality check, internally calls Rust's `Eq` trait.
     */
    bool eq(const std::shared_ptr<CurrencyCode> &other) const;
    /**
     * Inequality check, internally calls Rust's `Ne` trait.
     */
    bool ne(const std::shared_ptr<CurrencyCode> &other) const;
    /**
     * Returns a hash of the object, internally calls Rust's `Hash` trait.
     */
    uint64_t hash() const;

    private:
    CurrencyCode(const CurrencyCode &);

    CurrencyCode(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterElectrumClient;
} // namespace uniffi

/**
 * A client to issue TCP requests to an electrum server.
 */
struct ElectrumClient



{
    friend uniffi::FfiConverterElectrumClient;

    ElectrumClient() = delete;

    ElectrumClient(ElectrumClient &&) = delete;

    ElectrumClient &operator=(const ElectrumClient &) = delete;
    ElectrumClient &operator=(ElectrumClient &&) = delete;

    ~ElectrumClient();
    /**
     * Construct an Electrum client
     */
    static std::shared_ptr<ElectrumClient> init(const std::string &electrum_url, bool tls, bool validate_domain);
    /**
     * Construct an electrum client from an Electrum URL
     */
    static std::shared_ptr<ElectrumClient> from_url(const std::string &electrum_url);
    /**
     * Broadcast a transaction to the network so that a miner can include it in a block.
     */
    std::shared_ptr<Txid> broadcast(const std::shared_ptr<Transaction> &tx);
    /**
     * Scan the blockchain for the scripts generated by a watch-only wallet
     *
     * This method scans both external and internal address chains, stopping after finding
     * 20 consecutive unused addresses (the gap limit) as recommended by
     * [BIP44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki#address-gap-limit).
     *
     * Returns `Some(Update)` if any changes were found during scanning, or `None` if no changes
     * were detected.
     *
     * To scan beyond the gap limit use `full_scan_to_index()` instead.
     */
    std::shared_ptr<Update> full_scan(const std::shared_ptr<Wollet> &wollet);
    /**
     * Scan the blockchain for the scripts generated by a watch-only wallet up to a specified derivation index
     *
     * While `full_scan()` stops after finding 20 consecutive unused addresses (the gap limit),
     * this method will scan at least up to the given derivation index. This is useful to prevent
     * missing funds in cases where outputs exist beyond the gap limit.
     *
     * Will scan both external and internal address chains up to the given index for maximum safety,
     * even though internal addresses may not need such deep scanning.
     *
     * If transactions are found beyond the gap limit during this scan, subsequent calls to
     * `full_scan()` will automatically scan up to the highest used index, preventing any
     * previously-found transactions from being missed.
     */
    std::shared_ptr<Update> full_scan_to_index(const std::shared_ptr<Wollet> &wollet, uint32_t index);
    /**
     * Fetch the transaction with the given id
     */
    std::shared_ptr<Transaction> get_tx(const std::shared_ptr<Txid> &txid);
    /**
     * Ping the Electrum server
     */
    void ping();
    /**
     * Return the current tip of the blockchain
     */
    std::shared_ptr<BlockHeader> tip();

    private:
    ElectrumClient(const ElectrumClient &);

    ElectrumClient(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterEsploraClient;
} // namespace uniffi

/**
 * A blockchain backend implementation based on the
 * [esplora HTTP API](https://github.com/blockstream/esplora/blob/master/API.md)
 * But can also use the [waterfalls](https://github.com/RCasatta/waterfalls) endpoint to
 * speed up the scan if supported by the server.
 */
struct EsploraClient



{
    friend uniffi::FfiConverterEsploraClient;

    EsploraClient() = delete;

    EsploraClient(EsploraClient &&) = delete;

    EsploraClient &operator=(const EsploraClient &) = delete;
    EsploraClient &operator=(EsploraClient &&) = delete;

    ~EsploraClient();
    /**
     * Construct an Esplora Client
     */
    static std::shared_ptr<EsploraClient> init(const std::string &url, const std::shared_ptr<Network> &network);
    /**
     * Construct an Esplora Client from an `EsploraClientBuilder`
     */
    static std::shared_ptr<EsploraClient> from_builder(const EsploraClientBuilder &builder);
    /**
     * Construct an Esplora Client using Waterfalls endpoint
     */
    static std::shared_ptr<EsploraClient> new_waterfalls(const std::string &url, const std::shared_ptr<Network> &network);
    /**
     * Broadcast a transaction to the network so that a miner can include it in a block.
     */
    std::shared_ptr<Txid> broadcast(const std::shared_ptr<Transaction> &tx);
    /**
     * Scan the blockchain for the scripts generated by a watch-only wallet
     *
     * This method scans both external and internal address chains, stopping after finding
     * 20 consecutive unused addresses (the gap limit) as recommended by
     * [BIP44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki#address-gap-limit).
     *
     * Returns `Some(Update)` if any changes were found during scanning, or `None` if no changes
     * were detected.
     *
     * To scan beyond the gap limit use `full_scan_to_index()` instead.
     */
    std::shared_ptr<Update> full_scan(const std::shared_ptr<Wollet> &wollet);
    /**
     * Scan the blockchain for the scripts generated by a watch-only wallet up to a specified derivation index
     *
     * While `full_scan()` stops after finding 20 consecutive unused addresses (the gap limit),
     * this method will scan at least up to the given derivation index. This is useful to prevent
     * missing funds in cases where outputs exist beyond the gap limit.
     *
     * Will scan both external and internal address chains up to the given index for maximum safety,
     * even though internal addresses may not need such deep scanning.
     *
     * If transactions are found beyond the gap limit during this scan, subsequent calls to
     * `full_scan()` will automatically scan up to the highest used index, preventing any
     * previously-found transactions from being missed.
     */
    std::shared_ptr<Update> full_scan_to_index(const std::shared_ptr<Wollet> &wollet, uint32_t index);
    /**
     * See [`BlockchainBackend::tip`]
     */
    std::shared_ptr<BlockHeader> tip();

    private:
    EsploraClient(const EsploraClient &);

    EsploraClient(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterExternalUtxo;
} // namespace uniffi

/**
 * An external UTXO, owned by another wallet
 */
struct ExternalUtxo



{
    friend uniffi::FfiConverterExternalUtxo;

    ExternalUtxo() = delete;

    ExternalUtxo(ExternalUtxo &&) = delete;

    ExternalUtxo &operator=(const ExternalUtxo &) = delete;
    ExternalUtxo &operator=(ExternalUtxo &&) = delete;

    ~ExternalUtxo();
    /**
     * Construct an ExternalUtxo
     */
    static std::shared_ptr<ExternalUtxo> init(uint32_t vout, const std::shared_ptr<Transaction> &tx, const std::shared_ptr<TxOutSecrets> &unblinded, uint32_t max_weight_to_satisfy, bool is_segwit);
    /**
     * Construct an `ExternalUtxo` from unchecked outpoint/txout data.
     *
     * Unlike [`ExternalUtxo::new`], this constructor does not inspect a parent transaction or
     * derive `outpoint` and `txout` from it. It exists as an optimisation for callers that
     * already hold the exact outpoint, prevout, and unblinded data and want to avoid fetching or
     * materialising the full transaction just to construct the bindings object.
     *
     * Do not use this for pre-segwit external UTXOs. Pre-segwit inputs require the parent
     * transaction so the builder can populate `non_witness_utxo`, while this constructor always
     * creates an `ExternalUtxo` without it.
     *
     * Use this cautiously. Callers are responsible for ensuring that `outpoint` and `txout`
     * describe the same UTXO. As with [`ExternalUtxo::new`], callers must also ensure that
     * `unblinded` and `max_weight_to_satisfy` match that UTXO.
     *
     * IMPORTANT: This is a temporary workaround to speed up integration work
     * and should be removed after a more complete migration to `lwk`.
     */
    static std::shared_ptr<ExternalUtxo> from_unchecked_data(const std::shared_ptr<OutPoint> &outpoint, const std::shared_ptr<TxOut> &txout, const std::shared_ptr<TxOutSecrets> &unblinded, uint32_t max_weight_to_satisfy);

    private:
    ExternalUtxo(const ExternalUtxo &);

    ExternalUtxo(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};




/**
 * An FFI-safe key-value storage trait for caller-defined persistence.
 *
 * Keys are strings to allow namespacing (e.g., "Liquid:Tx:abcd1234").
 * Values are byte arrays for flexibility in serialization.
 */
struct ForeignStore {
    virtual ~ForeignStore() {}
    /**
     * Retrieve a value by key.
     *
     * Returns `Ok(None)` if the key does not exist.
     */
    virtual
    std::optional<std::vector<uint8_t>> get(const std::string &key) = 0;
    /**
     * Insert or update a value.
     */
    virtual
    void put(const std::string &key, const std::vector<uint8_t> &value) = 0;
    /**
     * Remove a value by key.
     *
     * Returns `Ok(())` even if the key did not exist.
     */
    virtual
    void remove(const std::string &key) = 0;
};

namespace uniffi {
    struct UniffiCallbackInterfaceForeignStore {
        static void get(uint64_t uniffi_handle,RustBuffer key,RustBuffer & uniffi_out_return,RustCallStatus *out_status);
        static void put(uint64_t uniffi_handle,RustBuffer key,RustBuffer value,void * uniffi_out_return,RustCallStatus *out_status);
        static void remove(uint64_t uniffi_handle,RustBuffer key,void * uniffi_out_return,RustCallStatus *out_status);

        static void uniffi_free(uint64_t uniffi_handle);
        static void init();
    private:
        static inline UniffiVTableCallbackInterfaceForeignStore vtable = UniffiVTableCallbackInterfaceForeignStore {
            .get = reinterpret_cast<void *>(&get),
            .put = reinterpret_cast<void *>(&put),
            .remove = reinterpret_cast<void *>(&remove),
            .uniffi_free = reinterpret_cast<void *>(&uniffi_free)
        };
    };
}

namespace uniffi {
    struct FfiConverterForeignStore;
} // namespace uniffi

/**
 * An FFI-safe key-value storage trait for caller-defined persistence.
 *
 * Keys are strings to allow namespacing (e.g., "Liquid:Tx:abcd1234").
 * Values are byte arrays for flexibility in serialization.
 */
struct ForeignStoreImpl

 : public ForeignStore 

{
    friend uniffi::FfiConverterForeignStore;

    ForeignStoreImpl() = delete;

    ForeignStoreImpl(ForeignStoreImpl &&) = delete;

    ForeignStoreImpl &operator=(const ForeignStoreImpl &) = delete;
    ForeignStoreImpl &operator=(ForeignStoreImpl &&) = delete;

    ~ForeignStoreImpl();
    /**
     * Retrieve a value by key.
     *
     * Returns `Ok(None)` if the key does not exist.
     */
    std::optional<std::vector<uint8_t>> get(const std::string &key);
    /**
     * Insert or update a value.
     */
    void put(const std::string &key, const std::vector<uint8_t> &value);
    /**
     * Remove a value by key.
     *
     * Returns `Ok(())` even if the key did not exist.
     */
    void remove(const std::string &key);

    private:
    ForeignStoreImpl(const ForeignStoreImpl &);

    ForeignStoreImpl(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterInvoiceResponse;
} // namespace uniffi

struct InvoiceResponse



{
    friend uniffi::FfiConverterInvoiceResponse;

    InvoiceResponse() = delete;

    InvoiceResponse(InvoiceResponse &&) = delete;

    InvoiceResponse &operator=(const InvoiceResponse &) = delete;
    InvoiceResponse &operator=(InvoiceResponse &&) = delete;

    ~InvoiceResponse();
    PaymentState advance();
    std::shared_ptr<Bolt11Invoice> bolt11_invoice();
    /**
     * The fee of the swap provider
     *
     * It is equal to the invoice amount multiplied by the boltz fee rate.
     * For example for receiving an invoice of 10000 satoshi with a 0.25% rate would be 25 satoshi.
     */
    std::optional<uint64_t> boltz_fee();
    /**
     * The txid of the claim transaction of the swap
     */
    std::optional<std::string> claim_txid();
    bool complete_pay();
    /**
     * The fee of the swap provider and the network fee
     *
     * It is equal to the amount of the invoice minus the amount of the onchain transaction.
     */
    std::optional<uint64_t> fee();
    /**
     * The txid of the lockup transaction of the swap (made by Boltz)
     */
    std::optional<std::string> lockup_txid();
    /**
     * Serialize the prepare pay response data to a json string
     *
     * This can be used to restore the prepare pay response after a crash
     */
    std::string serialize();
    std::string swap_id();

    private:
    InvoiceResponse(const InvoiceResponse &);

    InvoiceResponse(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterIssuance;
} // namespace uniffi

/**
 * The details of an issuance or reissuance
 */
struct Issuance



{
    friend uniffi::FfiConverterIssuance;

    Issuance() = delete;

    Issuance(Issuance &&) = delete;

    Issuance &operator=(const Issuance &) = delete;
    Issuance &operator=(Issuance &&) = delete;

    ~Issuance();
    /**
     * Return the asset id or None if it's a null issuance
     */
    std::optional<AssetId> asset();
    /**
     * Return the amount of the asset in satoshis
     */
    std::optional<uint64_t> asset_satoshi();
    /**
     * Return true if the issuance or reissuance is confidential
     */
    bool is_confidential();
    /**
     * Return true if this is effectively an issuance
     */
    bool is_issuance();
    /**
     * Return true if the issuance or reissuance is null
     */
    bool is_null();
    /**
     * Return true if this is effectively a reissuance
     */
    bool is_reissuance();
    /**
     * Return the previous transaction id or None if it's a null issuance
     */
    std::shared_ptr<Txid> prev_txid();
    /**
     * Return the previous output index or None if it's a null issuance
     */
    std::optional<uint32_t> prev_vout();
    /**
     * Return the token id or None if it's a null issuance
     */
    std::optional<AssetId> token();
    /**
     * Return the amount of the reissuance token in satoshis
     */
    std::optional<uint64_t> token_satoshi();

    private:
    Issuance(const Issuance &);

    Issuance(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterLightningPayment;
} // namespace uniffi

/**
 * Represents a lightning payment (bolt11 invoice or bolt12 offer)
 */
struct LightningPayment



{
    friend uniffi::FfiConverterLightningPayment;

    LightningPayment() = delete;

    LightningPayment(LightningPayment &&) = delete;

    LightningPayment &operator=(const LightningPayment &) = delete;
    LightningPayment &operator=(LightningPayment &&) = delete;

    ~LightningPayment();
    /**
     * Construct a lightning payment (bolt11 invoice or bolt12 offer) from a string
     */
    static std::shared_ptr<LightningPayment> init(const std::string &s);
    /**
     * Construct a lightning payment (bolt11 invoice or bolt12 offer) from a bolt11 invoice
     */
    static std::shared_ptr<LightningPayment> from_bolt11_invoice(const std::shared_ptr<Bolt11Invoice> &invoice);
    /**
     * Returns the bolt11 invoice if the lightning payment is a bolt11 invoice
     */
    std::shared_ptr<Bolt11Invoice> bolt11_invoice();
    /**
     * Returns the invoice amount in satoshis for a BOLT12 offer if set
     *
     * Returns an error if this is not a BOLT12 offer
     */
    std::optional<uint64_t> bolt12_invoice_amount();
    /**
     * Checks if the BOLT12 offer has an amount
     *
     * Returns true if the offer has a per-item amount (requires specifying number of items),
     * false if it doesn't (requires specifying total amount in sats).
     *
     * Returns an error if this is not a BOLT12 offer.
     */
    bool bolt12_offer_has_amount();
    /**
     * Returns true if this is a BOLT12 offer
     */
    bool is_bolt12();
    /**
     * Sets the amount for a BOLT12 offer without an amount
     *
     * The amount should be in satoshis.
     *
     * # Errors
     *
     * Returns an error if:
     * - This is not a BOLT12 offer
     * - The offer already has an amount (use set_bolt12_invoice_amount_via_items instead)
     */
    void set_bolt12_invoice_amount(uint64_t amount_sats);
    /**
     * Sets the amount for a BOLT12 offer based on number of items
     *
     * This calculates the final amount as `items * offer_amount` where
     * `offer_amount` is the per-item amount specified in the offer.
     *
     * # Errors
     *
     * Returns an error if:
     * - This is not a BOLT12 offer
     * - The offer does not have an amount set
     */
    void set_bolt12_invoice_amount_via_items(uint64_t items);

    private:
    LightningPayment(const LightningPayment &);

    LightningPayment(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterLockupResponse;
} // namespace uniffi

struct LockupResponse



{
    friend uniffi::FfiConverterLockupResponse;

    LockupResponse() = delete;

    LockupResponse(LockupResponse &&) = delete;

    LockupResponse &operator=(const LockupResponse &) = delete;
    LockupResponse &operator=(LockupResponse &&) = delete;

    ~LockupResponse();
    PaymentState advance();
    /**
     * The fee of the swap provider
     *
     * It is equal to the swap amount multiplied by the boltz fee rate.
     */
    std::optional<uint64_t> boltz_fee();
    std::string chain_from();
    std::string chain_to();
    std::string claim_address();
    /**
     * The txid of the claim transaction of the swap
     */
    std::optional<std::string> claim_txid();
    bool complete();
    uint64_t expected_amount();
    /**
     * The fee of the swap provider and the network fee
     *
     * It is equal to the amount requested minus the amount sent to the claim address.
     */
    std::optional<uint64_t> fee();
    std::string lockup_address();
    /**
     * The txid of the lockup transaction of the swap
     */
    std::optional<std::string> lockup_txid();
    /**
     * The txid of the refund transaction of the swap
     */
    std::optional<std::string> refund_txid();
    std::string serialize();
    /**
     * Optionally set the lockup transaction txid.
     *
     * This can be useful when the app creates and broadcasts the lockup transaction and wants to
     * persist the txid immediately before websocket updates arrive from Boltz. It helps avoid a
     * race where a fast retry flow could submit the lockup transaction twice.
     */
    void set_lockup_txid(const std::string &txid);
    std::string swap_id();
    /**
     * The BIP21 URI for the lockup address, if provided by Boltz
     */
    std::optional<std::string> uri();

    private:
    LockupResponse(const LockupResponse &);

    LockupResponse(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterLoggingLink;
} // namespace uniffi

/**
 * An object to define logging at the caller level
 */
struct LoggingLink



{
    friend uniffi::FfiConverterLoggingLink;

    LoggingLink() = delete;

    LoggingLink(LoggingLink &&) = delete;

    LoggingLink &operator=(const LoggingLink &) = delete;
    LoggingLink &operator=(LoggingLink &&) = delete;

    ~LoggingLink();
    /**
     * Create a new `LoggingLink`
     */
    static std::shared_ptr<LoggingLink> init(const std::shared_ptr<Logging> &logging);

    private:
    LoggingLink(const LoggingLink &);

    LoggingLink(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterLwkTestEnv;
} // namespace uniffi

/**
 * Test environment
 *
 * Regtest with:
 * * Elements node
 * * Electrum server
 * * Esplora server
 * * Waterfalls server
 *
 * Wrapper over [`lwk_test_util::TestEnv`]
 */
struct LwkTestEnv



{
    friend uniffi::FfiConverterLwkTestEnv;

    LwkTestEnv() = delete;

    LwkTestEnv(LwkTestEnv &&) = delete;

    LwkTestEnv &operator=(const LwkTestEnv &) = delete;
    LwkTestEnv &operator=(LwkTestEnv &&) = delete;

    ~LwkTestEnv();
    /**
     * Creates a new test environment
     */
    static std::shared_ptr<LwkTestEnv> init();
    /**
     * Get the Electrum URL of the test environment
     */
    std::string electrum_url();
    /**
     * Get the Esplora URL of the test environment
     */
    std::string esplora_url();
    /**
     * Generate `blocks` blocks from the node
     */
    void generate(uint32_t blocks);
    /**
     * Get the genesis block hash from the running node.
     */
    std::string genesis_block_hash();
    /**
     * Get a new address from the node
     */
    std::shared_ptr<Address> get_new_address();
    /**
     * Get the height of the node
     */
    uint64_t height();
    /**
     * Issue `satoshi` of an asset from the node
     */
    AssetId issue_asset(uint64_t satoshi);
    /**
     * Get the network of the test environment.
     */
    std::shared_ptr<Network> network();
    /**
     * Send `satoshi` to `address` from the node
     */
    std::shared_ptr<Txid> send_to_address(const std::shared_ptr<Address> &address, uint64_t satoshi, std::optional<AssetId> asset);
    /**
     * Get the Waterfalls URL of the test environment
     */
    std::string waterfalls_url();

    private:
    LwkTestEnv(const LwkTestEnv &);

    LwkTestEnv(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterLwkTestStore;
} // namespace uniffi

/**
 * A lightweight test helper for [`ForeignStore`](crate::ForeignStore) implementations.
 *
 * Use this to verify that Rust can correctly read/write through an FFI store.
 */
struct LwkTestStore



{
    friend uniffi::FfiConverterLwkTestStore;

    LwkTestStore() = delete;

    LwkTestStore(LwkTestStore &&) = delete;

    LwkTestStore &operator=(const LwkTestStore &) = delete;
    LwkTestStore &operator=(LwkTestStore &&) = delete;

    ~LwkTestStore();
    /**
     * Create a new test store helper wrapping the given store.
     */
    static std::shared_ptr<LwkTestStore> init(const std::shared_ptr<ForeignStoreLink> &store);
    /**
     * Read a value from the store.
     */
    std::optional<std::vector<uint8_t>> read(const std::string &key);
    /**
     * Remove a key from the store.
     */
    void remove(const std::string &key);
    /**
     * Write a key-value pair to the store.
     */
    void write(const std::string &key, const std::vector<uint8_t> &value);

    private:
    LwkTestStore(const LwkTestStore &);

    LwkTestStore(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterOutPoint;
} // namespace uniffi

/**
 * A reference to a transaction output
 */
struct OutPoint



{
    friend uniffi::FfiConverterOutPoint;

    OutPoint() = delete;

    OutPoint(OutPoint &&) = delete;

    OutPoint &operator=(const OutPoint &) = delete;
    OutPoint &operator=(OutPoint &&) = delete;

    ~OutPoint();
    /**
     * Construct an OutPoint object from its string representation.
     * For example: "[elements]0000000000000000000000000000000000000000000000000000000000000001:1"
     * To create the string representation of an outpoint use `to_string()`.
     */
    static std::shared_ptr<OutPoint> init(const std::string &s);
    /**
     * Create an OutPoint from a transaction id and output index.
     */
    static std::shared_ptr<OutPoint> from_parts(const std::shared_ptr<Txid> &txid, uint32_t vout);
    /**
     * Return the transaction identifier.
     */
    std::shared_ptr<Txid> txid();
    /**
     * Return the output index.
     */
    uint32_t vout();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    OutPoint(const OutPoint &);

    OutPoint(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterPayment;
} // namespace uniffi

/**
 * A parsed payment category from a payment instruction string.
 *
 * This can be a Bitcoin address, Liquid address, Lightning invoice,
 * Lightning offer, LNURL, BIP353, BIP21 URI, or Liquid BIP21 URI.
 */
struct Payment



{
    friend uniffi::FfiConverterPayment;

    Payment() = delete;

    Payment(Payment &&) = delete;

    Payment &operator=(const Payment &) = delete;
    Payment &operator=(Payment &&) = delete;

    ~Payment();
    /**
     * Parse a payment instruction string into a PaymentCategory
     */
    static std::shared_ptr<Payment> init(const std::string &s);
    /**
     * Returns the BIP21 URI if this is a Bip21 category, None otherwise
     */
    std::shared_ptr<Bip21> bip21();
    /**
     * Returns the BIP321 URI if this is a Bip321 category, None otherwise
     */
    std::shared_ptr<Bip321> bip321();
    /**
     * Returns the BIP353 address (without the ₿ prefix) if this is a Bip353 category, None otherwise
     */
    std::optional<std::string> bip353();
    /**
     * Returns the Bitcoin address if this is a BitcoinAddress category, None otherwise
     *
     * Returns the address portion of the original input string
     */
    std::shared_ptr<BitcoinAddress> bitcoin_address();
    /**
     * Fetches a Bolt11 invoice from a LNURL callback (second step of LNURL-pay).
     */
    std::shared_ptr<Payment> fetch_lnurl_invoice(const LnUrlPayResponse &info, uint64_t amount_sats);
    /**
     * Returns the kind of payment category
     */
    PaymentKind kind();
    /**
     * Returns the Lightning invoice if this is a `LightningInvoice` category, `None` otherwise
     */
    std::shared_ptr<Bolt11Invoice> lightning_invoice();
    /**
     * Returns the Lightning offer as a string if this is a LightningOffer category, None otherwise
     */
    std::optional<std::string> lightning_offer();
    /**
     * Returns a `LightningPayment`` if this category is payable via Lightning
     *
     * Returns `Some` for `LightningInvoice`, `LightningOffer`, and `LnUrl` categories.
     * The returned `LightningPayment` can be used with `BoltzSession::prepare_pay()`.
     */
    std::shared_ptr<LightningPayment> lightning_payment();
    /**
     * Returns the Liquid address if this is a LiquidAddress category, None otherwise
     */
    std::shared_ptr<Address> liquid_address();
    /**
     * Returns the Liquid BIP21 details if this is a LiquidBip21 category, None otherwise
     */
    std::optional<LiquidBip21> liquid_bip21();
    /**
     * Returns the LNURL as a string if this is an LnUrl category, None otherwise
     */
    std::optional<std::string> lnurl();
    /**
     * Resolves a BIP353 payment instruction into a LightningOffer payment.
     */
    std::shared_ptr<Payment> resolve_bip353();
    /**
     * Resolves a LNURL into its metadata (first step of LNURL-pay).
     */
    LnUrlPayResponse resolve_lnurl_info();

    private:
    Payment(const Payment &);

    Payment(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterPosConfig;
} // namespace uniffi

/**
 * POS (Point of Sale) configuration for encoding/decoding
 */
struct PosConfig



{
    friend uniffi::FfiConverterPosConfig;

    PosConfig() = delete;

    PosConfig(PosConfig &&) = delete;

    PosConfig &operator=(const PosConfig &) = delete;
    PosConfig &operator=(PosConfig &&) = delete;

    ~PosConfig();
    /**
     * Create a new POS configuration
     */
    static std::shared_ptr<PosConfig> init(const std::shared_ptr<WolletDescriptor> &descriptor, const std::shared_ptr<CurrencyCode> &currency);
    /**
     * Decode a POS configuration from a URL-safe base64 encoded string
     */
    static std::shared_ptr<PosConfig> decode(const std::string &encoded);
    /**
     * Create a POS configuration with all options
     */
    static std::shared_ptr<PosConfig> with_options(const std::shared_ptr<WolletDescriptor> &descriptor, const std::shared_ptr<CurrencyCode> &currency, std::optional<bool> show_gear, std::optional<bool> show_description);
    /**
     * Get the currency code
     */
    std::shared_ptr<CurrencyCode> currency();
    /**
     * Get the wallet descriptor
     */
    std::shared_ptr<WolletDescriptor> descriptor();
    /**
     * Encode the POS configuration to a URL-safe base64 string
     */
    std::string encode();
    /**
     * Get whether to show the description/note field
     */
    std::optional<bool> show_description();
    /**
     * Get whether to show the gear/settings button
     */
    std::optional<bool> show_gear();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;
    /**
     * Equality check, internally calls Rust's `Eq` trait.
     */
    bool eq(const std::shared_ptr<PosConfig> &other) const;
    /**
     * Inequality check, internally calls Rust's `Ne` trait.
     */
    bool ne(const std::shared_ptr<PosConfig> &other) const;
    /**
     * Returns a hash of the object, internally calls Rust's `Hash` trait.
     */
    uint64_t hash() const;

    private:
    PosConfig(const PosConfig &);

    PosConfig(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterPrecision;
} // namespace uniffi

/**
 * Wrapper over [`lwk_common::Precision`]
 */
struct Precision



{
    friend uniffi::FfiConverterPrecision;

    Precision() = delete;

    Precision(Precision &&) = delete;

    Precision &operator=(const Precision &) = delete;
    Precision &operator=(Precision &&) = delete;

    ~Precision();
    /**
     * See [`lwk_common::Precision::new`]
     */
    static std::shared_ptr<Precision> init(uint8_t precision);
    /**
     * See [`lwk_common::Precision::sats_to_string`]
     */
    std::string sats_to_string(int64_t sats);
    /**
     * See [`lwk_common::Precision::string_to_sats`]
     */
    int64_t string_to_sats(const std::string &val);

    private:
    Precision(const Precision &);

    Precision(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterPreparePayResponse;
} // namespace uniffi

struct PreparePayResponse



{
    friend uniffi::FfiConverterPreparePayResponse;

    PreparePayResponse() = delete;

    PreparePayResponse(PreparePayResponse &&) = delete;

    PreparePayResponse &operator=(const PreparePayResponse &) = delete;
    PreparePayResponse &operator=(PreparePayResponse &&) = delete;

    ~PreparePayResponse();
    PaymentState advance();
    /**
     * The fee of the swap provider
     *
     * It is equal to the invoice amount multiplied by the boltz fee rate.
     * For example for paying an invoice of 1000 satoshi with a 0.1% rate would be 1 satoshi.
     */
    std::optional<uint64_t> boltz_fee();
    bool complete_pay();
    /**
     * The fee of the swap provider and the network fee
     *
     * It is equal to the amount requested onchain minus the amount of the bolt11 invoice
     */
    std::optional<uint64_t> fee();
    /**
     * The txid of the user lockup transaction of the swap.
     */
    std::optional<std::string> lockup_txid();
    /**
     * The txid of the refund transaction of the swap
     */
    std::optional<std::string> refund_txid();
    /**
     * Serialize the prepare pay response data to a json string
     *
     * This can be used to restore the prepare pay response after a crash
     */
    std::string serialize();
    /**
     * Optionally set the lockup transaction txid.
     *
     * This can be useful when the app creates and broadcasts the lockup transaction and wants to
     * persist the txid immediately before websocket updates arrive from Boltz. It helps avoid a
     * race where a fast retry flow could submit the lockup transaction twice.
     */
    void set_lockup_txid(const std::string &txid);
    std::string swap_id();
    std::string uri();
    std::shared_ptr<Address> uri_address();
    uint64_t uri_amount();

    private:
    PreparePayResponse(const PreparePayResponse &);

    PreparePayResponse(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterPset;
} // namespace uniffi

/**
 * A Partially Signed Elements Transaction
 */
struct Pset



{
    friend uniffi::FfiConverterPset;

    Pset() = delete;

    Pset(Pset &&) = delete;

    Pset &operator=(const Pset &) = delete;
    Pset &operator=(Pset &&) = delete;

    ~Pset();
    /**
     * Construct a Watch-Only wallet object
     */
    static std::shared_ptr<Pset> init(const std::string &base64);
    /**
     * Attempt to combine with another `Pset`.
     */
    std::shared_ptr<Pset> combine(const std::shared_ptr<Pset> &other);
    /**
     * Extract the Transaction from a Pset by filling in
     * the available signature information in place.
     */
    std::shared_ptr<Transaction> extract_tx();
    /**
     * Finalize and extract the PSET
     */
    std::shared_ptr<Transaction> finalize();
    /**
     * Return a copy of the inputs of this PSET
     */
    std::vector<std::shared_ptr<PsetInput>> inputs();
    /**
     * Return a copy of the outputs of this PSET
     */
    std::vector<std::shared_ptr<PsetOutput>> outputs();
    /**
     * Get the unique id of the PSET as defined by [BIP-370](https://github.com/bitcoin/bips/blob/master/bip-0370.mediawiki#unique-identification)
     *
     * The unique id is the txid of the PSET with sequence numbers of inputs set to 0
     */
    std::shared_ptr<Txid> unique_id();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    Pset(const Pset &);

    Pset(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterPsetBalance;
} // namespace uniffi

struct PsetBalance



{
    friend uniffi::FfiConverterPsetBalance;

    PsetBalance() = delete;

    PsetBalance(PsetBalance &&) = delete;

    PsetBalance &operator=(const PsetBalance &) = delete;
    PsetBalance &operator=(PsetBalance &&) = delete;

    ~PsetBalance();
    std::unordered_map<AssetId, int64_t> balances();
    uint64_t fee();
    std::vector<std::shared_ptr<Recipient>> recipients();

    private:
    PsetBalance(const PsetBalance &);

    PsetBalance(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterPsetDetails;
} // namespace uniffi

/**
 * The details of a Partially Signed Elements Transaction:
 *
 * - the net balance from the point of view of the wallet
 * - the available and missing signatures for each input
 * - for issuances and reissuances transactions contains the issuance or reissuance details
 */
struct PsetDetails



{
    friend uniffi::FfiConverterPsetDetails;

    PsetDetails() = delete;

    PsetDetails(PsetDetails &&) = delete;

    PsetDetails &operator=(const PsetDetails &) = delete;
    PsetDetails &operator=(PsetDetails &&) = delete;

    ~PsetDetails();
    /**
     * Return the balance of the PSET from the point of view of the wallet
     * that generated this via `psetDetails()`
     */
    std::shared_ptr<PsetBalance> balance();
    /**
     * Set of fingerprints for which the PSET has a signature
     */
    std::vector<std::string> fingerprints_has();
    /**
     * Set of fingerprints for which the PSET is missing a signature
     */
    std::vector<std::string> fingerprints_missing();
    /**
     * Return an element for every input that could possibly be a issuance or a reissuance
     */
    std::vector<std::shared_ptr<Issuance>> inputs_issuances();
    /**
     * For each input its existing or missing signatures
     */
    std::vector<std::shared_ptr<PsetSignatures>> signatures();

    private:
    PsetDetails(const PsetDetails &);

    PsetDetails(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterPsetInput;
} // namespace uniffi

/**
 * PSET input (read-only)
 */
struct PsetInput



{
    friend uniffi::FfiConverterPsetInput;

    PsetInput() = delete;

    PsetInput(PsetInput &&) = delete;

    PsetInput &operator=(const PsetInput &) = delete;
    PsetInput &operator=(PsetInput &&) = delete;

    ~PsetInput();
    /**
     * If the input has a (re)issuance, the issuance object.
     */
    std::shared_ptr<Issuance> issuance();
    /**
     * If the input has an issuance, the asset id.
     */
    std::optional<AssetId> issuance_asset();
    /**
     * If the input has an issuance, returns (asset_id, token_id).
     * Returns `None` if the input has no issuance.
     */
    std::optional<std::vector<AssetId>> issuance_ids();
    /**
     * If the input has an issuance, the token id.
     */
    std::optional<AssetId> issuance_token();
    /**
     * Prevout scriptpubkey of the input.
     */
    std::shared_ptr<Script> previous_script_pubkey();
    /**
     * Prevout TXID of the input.
     */
    std::shared_ptr<Txid> previous_txid();
    /**
     * Prevout vout of the input.
     */
    uint32_t previous_vout();
    /**
     * Redeem script of the input.
     */
    std::shared_ptr<Script> redeem_script();
    /**
     * Input sighash.
     */
    uint32_t sighash();

    private:
    PsetInput(const PsetInput &);

    PsetInput(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterPsetOutput;
} // namespace uniffi

/**
 * PSET output (read-only)
 */
struct PsetOutput



{
    friend uniffi::FfiConverterPsetOutput;

    PsetOutput() = delete;

    PsetOutput(PsetOutput &&) = delete;

    PsetOutput &operator=(const PsetOutput &) = delete;
    PsetOutput &operator=(PsetOutput &&) = delete;

    ~PsetOutput();
    /**
     * Get the explicit amount, if set.
     */
    std::optional<uint64_t> amount();
    /**
     * Get the explicit asset ID, if set.
     */
    std::optional<AssetId> asset();
    /**
     * Get the blinder index, if set.
     */
    std::optional<uint32_t> blinder_index();
    /**
     * Get the script pubkey.
     */
    std::shared_ptr<Script> script_pubkey();

    private:
    PsetOutput(const PsetOutput &);

    PsetOutput(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterPsetSignatures;
} // namespace uniffi

struct PsetSignatures



{
    friend uniffi::FfiConverterPsetSignatures;

    PsetSignatures() = delete;

    PsetSignatures(PsetSignatures &&) = delete;

    PsetSignatures &operator=(const PsetSignatures &) = delete;
    PsetSignatures &operator=(PsetSignatures &&) = delete;

    ~PsetSignatures();
    std::unordered_map<std::string, std::string> has_signature();
    std::unordered_map<std::string, std::string> missing_signature();

    private:
    PsetSignatures(const PsetSignatures &);

    PsetSignatures(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterQuoteBuilder;
} // namespace uniffi

/**
 * Builder for creating swap quotes
 */
struct QuoteBuilder



{
    friend uniffi::FfiConverterQuoteBuilder;

    QuoteBuilder() = delete;

    QuoteBuilder(QuoteBuilder &&) = delete;

    QuoteBuilder &operator=(const QuoteBuilder &) = delete;
    QuoteBuilder &operator=(QuoteBuilder &&) = delete;

    ~QuoteBuilder();
    /**
     * Build the quote, calculating fees and receive amount
     */
    Quote build();
    /**
     * Set the destination asset for the swap
     */
    void receive(const SwapAsset &asset);
    /**
     * Set the source asset for the swap
     */
    void send(const SwapAsset &asset);

    private:
    QuoteBuilder(const QuoteBuilder &);

    QuoteBuilder(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterRecipient;
} // namespace uniffi

struct Recipient



{
    friend uniffi::FfiConverterRecipient;

    Recipient() = delete;

    Recipient(Recipient &&) = delete;

    Recipient &operator=(const Recipient &) = delete;
    Recipient &operator=(Recipient &&) = delete;

    ~Recipient();
    std::shared_ptr<Address> address();
    std::optional<AssetId> asset();
    std::optional<uint64_t> value();
    uint32_t vout();

    private:
    Recipient(const Recipient &);

    Recipient(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterScript;
} // namespace uniffi

/**
 * A Liquid script
 */
struct Script



{
    friend uniffi::FfiConverterScript;

    Script() = delete;

    Script(Script &&) = delete;

    Script &operator=(const Script &) = delete;
    Script &operator=(Script &&) = delete;

    ~Script();
    /**
     * Construct a Script object from its hex representation.
     * To create the hex representation of a script use `to_string()`.
     *
     * Deprecated: use `from_string()` instead.
     */
    static std::shared_ptr<Script> init(const std::string &hex);
    /**
     * Create an empty script (for fee outputs).
     */
    static std::shared_ptr<Script> empty();
    /**
     * Construct a Script object from its bytes.
     */
    static std::shared_ptr<Script> from_bytes(const std::vector<uint8_t> &bytes);
    /**
     * Construct a Script object from its canonical string representation.
     * To create the string representation of a script use `to_string()`.
     */
    static std::shared_ptr<Script> from_string(const std::string &s);
    /**
     * Create an OP_RETURN script (for burn outputs).
     */
    static std::shared_ptr<Script> new_op_return(const std::vector<uint8_t> &data);
    /**
     * Return the consensus encoded bytes of the script.
     *
     * Deprecated: use `to_bytes()` instead.
     */
    std::vector<uint8_t> bytes();
    /**
     * Whether a script pubkey is provably unspendable (like a burn script)
     */
    bool is_provably_unspendable();
    /**
     * Returns SHA256 of the script's consensus bytes.
     *
     * Returns an equivalent value to the `jet::input_script_hash(index)`/`jet::output_script_hash(index)`.
     */
    std::string jet_sha256_hex();
    /**
     * Return the string representation of the script showing op codes and their arguments.
     * For example: "OP_0 OP_PUSHBYTES_32 d2e99f0c38089c08e5e1080ff6658c6075afaa7699d384333d956c470881afde"
     */
    std::string to_asm();
    /**
     * Return the consensus encoded bytes of the script.
     */
    std::vector<uint8_t> to_bytes();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    Script(const Script &);

    Script(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterSecretKey;
} // namespace uniffi

/**
 * A secret key
 */
struct SecretKey



{
    friend uniffi::FfiConverterSecretKey;

    SecretKey() = delete;

    SecretKey(SecretKey &&) = delete;

    SecretKey &operator=(const SecretKey &) = delete;
    SecretKey &operator=(SecretKey &&) = delete;

    ~SecretKey();
    /**
     * Creates a `SecretKey` from a byte array
     *
     * The bytes can be used to create a `SecretKey` with `from_bytes()`
     */
    static std::shared_ptr<SecretKey> from_bytes(const std::vector<uint8_t> &bytes);
    /**
     * Creates a `SecretKey` from a WIF (Wallet Import Format) string
     */
    static std::shared_ptr<SecretKey> from_wif(const std::string &wif);
    /**
     * Returns the bytes of the secret key, the bytes can be used to create a `SecretKey` with `from_bytes()`
     */
    std::vector<uint8_t> bytes();
    /**
     * Sign the given `pset`
     */
    std::shared_ptr<Pset> sign(const std::shared_ptr<Pset> &pset);

    private:
    SecretKey(const SecretKey &);

    SecretKey(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterSigner;
} // namespace uniffi

/**
 * A Software signer, wrapper over [`lwk_signer::SwSigner`]
 */
struct Signer



{
    friend uniffi::FfiConverterSigner;

    Signer() = delete;

    Signer(Signer &&) = delete;

    Signer &operator=(const Signer &) = delete;
    Signer &operator=(Signer &&) = delete;

    ~Signer();
    /**
     * Construct a software signer
     */
    static std::shared_ptr<Signer> init(const std::shared_ptr<Mnemonic> &mnemonic, const std::shared_ptr<Network> &network);
    /**
     * Generate a new random software signer
     */
    static std::shared_ptr<Signer> random(const std::shared_ptr<Network> &network);
    /**
     * AMP0 account xpub
     */
    std::string amp0_account_xpub(uint32_t account);
    /**
     * AMP0 sign login challenge
     */
    std::string amp0_sign_challenge(const std::string &challenge);
    /**
     * AMP0 signer data for login
     */
    std::shared_ptr<Amp0SignerData> amp0_signer_data();
    /**
     * Derive a BIP85 mnemonic from this signer
     *
     * # Arguments
     * * `index` - The index for the derived mnemonic (0-based)
     * * `word_count` - The number of words in the derived mnemonic (12 or 24)
     *
     * # Returns
     * * `Ok(Mnemonic)` - The derived BIP85 mnemonic
     * * `Err(LwkError)` - If BIP85 derivation fails
     *
     * # Example
     * ```python
     * signer = Signer.new(mnemonic, network)
     * derived_mnemonic = signer.derive_bip85_mnemonic(0, 12)
     * ```
     */
    std::shared_ptr<Mnemonic> derive_bip85_mnemonic(uint32_t index, uint32_t word_count);
    /**
     * Return the signer fingerprint
     */
    std::string fingerprint();
    /**
     * Return keyorigin and xpub, like "[73c5da0a/84h/1h/0h]tpub..."
     */
    std::string keyorigin_xpub(const std::shared_ptr<Bip> &bip);
    /**
     * Get the mnemonic of the signer
     */
    std::shared_ptr<Mnemonic> mnemonic();
    /**
     * Sign the given `pset`
     *
     * Note from an API perspective it would be better to consume the `pset` parameter so it would
     * be clear the signed PSET is the returned one, but it's not possible with uniffi bindings
     */
    std::shared_ptr<Pset> sign(const std::shared_ptr<Pset> &pset);
    /**
     * Generate a singlesig descriptor with the given parameters
     */
    std::shared_ptr<WolletDescriptor> singlesig_desc(const Singlesig &script_variant, const DescriptorBlindingKey &blinding_variant);
    /**
     * Return the witness public key hash, slip77 descriptor of this signer
     */
    std::shared_ptr<WolletDescriptor> wpkh_slip77_descriptor();

    private:
    Signer(const Signer &);

    Signer(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterSwapList;
} // namespace uniffi

struct SwapList



{
    friend uniffi::FfiConverterSwapList;

    SwapList() = delete;

    SwapList(SwapList &&) = delete;

    SwapList &operator=(const SwapList &) = delete;
    SwapList &operator=(SwapList &&) = delete;

    ~SwapList();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    SwapList(const SwapList &);

    SwapList(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterTransaction;
} // namespace uniffi

/**
 * A Liquid transaction
 */
struct Transaction



{
    friend uniffi::FfiConverterTransaction;

    Transaction() = delete;

    Transaction(Transaction &&) = delete;

    Transaction &operator=(const Transaction &) = delete;
    Transaction &operator=(Transaction &&) = delete;

    ~Transaction();
    /**
     * Construct a Transaction object from its hex representation.
     * To create the hex representation of a transaction use `to_string()`.
     *
     * Deprecated: use `from_string()` instead.
     */
    static std::shared_ptr<Transaction> init(const std::string &hex);
    /**
     * Construct a Transaction object from its bytes.
     */
    static std::shared_ptr<Transaction> from_bytes(const std::vector<uint8_t> &bytes);
    /**
     * Construct a Transaction object from its canonical string representation.
     * To create the string representation of a transaction use `to_string()`.
     */
    static std::shared_ptr<Transaction> from_string(const std::string &s);
    /**
     * Return the consensus encoded bytes of the transaction.
     *
     * Deprecated: use `to_bytes()` instead.
     */
    std::vector<uint8_t> bytes();
    /**
     * Returns the "discount virtual size" of this transaction.
     */
    uint32_t discount_vsize();
    /**
     * Return the fee of the transaction in the given asset.
     * At the moment the only asset that can be used as fee is the policy asset (LBTC for mainnet).
     */
    uint64_t fee(const AssetId &policy_asset);
    /**
     * Return a copy of the inputs of the transaction.
     */
    std::vector<std::shared_ptr<TxIn>> inputs();
    /**
     * Return a copy of the outputs of the transaction.
     */
    std::vector<std::shared_ptr<TxOut>> outputs();
    /**
     * Return the consensus encoded bytes of the transaction.
     */
    std::vector<uint8_t> to_bytes();
    /**
     * Return the transaction identifier.
     */
    std::shared_ptr<Txid> txid();
    /**
     * Verify that the transaction has correctly calculated blinding factors and they CT
     * verification equation holds.
     *
     * This is *NOT* a complete Transaction verification check
     * It does *NOT* check whether input witness/script satisfies the script pubkey, or
     * inputs are double-spent and other consensus checks.
     *
     * This method only checks if the `Transaction` verification equation for Confidential
     * transactions holds. i.e Sum of inputs = Sum of outputs + fees.
     *
     * And the corresponding surjection/rangeproofs are correct.
     * For checking of surjection proofs and amounts, spent_utxos parameter
     * should contain information about the prevouts. Note that the order of
     * spent_utxos should be consistent with transaction inputs.
     */
    void verify_tx_amt_proofs(const std::vector<std::shared_ptr<TxOut>> &utxos);
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    Transaction(const Transaction &);

    Transaction(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterTxBuilder;
} // namespace uniffi

/**
 * Wrapper over [`lwk_wollet::TxBuilder`]
 */
struct TxBuilder



{
    friend uniffi::FfiConverterTxBuilder;

    TxBuilder() = delete;

    TxBuilder(TxBuilder &&) = delete;

    TxBuilder &operator=(const TxBuilder &) = delete;
    TxBuilder &operator=(TxBuilder &&) = delete;

    ~TxBuilder();
    /**
     * Construct a transaction builder
     */
    static std::shared_ptr<TxBuilder> init(const std::shared_ptr<Network> &network);
    /**
     * Burn satoshi units of the given asset
     */
    void add_burn(uint64_t satoshi, const AssetId &asset);
    /**
     * Add explicit recipient
     */
    void add_explicit_recipient(const std::shared_ptr<Address> &address, uint64_t satoshi, const AssetId &asset);
    /**
     * Adds external UTXOs
     *
     * Note: unblinded UTXOs with the same scriptpubkeys as the wallet, are considered external.
     */
    void add_external_utxos(const std::vector<std::shared_ptr<ExternalUtxo>> &utxos);
    /**
     * Add input rangeproofs
     */
    void add_input_rangeproofs(bool add_rangeproofs);
    /**
     * Add a recipient receiving L-BTC
     */
    void add_lbtc_recipient(const std::shared_ptr<Address> &address, uint64_t satoshi);
    /**
     * Add a recipient receiving the given asset
     */
    void add_recipient(const std::shared_ptr<Address> &address, uint64_t satoshi, const AssetId &asset);
    /**
     * Sets the address to drain excess L-BTC to
     */
    void drain_lbtc_to(const std::shared_ptr<Address> &address);
    /**
     * Select all available L-BTC inputs
     */
    void drain_lbtc_wallet();
    /**
     * Fee rate in sats/kvb
     * Multiply sats/vb value by 1000 i.e. 1.0 sat/byte = 1000.0 sat/kvb
     */
    void fee_rate(std::optional<float> rate);
    /**
     * Build the transaction
     */
    std::shared_ptr<Pset> finish(const std::shared_ptr<Wollet> &wollet);
    /**
     * Build the transaction
     */
    std::shared_ptr<Amp0Pset> finish_for_amp0(const std::shared_ptr<Wollet> &wollet);
    /**
     * Issue an asset
     *
     * There will be `asset_sats` units of this asset that will be received by
     * `asset_receiver` if it's set, otherwise to an address of the wallet generating the issuance.
     *
     * There will be `token_sats` reissuance tokens that allow token holder to reissue the created
     * asset. Reissuance token will be received by `token_receiver` if it's some, or to an
     * address of the wallet generating the issuance if none.
     *
     * If a `contract` is provided, it's metadata will be committed in the generated asset id.
     *
     * Can't be used if `reissue_asset` has been called
     */
    void issue_asset(uint64_t asset_sats, std::shared_ptr<Address> asset_receiver, uint64_t token_sats, std::shared_ptr<Address> token_receiver, std::shared_ptr<Contract> contract);
    /**
     * Set data to create a PSET from which you
     * can create a LiquiDEX proposal
     */
    void liquidex_make(const std::shared_ptr<OutPoint> &utxo, const std::shared_ptr<Address> &address, uint64_t amount, const AssetId &asset);
    /**
     * Set data to take LiquiDEX proposals
     */
    void liquidex_take(const std::vector<std::shared_ptr<ValidatedLiquidexProposal>> &proposals);
    /**
     * Reissue an asset
     *
     * reissue the asset defined by `asset_to_reissue`, provided the reissuance token is owned
     * by the wallet generating te reissuance.
     *
     * Generated transaction will create `satoshi_to_reissue` new asset units, and they will be
     * sent to the provided `asset_receiver` address if some, or to an address from the wallet
     * generating the reissuance transaction if none.
     *
     * If the issuance transaction does not involve this wallet,
     * pass the issuance transaction in `issuance_tx`.
     */
    void reissue_asset(const AssetId &asset_to_reissue, uint64_t satoshi_to_reissue, std::shared_ptr<Address> asset_receiver, std::shared_ptr<Transaction> issuance_tx);
    /**
     * Switch to manual coin selection by giving a list of internal UTXOs to use.
     *
     * All passed UTXOs are added to the transaction.
     * No other wallet UTXO is added to the transaction, caller is supposed to add enough UTXOs to
     * cover for all recipients and fees.
     *
     * This method never fails, any error will be raised in [`TxBuilder::finish`].
     *
     * Possible errors:
     * * OutPoint doesn't belong to the wallet
     * * Insufficient funds (remember to include L-BTC utxos for fees)
     */
    void set_wallet_utxos(const std::vector<std::shared_ptr<OutPoint>> &utxos);
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    TxBuilder(const TxBuilder &);

    TxBuilder(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterTxIn;
} // namespace uniffi

/**
 * A transaction input.
 */
struct TxIn



{
    friend uniffi::FfiConverterTxIn;

    TxIn() = delete;

    TxIn(TxIn &&) = delete;

    TxIn &operator=(const TxIn &) = delete;
    TxIn &operator=(TxIn &&) = delete;

    ~TxIn();
    /**
     * Outpoint
     */
    std::shared_ptr<OutPoint> outpoint();
    /**
     * Get the sequence number for this input.
     */
    uint32_t sequence();

    private:
    TxIn(const TxIn &);

    TxIn(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterTxOut;
} // namespace uniffi

/**
 * A transaction output.
 */
struct TxOut



{
    friend uniffi::FfiConverterTxOut;

    TxOut() = delete;

    TxOut(TxOut &&) = delete;

    TxOut &operator=(const TxOut &) = delete;
    TxOut &operator=(TxOut &&) = delete;

    ~TxOut();
    /**
     * Create a TxOut with explicit asset and value from script pubkey and asset ID.
     *
     * This is useful for constructing UTXOs for Simplicity transaction signing.
     */
    static std::shared_ptr<TxOut> from_explicit(const std::shared_ptr<Script> &script_pubkey, const AssetId &asset_id, uint64_t satoshi);
    /**
     * If explicit returns the asset, if confidential [None]
     */
    std::optional<AssetId> asset();
    /**
     * Whether or not this output is a fee output
     */
    bool is_fee();
    /**
     * Returns if at least some part of this output are blinded
     */
    bool is_partially_blinded();
    /**
     * Scriptpubkey
     */
    std::shared_ptr<Script> script_pubkey();
    /**
     * Unblind the output
     */
    std::shared_ptr<TxOutSecrets> unblind(const std::shared_ptr<SecretKey> &secret_key);
    /**
     * Unconfidential address
     */
    std::shared_ptr<Address> unconfidential_address(const std::shared_ptr<Network> &network);
    /**
     * If explicit returns the value, if confidential [None]
     */
    std::optional<uint64_t> value();

    private:
    TxOut(const TxOut &);

    TxOut(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterTxOutSecrets;
} // namespace uniffi

/**
 * Contains unblinded information such as the asset and the value of a transaction output
 */
struct TxOutSecrets



{
    friend uniffi::FfiConverterTxOutSecrets;

    TxOutSecrets() = delete;

    TxOutSecrets(TxOutSecrets &&) = delete;

    TxOutSecrets &operator=(const TxOutSecrets &) = delete;
    TxOutSecrets &operator=(TxOutSecrets &&) = delete;

    ~TxOutSecrets();
    /**
     * Return the asset identifier of the output.
     */
    AssetId asset();
    /**
     * Return the asset blinding factor as a hex string.
     *
     * Deprecated: use `asset_blinding_factor()` instead.
     */
    std::string asset_bf();
    /**
     * Get the asset commitment
     *
     * If the output is explicit, returns the empty string
     */
    std::string asset_commitment();
    /**
     * Return true if the output is explicit (no blinding factors).
     */
    bool is_explicit();
    /**
     * Return the value of the output.
     */
    uint64_t value();
    /**
     * Return the value blinding factor as a hex string.
     *
     * Deprecated: use `value_blinding_factor()` instead.
     */
    std::string value_bf();
    /**
     * Get the value commitment
     *
     * If the output is explicit, returns the empty string
     */
    std::string value_commitment();

    private:
    TxOutSecrets(const TxOutSecrets &);

    TxOutSecrets(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterTxid;
} // namespace uniffi

/**
 * A transaction identifier.
 */
struct Txid



{
    friend uniffi::FfiConverterTxid;

    Txid() = delete;

    Txid(Txid &&) = delete;

    Txid &operator=(const Txid &) = delete;
    Txid &operator=(Txid &&) = delete;

    ~Txid();
    /**
     * Construct a Txid object
     *
     * Deprecated: use `from_string()` instead.
     */
    static std::shared_ptr<Txid> init(const std::string &hex);
    /**
     * Construct a Transaction object from its bytes.
     */
    static std::shared_ptr<Txid> from_bytes(const std::vector<uint8_t> &bytes);
    /**
     * Construct a Txid object from its canonical string representation.
     *
     * To create the string representation of a Txid use `to_string()`.
     */
    static std::shared_ptr<Txid> from_string(const std::string &s);
    /**
     * Return the bytes of the transaction identifier.
     *
     * Deprecated: use `to_bytes()` instead.
     */
    std::vector<uint8_t> bytes();
    /**
     * Return the bytes of the transaction identifier.
     */
    std::vector<uint8_t> to_bytes();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    Txid(const Txid &);

    Txid(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterUnvalidatedLiquidexProposal;
} // namespace uniffi

/**
 * LiquiDEX swap proposal
 *
 * A LiquiDEX swap proposal is a transaction with one input and one output created by the "maker".
 * The transaction "swaps" the input for the output, meaning that the "maker" sends the input and
 * receives the output.
 * However the transaction is incomplete (unbalanced and without a fee output), thus it cannot be
 * broadcast.
 * The "taker" can "complete" the transaction (using `liquidex_take()`) by
 * adding more inputs and more outputs to balance the amounts, meaning that the "taker" sends the
 * output and receives the input.
 */
struct UnvalidatedLiquidexProposal



{
    friend uniffi::FfiConverterUnvalidatedLiquidexProposal;

    UnvalidatedLiquidexProposal() = delete;

    UnvalidatedLiquidexProposal(UnvalidatedLiquidexProposal &&) = delete;

    UnvalidatedLiquidexProposal &operator=(const UnvalidatedLiquidexProposal &) = delete;
    UnvalidatedLiquidexProposal &operator=(UnvalidatedLiquidexProposal &&) = delete;

    ~UnvalidatedLiquidexProposal();
    /**
     * Create a LiquiDEX proposal from its json string representation
     */
    static std::shared_ptr<UnvalidatedLiquidexProposal> init(const std::string &s);
    /**
     * Create a LiquiDEX proposal from a PSET
     */
    static std::shared_ptr<UnvalidatedLiquidexProposal> from_pset(const std::shared_ptr<Pset> &pset);
    /**
     * Validate the proposal output but not the input wich require fetching the previous transaction
     */
    std::shared_ptr<ValidatedLiquidexProposal> insecure_validate();
    /**
     * Return the transaction id of the previous transaction needed for validation
     */
    std::shared_ptr<Txid> needed_tx();
    /**
     * Validate the proposal input and output, returning a validated proposal.
     */
    std::shared_ptr<ValidatedLiquidexProposal> validate(const std::shared_ptr<Transaction> &previous_tx);
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    UnvalidatedLiquidexProposal(const UnvalidatedLiquidexProposal &);

    UnvalidatedLiquidexProposal(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterUpdate;
} // namespace uniffi

/**
 * Wrapper over [`lwk_wollet::Update`]
 */
struct Update



{
    friend uniffi::FfiConverterUpdate;

    Update() = delete;

    Update(Update &&) = delete;

    Update &operator=(const Update &) = delete;
    Update &operator=(Update &&) = delete;

    ~Update();
    /**
     * Creates an `Update` from a byte array created with `serialize()`
     */
    static std::shared_ptr<Update> init(const std::vector<uint8_t> &bytes);
    /**
     * Whether the update only changes the tip (does not affect transactions)
     */
    bool only_tip();
    /**
     * Serialize an `Update` to a byte array, can be deserialized back with `new()`
     */
    std::vector<uint8_t> serialize();

    private:
    Update(const Update &);

    Update(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterValidatedLiquidexProposal;
} // namespace uniffi

/**
 * Created by validating `UnvalidatedLiquidexProposal` via `validate()` or `insecure_validate()`
 */
struct ValidatedLiquidexProposal



{
    friend uniffi::FfiConverterValidatedLiquidexProposal;

    ValidatedLiquidexProposal() = delete;

    ValidatedLiquidexProposal(ValidatedLiquidexProposal &&) = delete;

    ValidatedLiquidexProposal &operator=(const ValidatedLiquidexProposal &) = delete;
    ValidatedLiquidexProposal &operator=(ValidatedLiquidexProposal &&) = delete;

    ~ValidatedLiquidexProposal();
    /**
     * The asset value and amount in the input of this validated proposal.
     */
    std::shared_ptr<AssetAmount> input();
    /**
     * The asset value and amount in the output of this validated proposal.
     */
    std::shared_ptr<AssetAmount> output();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    ValidatedLiquidexProposal(const ValidatedLiquidexProposal &);

    ValidatedLiquidexProposal(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterValueBlindingFactor;
} // namespace uniffi

/**
 * A blinding factor for value commitments.
 */
struct ValueBlindingFactor



{
    friend uniffi::FfiConverterValueBlindingFactor;

    ValueBlindingFactor() = delete;

    ValueBlindingFactor(ValueBlindingFactor &&) = delete;

    ValueBlindingFactor &operator=(const ValueBlindingFactor &) = delete;
    ValueBlindingFactor &operator=(ValueBlindingFactor &&) = delete;

    ~ValueBlindingFactor();
    /**
     * Create from bytes.
     */
    static std::shared_ptr<ValueBlindingFactor> from_bytes(const std::vector<uint8_t> &bytes);
    /**
     * Creates from a hex string.
     */
    static std::shared_ptr<ValueBlindingFactor> from_string(const std::string &s);
    /**
     * Get a unblinded/zero value blinding factor
     */
    static std::shared_ptr<ValueBlindingFactor> zero();
    /**
     * Returns the bytes (32 bytes).
     */
    std::vector<uint8_t> to_bytes();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    ValueBlindingFactor(const ValueBlindingFactor &);

    ValueBlindingFactor(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterWalletTx;
} // namespace uniffi

/**
 * Value returned by asking transactions to the wallet. Contains details about a transaction
 * from the perspective of the wallet, for example the net-balance of the transaction for the
 * wallet.
 */
struct WalletTx



{
    friend uniffi::FfiConverterWalletTx;

    WalletTx() = delete;

    WalletTx(WalletTx &&) = delete;

    WalletTx &operator=(const WalletTx &) = delete;
    WalletTx &operator=(WalletTx &&) = delete;

    ~WalletTx();
    /**
     * Return the net balance of the transaction for the wallet.
     */
    std::unordered_map<AssetId, int64_t> balance();
    /**
     * Return the fee of the transaction.
     */
    uint64_t fee();
    /**
     * Return the height of the block containing the transaction if it's confirmed.
     */
    std::optional<uint32_t> height();
    /**
     * Return a list with the same number of elements as the inputs of the transaction.
     * The element in the list is a `WalletTxOut` (the output spent to create the input)
     * if it belongs to the wallet, while it is None for inputs owned by others
     */
    std::vector<std::shared_ptr<WalletTxOut>> inputs();
    /**
     * Return a list with the same number of elements as the outputs of the transaction.
     * The element in the list is a `WalletTxOut` if it belongs to the wallet,
     * while it is None for inputs owned by others
     */
    std::vector<std::shared_ptr<WalletTxOut>> outputs();
    /**
     * Return the timestamp of the block containing the transaction if it's confirmed.
     */
    std::optional<uint32_t> timestamp();
    /**
     * Return a copy of the transaction.
     */
    std::shared_ptr<Transaction> tx();
    /**
     * Return the transaction identifier.
     */
    std::shared_ptr<Txid> txid();
    /**
     * Return the type of the transaction. Can be "issuance", "reissuance", "burn", "redeposit",
     * "incoming", "outgoing" or "unknown".
     */
    std::string type();
    /**
     * Return the URL to view the transaction on the explorer. Including the information needed to
     * unblind the transaction in the explorer UI.
     */
    std::string unblinded_url(const std::string &explorer_url);

    private:
    WalletTx(const WalletTx &);

    WalletTx(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterWalletTxOut;
} // namespace uniffi

/**
 * Details of a wallet transaction output used in `WalletTx`
 */
struct WalletTxOut



{
    friend uniffi::FfiConverterWalletTxOut;

    WalletTxOut() = delete;

    WalletTxOut(WalletTxOut &&) = delete;

    WalletTxOut &operator=(const WalletTxOut &) = delete;
    WalletTxOut &operator=(WalletTxOut &&) = delete;

    ~WalletTxOut();
    /**
     * Return the address of this `WalletTxOut`.
     */
    std::shared_ptr<Address> address();
    /**
     * Return the chain of this `WalletTxOut`. Can be "Chain::External" or "Chain::Internal" (change).
     */
    Chain ext_int();
    /**
     * Return the height of the block containing this output if it's confirmed.
     */
    std::optional<uint32_t> height();
    /**
     * Return the outpoint (txid and vout) of this `WalletTxOut`.
     */
    std::shared_ptr<OutPoint> outpoint();
    /**
     * Return the script pubkey of the address of this `WalletTxOut`.
     */
    std::shared_ptr<Script> script_pubkey();
    /**
     * Return the unblinded values of this `WalletTxOut`.
     */
    std::shared_ptr<TxOutSecrets> unblinded();
    /**
     * Return the wildcard index used to derive the address of this `WalletTxOut`.
     */
    uint32_t wildcard_index();

    private:
    WalletTxOut(const WalletTxOut &);

    WalletTxOut(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterWebHook;
} // namespace uniffi

struct WebHook



{
    friend uniffi::FfiConverterWebHook;

    WebHook() = delete;

    WebHook(WebHook &&) = delete;

    WebHook &operator=(const WebHook &) = delete;
    WebHook &operator=(WebHook &&) = delete;

    ~WebHook();
    static std::shared_ptr<WebHook> init(const std::string &url, const std::vector<std::string> &status);

    private:
    WebHook(const WebHook &);

    WebHook(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterWollet;
} // namespace uniffi

/**
 * A Watch-Only wallet, wrapper over [`lwk_wollet::Wollet`]
 */
struct Wollet



{
    friend uniffi::FfiConverterWollet;

    Wollet() = delete;

    Wollet(Wollet &&) = delete;

    Wollet &operator=(const Wollet &) = delete;
    Wollet &operator=(Wollet &&) = delete;

    ~Wollet();
    /**
     * Construct a Watch-Only wallet object
     */
    static std::shared_ptr<Wollet> init(const std::shared_ptr<Network> &network, const std::shared_ptr<WolletDescriptor> &descriptor, std::optional<std::string> datadir);
    /**
     * Construct a Watch-Only wallet object with a caller provided store
     */
    static std::shared_ptr<Wollet> with_custom_store(const std::shared_ptr<Network> &network, const std::shared_ptr<WolletDescriptor> &descriptor, const std::shared_ptr<ForeignStoreLink> &store);
    /**
     * Add wallet details to the PSET
     */
    std::shared_ptr<Pset> add_details(const std::shared_ptr<Pset> &pset);
    /**
     * Get a wallet address
     *
     * If Some return the address at the given index,
     * otherwise the last unused address.
     */
    std::shared_ptr<AddressResult> address(std::optional<uint32_t> index);
    /**
     * Apply a transaction to the wallet state
     *
     * Wallet transactions are normally obtained using `full_scan()`
     * and applying the resulting `Update` with `apply_update()`. However a
     * full scan involves network calls and it can take a significant amount of time.
     *
     * If the caller does not want to wait for a full scan containing the transaction, it can
     * apply the transaction to the wallet state using this function.
     *
     * Note: if this transaction is *not* returned by a next full scan, after `apply_update()` it will disappear from the
     * transactions list, will not be included in balance computations, and by the remaining
     * wollet methods.
     *
     * Calling this method, might cause `apply_update()` to fail with a
     * `Error::UpdateOnDifferentStatus`, make sure to either avoid it or handle the error properly.
     */
    void apply_transaction(const std::shared_ptr<Transaction> &tx);
    /**
     * Apply an update containing blockchain data
     *
     * To update the wallet you need to first obtain the blockchain data relevant for the wallet.
     * This can be done using `full_scan()`, which
     * returns an `Update` that contains new transaction and other data relevant for the
     * wallet.
     * The update must then be applied to the `Wollet` so that wollet methods such as
     * `balance()` or `transactions()` include the new data.
     *
     * However getting blockchain data involves network calls, so between the full scan start and
     * when the update is applied it might elapse a significant amount of time.
     * In that interval, applying any update, or any transaction using `apply_transaction()`,
     * will cause this function to return a `Error::UpdateOnDifferentStatus`.
     * Callers should either avoid applying updates and transactions, or they can catch the error and wait for a new full scan to be completed and applied.
     */
    void apply_update(const std::shared_ptr<Update> &update);
    /**
     * Get the wallet balance
     */
    std::unordered_map<AssetId, uint64_t> balance();
    /**
     * Get a copy of the wallet descriptor
     */
    std::shared_ptr<WolletDescriptor> descriptor();
    /**
     * Return the [ELIP152](https://github.com/ElementsProject/ELIPs/blob/main/elip-0152.mediawiki) deterministic wallet identifier.
     */
    std::string dwid();
    /**
     * Extract the wallet UTXOs that a PSET is creating
     */
    std::vector<std::shared_ptr<ExternalUtxo>> extract_wallet_utxos(const std::shared_ptr<Pset> &pset);
    /**
     * Finalize a PSET, returning a new PSET with the finalized inputs
     */
    std::shared_ptr<Pset> finalize(const std::shared_ptr<Pset> &pset);
    /**
     * Whether the wallet is AMP0
     */
    bool is_amp0();
    /**
     * Whether the wallet is segwit
     */
    bool is_segwit();
    /**
     * Max weight to satisfy for inputs belonging to this wallet
     */
    uint32_t max_weight_to_satisfy();
    /**
     * Get the PSET details with respect to the wallet
     */
    std::shared_ptr<PsetDetails> pset_details(const std::shared_ptr<Pset> &pset);
    /**
     * Get all the wallet transaction
     */
    std::shared_ptr<WalletTx> transaction(const std::shared_ptr<Txid> &txid);
    /**
     * Get all the wallet transactions
     */
    std::vector<std::shared_ptr<WalletTx>> transactions();
    /**
     * Get the wallet transactions with pagination
     */
    std::vector<std::shared_ptr<WalletTx>> transactions_paginated(uint32_t offset, uint32_t limit);
    /**
     * Get all the transaction outputs of the wallet, both spent and unspent
     */
    std::vector<std::shared_ptr<WalletTxOut>> txos();
    /**
     * Get the utxo with unspent transaction outputs of the wallet
     * Return utxos unblinded with a specific blinding key
     */
    std::vector<std::shared_ptr<ExternalUtxo>> unblind_utxos_with(const std::shared_ptr<SecretKey> &blinding_privkey);
    /**
     * Get the unspent transaction outputs of the wallet
     */
    std::vector<std::shared_ptr<WalletTxOut>> utxos();
    /**
     * Note this a test method but we are not feature gating in test because we need it in
     * destination language examples
     */
    std::shared_ptr<WalletTx> wait_for_tx(const std::shared_ptr<Txid> &txid, const std::shared_ptr<ElectrumClient> &client);

    private:
    Wollet(const Wollet &);

    Wollet(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterWolletBuilder;
} // namespace uniffi

/**
 * A builder for constructing a [`Wollet`].
 */
struct WolletBuilder



{
    friend uniffi::FfiConverterWolletBuilder;

    WolletBuilder() = delete;

    WolletBuilder(WolletBuilder &&) = delete;

    WolletBuilder &operator=(const WolletBuilder &) = delete;
    WolletBuilder &operator=(WolletBuilder &&) = delete;

    ~WolletBuilder();
    /**
     * Create a builder for a watch-only wallet.
     */
    static std::shared_ptr<WolletBuilder> init(const std::shared_ptr<Network> &network, const std::shared_ptr<WolletDescriptor> &descriptor);
    /**
     * Build the wallet from this builder.
     */
    std::shared_ptr<Wollet> build();
    /**
     * Set the wallet as "utxo only"
     *
     * **Experimental**: This API may change without notice.
     */
    void utxo_only(bool utxo_only);
    /**
     * Persist wallet updates in the legacy encrypted filesystem store.
     */
    void with_legacy_fs_store(const std::string &datadir);
    /**
     * Set the threshold used to merge persisted updates during build.
     *
     * **Experimental**: This API may change without notice.
     *
     * `None` disables merging (default behavior).
     */
    void with_merge_threshold(std::optional<uint32_t> merge_threshold);

    private:
    WolletBuilder(const WolletBuilder &);

    WolletBuilder(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


namespace uniffi {
    struct FfiConverterWolletDescriptor;
} // namespace uniffi

/**
 * The output descriptors, wrapper over [`lwk_wollet::WolletDescriptor`]
 */
struct WolletDescriptor



{
    friend uniffi::FfiConverterWolletDescriptor;

    WolletDescriptor() = delete;

    WolletDescriptor(WolletDescriptor &&) = delete;

    WolletDescriptor &operator=(const WolletDescriptor &) = delete;
    WolletDescriptor &operator=(WolletDescriptor &&) = delete;

    ~WolletDescriptor();
    /**
     * Create a new descriptor from its string representation.
     */
    static std::shared_ptr<WolletDescriptor> init(const std::string &descriptor);
    /**
     * Derive the private blinding key
     */
    std::shared_ptr<SecretKey> derive_blinding_key(const std::shared_ptr<Script> &script_pubkey);
    /**
     * Whether the descriptor is AMP0
     */
    bool is_amp0();
    /**
     * Whether the descriptor is on the mainnet
     */
    bool is_mainnet();
    /**
     * Derive a scriptpubkey
     */
    std::shared_ptr<Script> script_pubkey(const Chain &ext_int, uint32_t index);
    /**
     * Return the descriptor encoded so that can be part of an URL
     */
    std::string url_encoded_descriptor();
    /**
     * Returns a string representation of the object, internally calls Rust's `Display` trait.
     */
    std::string to_string() const;

    private:
    WolletDescriptor(const WolletDescriptor &);

    WolletDescriptor(void *);

    void *_uniffi_internal_clone_pointer() const;

    void *instance = nullptr;
};


/**
 * LNURL-pay metadata response
 */
struct LnUrlPayResponse {
    /**
     * The callback URL to fetch the invoice
     */
    std::string callback;
    /**
     * Maximum amount (in millisatoshis) the service is willing to receive
     */
    uint64_t max_sendable;
    /**
     * Minimum amount (in millisatoshis) the service is willing to receive
     */
    uint64_t min_sendable;
    /**
     * Metadata describing the payment
     */
    std::string metadata;
    /**
     * The type of LNURL request (should be "payRequest")
     */
    std::string tag;
};


/**
 * Quote result containing fee breakdown for a swap
 */
struct Quote {
    /**
     * Amount the user sends (before fees)
     */
    uint64_t send_amount;
    /**
     * Amount the user will receive after fees
     */
    uint64_t receive_amount;
    /**
     * Network/miner fee in satoshis
     */
    uint64_t network_fee;
    /**
     * Boltz service fee in satoshis
     */
    uint64_t boltz_fee;
    /**
     * Minimum amount for this swap pair
     */
    uint64_t min;
    /**
     * Maximum amount for this swap pair
     */
    uint64_t max;
};


/**
 * see [`lwk_wollet::Chain`]
 */
enum class Chain: int32_t {
    /**
     * External address, shown when asked for a payment.
     * Wallet having a single descriptor are considered External
     */
    kExternal = 1,
    /**
     * Internal address, used for the change
     */
    kInternal = 2
};


enum class DescriptorBlindingKey: int32_t {
    kSlip77 = 1,
    kSlip77Rand = 2,
    kElip151 = 3
};


/**
 * Log level for logging messages
 */
enum class LogLevel: int32_t {
    /**
     * Debug level
     */
    kDebug = 1,
    /**
     * Info level
     */
    kInfo = 2,
    /**
     * Warning level
     */
    kWarn = 3,
    /**
     * Error level
     */
    kError = 4
};

namespace uniffi {
struct FfiConverterLwkError;
} // namespace uniffi

/**
 * Possible errors emitted
 */
struct LwkError: std::runtime_error {
    friend uniffi::FfiConverterLwkError;

    LwkError() : std::runtime_error("") {}
    LwkError(const std::string &what_arg) : std::runtime_error(what_arg) {}

    virtual ~LwkError() = default;

    virtual void throw_underlying() {
        throw *this;
    }

protected:
    virtual int32_t get_variant_idx() const {
        return 0;
    };
};
/**
 * Contains variants of LwkError
 */
namespace lwk_error {

struct Generic: LwkError {
    std::string msg;

    Generic() : LwkError("") {}
    Generic(const std::string &what_arg) : LwkError(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 1;
    }
};

struct GenericWithSwapId: LwkError {
    std::string msg;
    std::string swap_id;

    GenericWithSwapId() : LwkError("") {}
    GenericWithSwapId(const std::string &what_arg) : LwkError(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 2;
    }
};

struct PoisonError: LwkError {
    std::string msg;

    PoisonError() : LwkError("") {}
    PoisonError(const std::string &what_arg) : LwkError(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 3;
    }
};

struct MagicRoutingHint: LwkError {
    std::string address;
    uint64_t amount;
    std::string uri;

    MagicRoutingHint() : LwkError("") {}
    MagicRoutingHint(const std::string &what_arg) : LwkError(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 4;
    }
};

struct SwapExpired: LwkError {
    std::string swap_id;
    std::string status;

    SwapExpired() : LwkError("") {}
    SwapExpired(const std::string &what_arg) : LwkError(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 5;
    }
};

struct NoBoltzUpdate: LwkError {

    NoBoltzUpdate() : LwkError("") {}
    NoBoltzUpdate(const std::string &what_arg) : LwkError(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 6;
    }
};

struct ObjectConsumed: LwkError {

    ObjectConsumed() : LwkError("") {}
    ObjectConsumed(const std::string &what_arg) : LwkError(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 7;
    }
};

struct BoltzBackendHttpError: LwkError {
    uint16_t status;
    std::optional<std::string> error;

    BoltzBackendHttpError() : LwkError("") {}
    BoltzBackendHttpError(const std::string &what_arg) : LwkError(what_arg) {}

    void throw_underlying() override {
        throw *this;
    }

protected:
    int32_t get_variant_idx() const override {
        return 8;
    }
};
} // namespace lwk_error


/**
 * The kind/type of a payment category without the associated data
 */
enum class PaymentKind: int32_t {
    /**
     * A Bitcoin address
     */
    kBitcoinAddress = 1,
    /**
     * A Liquid address
     */
    kLiquidAddress = 2,
    /**
     * A Lightning BOLT11 invoice
     */
    kLightningInvoice = 3,
    /**
     * A Lightning BOLT12 offer
     */
    kLightningOffer = 4,
    /**
     * An LNURL
     */
    kLnUrl = 5,
    /**
     * A BIP353 payment instruction (₿user@domain)
     */
    kBip353 = 6,
    /**
     * A BIP21 URI
     */
    kBip21 = 7,
    /**
     * A BIP321 URI (BIP21 without address but with payment method)
     */
    kBip321 = 8,
    /**
     * A Liquid BIP21 URI with amount and asset
     */
    kLiquidBip21 = 9
};


enum class PaymentState: int32_t {
    kContinue = 1,
    kSuccess = 2,
    kFailed = 3
};


enum class Singlesig: int32_t {
    kWpkh = 1,
    kShWpkh = 2
};


/**
 * Asset type for swap quotes
 */
enum class SwapAsset: int32_t {
    /**
     * Lightning Bitcoin (for reverse/submarine swaps)
     */
    kLightning = 1,
    /**
     * Onchain Bitcoin (for chain swaps)
     */
    kOnchain = 2,
    /**
     * Liquid Bitcoin (onchain)
     */
    kLiquid = 3
};

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
struct FfiConverterUInt8 {
    static uint8_t lift(uint8_t);
    static uint8_t lower(uint8_t);
    static uint8_t read(RustStream &);
    static void write(RustStream &, uint8_t);
    static uint64_t allocation_size(uint8_t);
};
struct FfiConverterInt8 {
    static int8_t lift(int8_t);
    static int8_t lower(int8_t);
    static int8_t read(RustStream &);
    static void write(RustStream &, int8_t);
    static uint64_t allocation_size(int8_t);
};
struct FfiConverterUInt16 {
    static uint16_t lift(uint16_t);
    static uint16_t lower(uint16_t);
    static uint16_t read(RustStream &);
    static void write(RustStream &, uint16_t);
    static uint64_t allocation_size(uint16_t);
};
struct FfiConverterUInt32 {
    static uint32_t lift(uint32_t);
    static uint32_t lower(uint32_t);
    static uint32_t read(RustStream &);
    static void write(RustStream &, uint32_t);
    static uint64_t allocation_size(uint32_t);
};
struct FfiConverterUInt64 {
    static uint64_t lift(uint64_t);
    static uint64_t lower(uint64_t);
    static uint64_t read(RustStream &);
    static void write(RustStream &, uint64_t);
    static uint64_t allocation_size(uint64_t);
};
struct FfiConverterInt64 {
    static int64_t lift(int64_t);
    static int64_t lower(int64_t);
    static int64_t read(RustStream &);
    static void write(RustStream &, int64_t);
    static uint64_t allocation_size(int64_t);
};
struct FfiConverterFloat {
    static float lift(float);
    static float lower(float);
    static float read(RustStream &);
    static void write(RustStream &, float);
    static uint64_t allocation_size(float);
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


struct FfiConverterAddress {
    static std::shared_ptr<Address> lift(void *);
    static void *lower(const std::shared_ptr<Address> &);
    static std::shared_ptr<Address> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Address> &);
    static uint64_t allocation_size(const std::shared_ptr<Address> &);
private:
};


struct FfiConverterAddressResult {
    static std::shared_ptr<AddressResult> lift(void *);
    static void *lower(const std::shared_ptr<AddressResult> &);
    static std::shared_ptr<AddressResult> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<AddressResult> &);
    static uint64_t allocation_size(const std::shared_ptr<AddressResult> &);
private:
};


struct FfiConverterAmp0 {
    static std::shared_ptr<Amp0> lift(void *);
    static void *lower(const std::shared_ptr<Amp0> &);
    static std::shared_ptr<Amp0> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Amp0> &);
    static uint64_t allocation_size(const std::shared_ptr<Amp0> &);
private:
};


struct FfiConverterAmp0Connected {
    static std::shared_ptr<Amp0Connected> lift(void *);
    static void *lower(const std::shared_ptr<Amp0Connected> &);
    static std::shared_ptr<Amp0Connected> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Amp0Connected> &);
    static uint64_t allocation_size(const std::shared_ptr<Amp0Connected> &);
private:
};


struct FfiConverterAmp0LoggedIn {
    static std::shared_ptr<Amp0LoggedIn> lift(void *);
    static void *lower(const std::shared_ptr<Amp0LoggedIn> &);
    static std::shared_ptr<Amp0LoggedIn> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Amp0LoggedIn> &);
    static uint64_t allocation_size(const std::shared_ptr<Amp0LoggedIn> &);
private:
};


struct FfiConverterAmp0Pset {
    static std::shared_ptr<Amp0Pset> lift(void *);
    static void *lower(const std::shared_ptr<Amp0Pset> &);
    static std::shared_ptr<Amp0Pset> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Amp0Pset> &);
    static uint64_t allocation_size(const std::shared_ptr<Amp0Pset> &);
private:
};


struct FfiConverterAmp0SignerData {
    static std::shared_ptr<Amp0SignerData> lift(void *);
    static void *lower(const std::shared_ptr<Amp0SignerData> &);
    static std::shared_ptr<Amp0SignerData> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Amp0SignerData> &);
    static uint64_t allocation_size(const std::shared_ptr<Amp0SignerData> &);
private:
};


struct FfiConverterAmp2 {
    static std::shared_ptr<Amp2> lift(void *);
    static void *lower(const std::shared_ptr<Amp2> &);
    static std::shared_ptr<Amp2> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Amp2> &);
    static uint64_t allocation_size(const std::shared_ptr<Amp2> &);
private:
};


struct FfiConverterAmp2Descriptor {
    static std::shared_ptr<Amp2Descriptor> lift(void *);
    static void *lower(const std::shared_ptr<Amp2Descriptor> &);
    static std::shared_ptr<Amp2Descriptor> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Amp2Descriptor> &);
    static uint64_t allocation_size(const std::shared_ptr<Amp2Descriptor> &);
private:
};


struct FfiConverterAnyClient {
    static std::shared_ptr<AnyClient> lift(void *);
    static void *lower(const std::shared_ptr<AnyClient> &);
    static std::shared_ptr<AnyClient> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<AnyClient> &);
    static uint64_t allocation_size(const std::shared_ptr<AnyClient> &);
private:
};


struct FfiConverterAssetAmount {
    static std::shared_ptr<AssetAmount> lift(void *);
    static void *lower(const std::shared_ptr<AssetAmount> &);
    static std::shared_ptr<AssetAmount> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<AssetAmount> &);
    static uint64_t allocation_size(const std::shared_ptr<AssetAmount> &);
private:
};


struct FfiConverterAssetBlindingFactor {
    static std::shared_ptr<AssetBlindingFactor> lift(void *);
    static void *lower(const std::shared_ptr<AssetBlindingFactor> &);
    static std::shared_ptr<AssetBlindingFactor> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<AssetBlindingFactor> &);
    static uint64_t allocation_size(const std::shared_ptr<AssetBlindingFactor> &);
private:
};


struct FfiConverterBip {
    static std::shared_ptr<Bip> lift(void *);
    static void *lower(const std::shared_ptr<Bip> &);
    static std::shared_ptr<Bip> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Bip> &);
    static uint64_t allocation_size(const std::shared_ptr<Bip> &);
private:
};


struct FfiConverterBip21 {
    static std::shared_ptr<Bip21> lift(void *);
    static void *lower(const std::shared_ptr<Bip21> &);
    static std::shared_ptr<Bip21> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Bip21> &);
    static uint64_t allocation_size(const std::shared_ptr<Bip21> &);
private:
};


struct FfiConverterBip321 {
    static std::shared_ptr<Bip321> lift(void *);
    static void *lower(const std::shared_ptr<Bip321> &);
    static std::shared_ptr<Bip321> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Bip321> &);
    static uint64_t allocation_size(const std::shared_ptr<Bip321> &);
private:
};


struct FfiConverterBitcoinAddress {
    static std::shared_ptr<BitcoinAddress> lift(void *);
    static void *lower(const std::shared_ptr<BitcoinAddress> &);
    static std::shared_ptr<BitcoinAddress> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<BitcoinAddress> &);
    static uint64_t allocation_size(const std::shared_ptr<BitcoinAddress> &);
private:
};


struct FfiConverterBlockHeader {
    static std::shared_ptr<BlockHeader> lift(void *);
    static void *lower(const std::shared_ptr<BlockHeader> &);
    static std::shared_ptr<BlockHeader> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<BlockHeader> &);
    static uint64_t allocation_size(const std::shared_ptr<BlockHeader> &);
private:
};


struct FfiConverterBolt11Invoice {
    static std::shared_ptr<Bolt11Invoice> lift(void *);
    static void *lower(const std::shared_ptr<Bolt11Invoice> &);
    static std::shared_ptr<Bolt11Invoice> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Bolt11Invoice> &);
    static uint64_t allocation_size(const std::shared_ptr<Bolt11Invoice> &);
private:
};


struct FfiConverterBoltzSession {
    static std::shared_ptr<BoltzSession> lift(void *);
    static void *lower(const std::shared_ptr<BoltzSession> &);
    static std::shared_ptr<BoltzSession> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<BoltzSession> &);
    static uint64_t allocation_size(const std::shared_ptr<BoltzSession> &);
private:
};


struct FfiConverterContract {
    static std::shared_ptr<Contract> lift(void *);
    static void *lower(const std::shared_ptr<Contract> &);
    static std::shared_ptr<Contract> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Contract> &);
    static uint64_t allocation_size(const std::shared_ptr<Contract> &);
private:
};


struct FfiConverterCurrencyCode {
    static std::shared_ptr<CurrencyCode> lift(void *);
    static void *lower(const std::shared_ptr<CurrencyCode> &);
    static std::shared_ptr<CurrencyCode> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<CurrencyCode> &);
    static uint64_t allocation_size(const std::shared_ptr<CurrencyCode> &);
private:
};


struct FfiConverterElectrumClient {
    static std::shared_ptr<ElectrumClient> lift(void *);
    static void *lower(const std::shared_ptr<ElectrumClient> &);
    static std::shared_ptr<ElectrumClient> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<ElectrumClient> &);
    static uint64_t allocation_size(const std::shared_ptr<ElectrumClient> &);
private:
};


struct FfiConverterEsploraClient {
    static std::shared_ptr<EsploraClient> lift(void *);
    static void *lower(const std::shared_ptr<EsploraClient> &);
    static std::shared_ptr<EsploraClient> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<EsploraClient> &);
    static uint64_t allocation_size(const std::shared_ptr<EsploraClient> &);
private:
};


struct FfiConverterExternalUtxo {
    static std::shared_ptr<ExternalUtxo> lift(void *);
    static void *lower(const std::shared_ptr<ExternalUtxo> &);
    static std::shared_ptr<ExternalUtxo> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<ExternalUtxo> &);
    static uint64_t allocation_size(const std::shared_ptr<ExternalUtxo> &);
private:
};


struct FfiConverterForeignStore {
    static std::shared_ptr<ForeignStore> lift(void *);
    static void *lower(const std::shared_ptr<ForeignStore> &);
    static std::shared_ptr<ForeignStore> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<ForeignStore> &);
    static uint64_t allocation_size(const std::shared_ptr<ForeignStore> &);
private:
    friend struct UniffiCallbackInterfaceForeignStore;
    inline static HandleMap<ForeignStore> handle_map = {};
};


struct FfiConverterForeignStoreLink {
    static std::shared_ptr<ForeignStoreLink> lift(void *);
    static void *lower(const std::shared_ptr<ForeignStoreLink> &);
    static std::shared_ptr<ForeignStoreLink> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<ForeignStoreLink> &);
    static uint64_t allocation_size(const std::shared_ptr<ForeignStoreLink> &);
private:
};


struct FfiConverterInvoiceResponse {
    static std::shared_ptr<InvoiceResponse> lift(void *);
    static void *lower(const std::shared_ptr<InvoiceResponse> &);
    static std::shared_ptr<InvoiceResponse> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<InvoiceResponse> &);
    static uint64_t allocation_size(const std::shared_ptr<InvoiceResponse> &);
private:
};


struct FfiConverterIssuance {
    static std::shared_ptr<Issuance> lift(void *);
    static void *lower(const std::shared_ptr<Issuance> &);
    static std::shared_ptr<Issuance> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Issuance> &);
    static uint64_t allocation_size(const std::shared_ptr<Issuance> &);
private:
};


struct FfiConverterLightningPayment {
    static std::shared_ptr<LightningPayment> lift(void *);
    static void *lower(const std::shared_ptr<LightningPayment> &);
    static std::shared_ptr<LightningPayment> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<LightningPayment> &);
    static uint64_t allocation_size(const std::shared_ptr<LightningPayment> &);
private:
};


struct FfiConverterLockupResponse {
    static std::shared_ptr<LockupResponse> lift(void *);
    static void *lower(const std::shared_ptr<LockupResponse> &);
    static std::shared_ptr<LockupResponse> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<LockupResponse> &);
    static uint64_t allocation_size(const std::shared_ptr<LockupResponse> &);
private:
};


struct FfiConverterLogging {
    static std::shared_ptr<Logging> lift(void *);
    static void *lower(const std::shared_ptr<Logging> &);
    static std::shared_ptr<Logging> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Logging> &);
    static uint64_t allocation_size(const std::shared_ptr<Logging> &);
private:
    friend struct UniffiCallbackInterfaceLogging;
    inline static HandleMap<Logging> handle_map = {};
};


struct FfiConverterLoggingLink {
    static std::shared_ptr<LoggingLink> lift(void *);
    static void *lower(const std::shared_ptr<LoggingLink> &);
    static std::shared_ptr<LoggingLink> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<LoggingLink> &);
    static uint64_t allocation_size(const std::shared_ptr<LoggingLink> &);
private:
};


struct FfiConverterLwkTestEnv {
    static std::shared_ptr<LwkTestEnv> lift(void *);
    static void *lower(const std::shared_ptr<LwkTestEnv> &);
    static std::shared_ptr<LwkTestEnv> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<LwkTestEnv> &);
    static uint64_t allocation_size(const std::shared_ptr<LwkTestEnv> &);
private:
};


struct FfiConverterLwkTestStore {
    static std::shared_ptr<LwkTestStore> lift(void *);
    static void *lower(const std::shared_ptr<LwkTestStore> &);
    static std::shared_ptr<LwkTestStore> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<LwkTestStore> &);
    static uint64_t allocation_size(const std::shared_ptr<LwkTestStore> &);
private:
};


struct FfiConverterMnemonic {
    static std::shared_ptr<Mnemonic> lift(void *);
    static void *lower(const std::shared_ptr<Mnemonic> &);
    static std::shared_ptr<Mnemonic> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Mnemonic> &);
    static uint64_t allocation_size(const std::shared_ptr<Mnemonic> &);
private:
};


struct FfiConverterNetwork {
    static std::shared_ptr<Network> lift(void *);
    static void *lower(const std::shared_ptr<Network> &);
    static std::shared_ptr<Network> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Network> &);
    static uint64_t allocation_size(const std::shared_ptr<Network> &);
private:
};


struct FfiConverterOutPoint {
    static std::shared_ptr<OutPoint> lift(void *);
    static void *lower(const std::shared_ptr<OutPoint> &);
    static std::shared_ptr<OutPoint> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<OutPoint> &);
    static uint64_t allocation_size(const std::shared_ptr<OutPoint> &);
private:
};


struct FfiConverterPayment {
    static std::shared_ptr<Payment> lift(void *);
    static void *lower(const std::shared_ptr<Payment> &);
    static std::shared_ptr<Payment> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Payment> &);
    static uint64_t allocation_size(const std::shared_ptr<Payment> &);
private:
};


struct FfiConverterPosConfig {
    static std::shared_ptr<PosConfig> lift(void *);
    static void *lower(const std::shared_ptr<PosConfig> &);
    static std::shared_ptr<PosConfig> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<PosConfig> &);
    static uint64_t allocation_size(const std::shared_ptr<PosConfig> &);
private:
};


struct FfiConverterPrecision {
    static std::shared_ptr<Precision> lift(void *);
    static void *lower(const std::shared_ptr<Precision> &);
    static std::shared_ptr<Precision> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Precision> &);
    static uint64_t allocation_size(const std::shared_ptr<Precision> &);
private:
};


struct FfiConverterPreparePayResponse {
    static std::shared_ptr<PreparePayResponse> lift(void *);
    static void *lower(const std::shared_ptr<PreparePayResponse> &);
    static std::shared_ptr<PreparePayResponse> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<PreparePayResponse> &);
    static uint64_t allocation_size(const std::shared_ptr<PreparePayResponse> &);
private:
};


struct FfiConverterPset {
    static std::shared_ptr<Pset> lift(void *);
    static void *lower(const std::shared_ptr<Pset> &);
    static std::shared_ptr<Pset> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Pset> &);
    static uint64_t allocation_size(const std::shared_ptr<Pset> &);
private:
};


struct FfiConverterPsetBalance {
    static std::shared_ptr<PsetBalance> lift(void *);
    static void *lower(const std::shared_ptr<PsetBalance> &);
    static std::shared_ptr<PsetBalance> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<PsetBalance> &);
    static uint64_t allocation_size(const std::shared_ptr<PsetBalance> &);
private:
};


struct FfiConverterPsetDetails {
    static std::shared_ptr<PsetDetails> lift(void *);
    static void *lower(const std::shared_ptr<PsetDetails> &);
    static std::shared_ptr<PsetDetails> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<PsetDetails> &);
    static uint64_t allocation_size(const std::shared_ptr<PsetDetails> &);
private:
};


struct FfiConverterPsetInput {
    static std::shared_ptr<PsetInput> lift(void *);
    static void *lower(const std::shared_ptr<PsetInput> &);
    static std::shared_ptr<PsetInput> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<PsetInput> &);
    static uint64_t allocation_size(const std::shared_ptr<PsetInput> &);
private:
};


struct FfiConverterPsetOutput {
    static std::shared_ptr<PsetOutput> lift(void *);
    static void *lower(const std::shared_ptr<PsetOutput> &);
    static std::shared_ptr<PsetOutput> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<PsetOutput> &);
    static uint64_t allocation_size(const std::shared_ptr<PsetOutput> &);
private:
};


struct FfiConverterPsetSignatures {
    static std::shared_ptr<PsetSignatures> lift(void *);
    static void *lower(const std::shared_ptr<PsetSignatures> &);
    static std::shared_ptr<PsetSignatures> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<PsetSignatures> &);
    static uint64_t allocation_size(const std::shared_ptr<PsetSignatures> &);
private:
};


struct FfiConverterQuoteBuilder {
    static std::shared_ptr<QuoteBuilder> lift(void *);
    static void *lower(const std::shared_ptr<QuoteBuilder> &);
    static std::shared_ptr<QuoteBuilder> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<QuoteBuilder> &);
    static uint64_t allocation_size(const std::shared_ptr<QuoteBuilder> &);
private:
};


struct FfiConverterRecipient {
    static std::shared_ptr<Recipient> lift(void *);
    static void *lower(const std::shared_ptr<Recipient> &);
    static std::shared_ptr<Recipient> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Recipient> &);
    static uint64_t allocation_size(const std::shared_ptr<Recipient> &);
private:
};


struct FfiConverterScript {
    static std::shared_ptr<Script> lift(void *);
    static void *lower(const std::shared_ptr<Script> &);
    static std::shared_ptr<Script> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Script> &);
    static uint64_t allocation_size(const std::shared_ptr<Script> &);
private:
};


struct FfiConverterSecretKey {
    static std::shared_ptr<SecretKey> lift(void *);
    static void *lower(const std::shared_ptr<SecretKey> &);
    static std::shared_ptr<SecretKey> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<SecretKey> &);
    static uint64_t allocation_size(const std::shared_ptr<SecretKey> &);
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


struct FfiConverterSwapList {
    static std::shared_ptr<SwapList> lift(void *);
    static void *lower(const std::shared_ptr<SwapList> &);
    static std::shared_ptr<SwapList> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<SwapList> &);
    static uint64_t allocation_size(const std::shared_ptr<SwapList> &);
private:
};


struct FfiConverterTransaction {
    static std::shared_ptr<Transaction> lift(void *);
    static void *lower(const std::shared_ptr<Transaction> &);
    static std::shared_ptr<Transaction> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Transaction> &);
    static uint64_t allocation_size(const std::shared_ptr<Transaction> &);
private:
};


struct FfiConverterTxBuilder {
    static std::shared_ptr<TxBuilder> lift(void *);
    static void *lower(const std::shared_ptr<TxBuilder> &);
    static std::shared_ptr<TxBuilder> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<TxBuilder> &);
    static uint64_t allocation_size(const std::shared_ptr<TxBuilder> &);
private:
};


struct FfiConverterTxIn {
    static std::shared_ptr<TxIn> lift(void *);
    static void *lower(const std::shared_ptr<TxIn> &);
    static std::shared_ptr<TxIn> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<TxIn> &);
    static uint64_t allocation_size(const std::shared_ptr<TxIn> &);
private:
};


struct FfiConverterTxOut {
    static std::shared_ptr<TxOut> lift(void *);
    static void *lower(const std::shared_ptr<TxOut> &);
    static std::shared_ptr<TxOut> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<TxOut> &);
    static uint64_t allocation_size(const std::shared_ptr<TxOut> &);
private:
};


struct FfiConverterTxOutSecrets {
    static std::shared_ptr<TxOutSecrets> lift(void *);
    static void *lower(const std::shared_ptr<TxOutSecrets> &);
    static std::shared_ptr<TxOutSecrets> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<TxOutSecrets> &);
    static uint64_t allocation_size(const std::shared_ptr<TxOutSecrets> &);
private:
};


struct FfiConverterTxid {
    static std::shared_ptr<Txid> lift(void *);
    static void *lower(const std::shared_ptr<Txid> &);
    static std::shared_ptr<Txid> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Txid> &);
    static uint64_t allocation_size(const std::shared_ptr<Txid> &);
private:
};


struct FfiConverterUnvalidatedLiquidexProposal {
    static std::shared_ptr<UnvalidatedLiquidexProposal> lift(void *);
    static void *lower(const std::shared_ptr<UnvalidatedLiquidexProposal> &);
    static std::shared_ptr<UnvalidatedLiquidexProposal> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<UnvalidatedLiquidexProposal> &);
    static uint64_t allocation_size(const std::shared_ptr<UnvalidatedLiquidexProposal> &);
private:
};


struct FfiConverterUpdate {
    static std::shared_ptr<Update> lift(void *);
    static void *lower(const std::shared_ptr<Update> &);
    static std::shared_ptr<Update> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Update> &);
    static uint64_t allocation_size(const std::shared_ptr<Update> &);
private:
};


struct FfiConverterValidatedLiquidexProposal {
    static std::shared_ptr<ValidatedLiquidexProposal> lift(void *);
    static void *lower(const std::shared_ptr<ValidatedLiquidexProposal> &);
    static std::shared_ptr<ValidatedLiquidexProposal> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<ValidatedLiquidexProposal> &);
    static uint64_t allocation_size(const std::shared_ptr<ValidatedLiquidexProposal> &);
private:
};


struct FfiConverterValueBlindingFactor {
    static std::shared_ptr<ValueBlindingFactor> lift(void *);
    static void *lower(const std::shared_ptr<ValueBlindingFactor> &);
    static std::shared_ptr<ValueBlindingFactor> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<ValueBlindingFactor> &);
    static uint64_t allocation_size(const std::shared_ptr<ValueBlindingFactor> &);
private:
};


struct FfiConverterWalletTx {
    static std::shared_ptr<WalletTx> lift(void *);
    static void *lower(const std::shared_ptr<WalletTx> &);
    static std::shared_ptr<WalletTx> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<WalletTx> &);
    static uint64_t allocation_size(const std::shared_ptr<WalletTx> &);
private:
};


struct FfiConverterWalletTxOut {
    static std::shared_ptr<WalletTxOut> lift(void *);
    static void *lower(const std::shared_ptr<WalletTxOut> &);
    static std::shared_ptr<WalletTxOut> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<WalletTxOut> &);
    static uint64_t allocation_size(const std::shared_ptr<WalletTxOut> &);
private:
};


struct FfiConverterWebHook {
    static std::shared_ptr<WebHook> lift(void *);
    static void *lower(const std::shared_ptr<WebHook> &);
    static std::shared_ptr<WebHook> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<WebHook> &);
    static uint64_t allocation_size(const std::shared_ptr<WebHook> &);
private:
};


struct FfiConverterWollet {
    static std::shared_ptr<Wollet> lift(void *);
    static void *lower(const std::shared_ptr<Wollet> &);
    static std::shared_ptr<Wollet> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<Wollet> &);
    static uint64_t allocation_size(const std::shared_ptr<Wollet> &);
private:
};


struct FfiConverterWolletBuilder {
    static std::shared_ptr<WolletBuilder> lift(void *);
    static void *lower(const std::shared_ptr<WolletBuilder> &);
    static std::shared_ptr<WolletBuilder> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<WolletBuilder> &);
    static uint64_t allocation_size(const std::shared_ptr<WolletBuilder> &);
private:
};


struct FfiConverterWolletDescriptor {
    static std::shared_ptr<WolletDescriptor> lift(void *);
    static void *lower(const std::shared_ptr<WolletDescriptor> &);
    static std::shared_ptr<WolletDescriptor> read(RustStream &);
    static void write(RustStream &, const std::shared_ptr<WolletDescriptor> &);
    static uint64_t allocation_size(const std::shared_ptr<WolletDescriptor> &);
private:
};

struct FfiConverterTypeBoltzSessionBuilder {
    static BoltzSessionBuilder lift(RustBuffer);
    static RustBuffer lower(const BoltzSessionBuilder &);
    static BoltzSessionBuilder read(RustStream &);
    static void write(RustStream &, const BoltzSessionBuilder &);
    static uint64_t allocation_size(const BoltzSessionBuilder &);
};

struct FfiConverterTypeEsploraClientBuilder {
    static EsploraClientBuilder lift(RustBuffer);
    static RustBuffer lower(const EsploraClientBuilder &);
    static EsploraClientBuilder read(RustStream &);
    static void write(RustStream &, const EsploraClientBuilder &);
    static uint64_t allocation_size(const EsploraClientBuilder &);
};

struct FfiConverterTypeLiquidBip21 {
    static LiquidBip21 lift(RustBuffer);
    static RustBuffer lower(const LiquidBip21 &);
    static LiquidBip21 read(RustStream &);
    static void write(RustStream &, const LiquidBip21 &);
    static uint64_t allocation_size(const LiquidBip21 &);
};

struct FfiConverterTypeLnUrlPayResponse {
    static LnUrlPayResponse lift(RustBuffer);
    static RustBuffer lower(const LnUrlPayResponse &);
    static LnUrlPayResponse read(RustStream &);
    static void write(RustStream &, const LnUrlPayResponse &);
    static uint64_t allocation_size(const LnUrlPayResponse &);
};

struct FfiConverterTypeQuote {
    static Quote lift(RustBuffer);
    static RustBuffer lower(const Quote &);
    static Quote read(RustStream &);
    static void write(RustStream &, const Quote &);
    static uint64_t allocation_size(const Quote &);
};
struct FfiConverterChain {
    static Chain lift(RustBuffer);
    static RustBuffer lower(const Chain &);
    static Chain read(RustStream &);
    static void write(RustStream &, const Chain &);
    static uint64_t allocation_size(const Chain &);
};
struct FfiConverterDescriptorBlindingKey {
    static DescriptorBlindingKey lift(RustBuffer);
    static RustBuffer lower(const DescriptorBlindingKey &);
    static DescriptorBlindingKey read(RustStream &);
    static void write(RustStream &, const DescriptorBlindingKey &);
    static uint64_t allocation_size(const DescriptorBlindingKey &);
};
struct FfiConverterLogLevel {
    static LogLevel lift(RustBuffer);
    static RustBuffer lower(const LogLevel &);
    static LogLevel read(RustStream &);
    static void write(RustStream &, const LogLevel &);
    static uint64_t allocation_size(const LogLevel &);
};

struct FfiConverterLwkError {
    static std::shared_ptr<LwkError> lift(RustBuffer buf);
    static RustBuffer lower(const LwkError &);
    static std::shared_ptr<LwkError> read(RustStream &stream);
    static void write(RustStream &stream, const LwkError &);
    static uint64_t allocation_size(const LwkError &);
};
struct FfiConverterPaymentKind {
    static PaymentKind lift(RustBuffer);
    static RustBuffer lower(const PaymentKind &);
    static PaymentKind read(RustStream &);
    static void write(RustStream &, const PaymentKind &);
    static uint64_t allocation_size(const PaymentKind &);
};
struct FfiConverterPaymentState {
    static PaymentState lift(RustBuffer);
    static RustBuffer lower(const PaymentState &);
    static PaymentState read(RustStream &);
    static void write(RustStream &, const PaymentState &);
    static uint64_t allocation_size(const PaymentState &);
};
struct FfiConverterSinglesig {
    static Singlesig lift(RustBuffer);
    static RustBuffer lower(const Singlesig &);
    static Singlesig read(RustStream &);
    static void write(RustStream &, const Singlesig &);
    static uint64_t allocation_size(const Singlesig &);
};
struct FfiConverterSwapAsset {
    static SwapAsset lift(RustBuffer);
    static RustBuffer lower(const SwapAsset &);
    static SwapAsset read(RustStream &);
    static void write(RustStream &, const SwapAsset &);
    static uint64_t allocation_size(const SwapAsset &);
};
struct FfiConverterOptionalUInt8 {
    static std::optional<uint8_t> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<uint8_t>& val);
    static std::optional<uint8_t> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<uint8_t>& value);
    static uint64_t allocation_size(const std::optional<uint8_t> &val);
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
struct FfiConverterOptionalFloat {
    static std::optional<float> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<float>& val);
    static std::optional<float> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<float>& value);
    static uint64_t allocation_size(const std::optional<float> &val);
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
struct FfiConverterOptionalAddress {
    static std::shared_ptr<Address> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<Address>& val);
    static std::shared_ptr<Address> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<Address>& value);
    static uint64_t allocation_size(const std::shared_ptr<Address> &val);
};
struct FfiConverterOptionalBip21 {
    static std::shared_ptr<Bip21> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<Bip21>& val);
    static std::shared_ptr<Bip21> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<Bip21>& value);
    static uint64_t allocation_size(const std::shared_ptr<Bip21> &val);
};
struct FfiConverterOptionalBip321 {
    static std::shared_ptr<Bip321> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<Bip321>& val);
    static std::shared_ptr<Bip321> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<Bip321>& value);
    static uint64_t allocation_size(const std::shared_ptr<Bip321> &val);
};
struct FfiConverterOptionalBitcoinAddress {
    static std::shared_ptr<BitcoinAddress> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<BitcoinAddress>& val);
    static std::shared_ptr<BitcoinAddress> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<BitcoinAddress>& value);
    static uint64_t allocation_size(const std::shared_ptr<BitcoinAddress> &val);
};
struct FfiConverterOptionalBolt11Invoice {
    static std::shared_ptr<Bolt11Invoice> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<Bolt11Invoice>& val);
    static std::shared_ptr<Bolt11Invoice> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<Bolt11Invoice>& value);
    static uint64_t allocation_size(const std::shared_ptr<Bolt11Invoice> &val);
};
struct FfiConverterOptionalContract {
    static std::shared_ptr<Contract> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<Contract>& val);
    static std::shared_ptr<Contract> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<Contract>& value);
    static uint64_t allocation_size(const std::shared_ptr<Contract> &val);
};
struct FfiConverterOptionalForeignStoreLink {
    static std::shared_ptr<ForeignStoreLink> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<ForeignStoreLink>& val);
    static std::shared_ptr<ForeignStoreLink> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<ForeignStoreLink>& value);
    static uint64_t allocation_size(const std::shared_ptr<ForeignStoreLink> &val);
};
struct FfiConverterOptionalIssuance {
    static std::shared_ptr<Issuance> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<Issuance>& val);
    static std::shared_ptr<Issuance> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<Issuance>& value);
    static uint64_t allocation_size(const std::shared_ptr<Issuance> &val);
};
struct FfiConverterOptionalLightningPayment {
    static std::shared_ptr<LightningPayment> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<LightningPayment>& val);
    static std::shared_ptr<LightningPayment> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<LightningPayment>& value);
    static uint64_t allocation_size(const std::shared_ptr<LightningPayment> &val);
};
struct FfiConverterOptionalLogging {
    static std::shared_ptr<Logging> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<Logging>& val);
    static std::shared_ptr<Logging> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<Logging>& value);
    static uint64_t allocation_size(const std::shared_ptr<Logging> &val);
};
struct FfiConverterOptionalMnemonic {
    static std::shared_ptr<Mnemonic> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<Mnemonic>& val);
    static std::shared_ptr<Mnemonic> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<Mnemonic>& value);
    static uint64_t allocation_size(const std::shared_ptr<Mnemonic> &val);
};
struct FfiConverterOptionalScript {
    static std::shared_ptr<Script> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<Script>& val);
    static std::shared_ptr<Script> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<Script>& value);
    static uint64_t allocation_size(const std::shared_ptr<Script> &val);
};
struct FfiConverterOptionalSecretKey {
    static std::shared_ptr<SecretKey> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<SecretKey>& val);
    static std::shared_ptr<SecretKey> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<SecretKey>& value);
    static uint64_t allocation_size(const std::shared_ptr<SecretKey> &val);
};
struct FfiConverterOptionalTransaction {
    static std::shared_ptr<Transaction> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<Transaction>& val);
    static std::shared_ptr<Transaction> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<Transaction>& value);
    static uint64_t allocation_size(const std::shared_ptr<Transaction> &val);
};
struct FfiConverterOptionalTxid {
    static std::shared_ptr<Txid> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<Txid>& val);
    static std::shared_ptr<Txid> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<Txid>& value);
    static uint64_t allocation_size(const std::shared_ptr<Txid> &val);
};
struct FfiConverterOptionalUpdate {
    static std::shared_ptr<Update> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<Update>& val);
    static std::shared_ptr<Update> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<Update>& value);
    static uint64_t allocation_size(const std::shared_ptr<Update> &val);
};
struct FfiConverterOptionalWalletTxOut {
    static std::shared_ptr<WalletTxOut> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<WalletTxOut>& val);
    static std::shared_ptr<WalletTxOut> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<WalletTxOut>& value);
    static uint64_t allocation_size(const std::shared_ptr<WalletTxOut> &val);
};
struct FfiConverterOptionalWebHook {
    static std::shared_ptr<WebHook> lift(RustBuffer buf);
    static RustBuffer lower(const std::shared_ptr<WebHook>& val);
    static std::shared_ptr<WebHook> read(RustStream &stream);
    static void write(RustStream &stream, const std::shared_ptr<WebHook>& value);
    static uint64_t allocation_size(const std::shared_ptr<WebHook> &val);
};
struct FfiConverterOptionalTypeLiquidBip21 {
    static std::optional<LiquidBip21> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<LiquidBip21>& val);
    static std::optional<LiquidBip21> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<LiquidBip21>& value);
    static uint64_t allocation_size(const std::optional<LiquidBip21> &val);
};
struct FfiConverterOptionalSequenceTypeAssetId {
    static std::optional<std::vector<AssetId>> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<std::vector<AssetId>>& val);
    static std::optional<std::vector<AssetId>> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<std::vector<AssetId>>& value);
    static uint64_t allocation_size(const std::optional<std::vector<AssetId>> &val);
};
struct FfiConverterOptionalTypeAssetId {
    static std::optional<AssetId> lift(RustBuffer buf);
    static RustBuffer lower(const std::optional<AssetId>& val);
    static std::optional<AssetId> read(RustStream &stream);
    static void write(RustStream &stream, const std::optional<AssetId>& value);
    static uint64_t allocation_size(const std::optional<AssetId> &val);
};

struct FfiConverterSequenceString {
    static std::vector<std::string> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::string> &);
    static std::vector<std::string> read(RustStream &);
    static void write(RustStream &, const std::vector<std::string> &);
    static uint64_t allocation_size(const std::vector<std::string> &);
};

struct FfiConverterSequenceExternalUtxo {
    static std::vector<std::shared_ptr<ExternalUtxo>> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::shared_ptr<ExternalUtxo>> &);
    static std::vector<std::shared_ptr<ExternalUtxo>> read(RustStream &);
    static void write(RustStream &, const std::vector<std::shared_ptr<ExternalUtxo>> &);
    static uint64_t allocation_size(const std::vector<std::shared_ptr<ExternalUtxo>> &);
};

struct FfiConverterSequenceIssuance {
    static std::vector<std::shared_ptr<Issuance>> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::shared_ptr<Issuance>> &);
    static std::vector<std::shared_ptr<Issuance>> read(RustStream &);
    static void write(RustStream &, const std::vector<std::shared_ptr<Issuance>> &);
    static uint64_t allocation_size(const std::vector<std::shared_ptr<Issuance>> &);
};

struct FfiConverterSequenceOutPoint {
    static std::vector<std::shared_ptr<OutPoint>> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::shared_ptr<OutPoint>> &);
    static std::vector<std::shared_ptr<OutPoint>> read(RustStream &);
    static void write(RustStream &, const std::vector<std::shared_ptr<OutPoint>> &);
    static uint64_t allocation_size(const std::vector<std::shared_ptr<OutPoint>> &);
};

struct FfiConverterSequencePsetInput {
    static std::vector<std::shared_ptr<PsetInput>> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::shared_ptr<PsetInput>> &);
    static std::vector<std::shared_ptr<PsetInput>> read(RustStream &);
    static void write(RustStream &, const std::vector<std::shared_ptr<PsetInput>> &);
    static uint64_t allocation_size(const std::vector<std::shared_ptr<PsetInput>> &);
};

struct FfiConverterSequencePsetOutput {
    static std::vector<std::shared_ptr<PsetOutput>> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::shared_ptr<PsetOutput>> &);
    static std::vector<std::shared_ptr<PsetOutput>> read(RustStream &);
    static void write(RustStream &, const std::vector<std::shared_ptr<PsetOutput>> &);
    static uint64_t allocation_size(const std::vector<std::shared_ptr<PsetOutput>> &);
};

struct FfiConverterSequencePsetSignatures {
    static std::vector<std::shared_ptr<PsetSignatures>> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::shared_ptr<PsetSignatures>> &);
    static std::vector<std::shared_ptr<PsetSignatures>> read(RustStream &);
    static void write(RustStream &, const std::vector<std::shared_ptr<PsetSignatures>> &);
    static uint64_t allocation_size(const std::vector<std::shared_ptr<PsetSignatures>> &);
};

struct FfiConverterSequenceRecipient {
    static std::vector<std::shared_ptr<Recipient>> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::shared_ptr<Recipient>> &);
    static std::vector<std::shared_ptr<Recipient>> read(RustStream &);
    static void write(RustStream &, const std::vector<std::shared_ptr<Recipient>> &);
    static uint64_t allocation_size(const std::vector<std::shared_ptr<Recipient>> &);
};

struct FfiConverterSequenceTxIn {
    static std::vector<std::shared_ptr<TxIn>> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::shared_ptr<TxIn>> &);
    static std::vector<std::shared_ptr<TxIn>> read(RustStream &);
    static void write(RustStream &, const std::vector<std::shared_ptr<TxIn>> &);
    static uint64_t allocation_size(const std::vector<std::shared_ptr<TxIn>> &);
};

struct FfiConverterSequenceTxOut {
    static std::vector<std::shared_ptr<TxOut>> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::shared_ptr<TxOut>> &);
    static std::vector<std::shared_ptr<TxOut>> read(RustStream &);
    static void write(RustStream &, const std::vector<std::shared_ptr<TxOut>> &);
    static uint64_t allocation_size(const std::vector<std::shared_ptr<TxOut>> &);
};

struct FfiConverterSequenceValidatedLiquidexProposal {
    static std::vector<std::shared_ptr<ValidatedLiquidexProposal>> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::shared_ptr<ValidatedLiquidexProposal>> &);
    static std::vector<std::shared_ptr<ValidatedLiquidexProposal>> read(RustStream &);
    static void write(RustStream &, const std::vector<std::shared_ptr<ValidatedLiquidexProposal>> &);
    static uint64_t allocation_size(const std::vector<std::shared_ptr<ValidatedLiquidexProposal>> &);
};

struct FfiConverterSequenceWalletTx {
    static std::vector<std::shared_ptr<WalletTx>> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::shared_ptr<WalletTx>> &);
    static std::vector<std::shared_ptr<WalletTx>> read(RustStream &);
    static void write(RustStream &, const std::vector<std::shared_ptr<WalletTx>> &);
    static uint64_t allocation_size(const std::vector<std::shared_ptr<WalletTx>> &);
};

struct FfiConverterSequenceWalletTxOut {
    static std::vector<std::shared_ptr<WalletTxOut>> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::shared_ptr<WalletTxOut>> &);
    static std::vector<std::shared_ptr<WalletTxOut>> read(RustStream &);
    static void write(RustStream &, const std::vector<std::shared_ptr<WalletTxOut>> &);
    static uint64_t allocation_size(const std::vector<std::shared_ptr<WalletTxOut>> &);
};

struct FfiConverterSequenceOptionalWalletTxOut {
    static std::vector<std::shared_ptr<WalletTxOut>> lift(RustBuffer);
    static RustBuffer lower(const std::vector<std::shared_ptr<WalletTxOut>> &);
    static std::vector<std::shared_ptr<WalletTxOut>> read(RustStream &);
    static void write(RustStream &, const std::vector<std::shared_ptr<WalletTxOut>> &);
    static uint64_t allocation_size(const std::vector<std::shared_ptr<WalletTxOut>> &);
};

struct FfiConverterSequenceTypeAssetId {
    static std::vector<AssetId> lift(RustBuffer);
    static RustBuffer lower(const std::vector<AssetId> &);
    static std::vector<AssetId> read(RustStream &);
    static void write(RustStream &, const std::vector<AssetId> &);
    static uint64_t allocation_size(const std::vector<AssetId> &);
};

struct FfiConverterMapStringString {
    static std::unordered_map<std::string, std::string> lift(RustBuffer);
    static RustBuffer lower(const std::unordered_map<std::string, std::string> &);
    static std::unordered_map<std::string, std::string> read(RustStream &);
    static void write(RustStream &, const std::unordered_map<std::string, std::string> &);
    static uint64_t allocation_size(const std::unordered_map<std::string, std::string> &);
};

struct FfiConverterMapTypeAssetIdUInt64 {
    static std::unordered_map<AssetId, uint64_t> lift(RustBuffer);
    static RustBuffer lower(const std::unordered_map<AssetId, uint64_t> &);
    static std::unordered_map<AssetId, uint64_t> read(RustStream &);
    static void write(RustStream &, const std::unordered_map<AssetId, uint64_t> &);
    static uint64_t allocation_size(const std::unordered_map<AssetId, uint64_t> &);
};

struct FfiConverterMapTypeAssetIdInt64 {
    static std::unordered_map<AssetId, int64_t> lift(RustBuffer);
    static RustBuffer lower(const std::unordered_map<AssetId, int64_t> &);
    static std::unordered_map<AssetId, int64_t> read(RustStream &);
    static void write(RustStream &, const std::unordered_map<AssetId, int64_t> &);
    static uint64_t allocation_size(const std::unordered_map<AssetId, int64_t> &);
};
typedef struct FfiConverterString FfiConverterTypeAssetId;
} // namespace uniffi

/**
 * Derive asset id from contract and transaction input
 */
AssetId derive_asset_id(const std::shared_ptr<TxIn> &txin, const std::shared_ptr<Contract> &contract);
/**
 * Derive token id from contract and transaction input
 */
AssetId derive_token_id(const std::shared_ptr<TxIn> &txin, const std::shared_ptr<Contract> &contract);
/**
 * Whether a script pubkey is provably segwit
 */
bool is_provably_segwit(const std::shared_ptr<Script> &script_pubkey, std::shared_ptr<Script> redeem_script);
} // namespace lwk