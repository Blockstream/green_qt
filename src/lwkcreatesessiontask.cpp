#include "lwkcreatesessiontask.h"

#include "context.h"
#include "lwk/lwk.hpp"
#include "network.h"
#include "swap.h"
#include "util.h"

#include <leveldb/db.h>

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include <wally_wrapper.h>

#include <QByteArray>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLoggingCategory>
#include <QString>
#include <QtConcurrentRun>

Q_LOGGING_CATEGORY(lcLwk, "lwk")

static lwk::LogLevel lwkMinLogLevel()
{
    const auto val = qEnvironmentVariable("GREEN_LWK_LOG_LEVEL", "info").toLower();
    if (val == "debug" || val == "trace") return lwk::LogLevel::kDebug;
    if (val == "warn" || val == "warning") return lwk::LogLevel::kWarn;
    if (val == "error") return lwk::LogLevel::kError;
    return lwk::LogLevel::kInfo;
}

struct Logger : public lwk::Logging
{
    Logger() : m_min_level(lwkMinLogLevel()) {}

    void log(const lwk::LogLevel& level, const std::string& message) override
    {
        if (level < m_min_level) return;

        switch (int(level)) {
        case 1: qCDebug(lcLwk)    << message.c_str(); break;
        case 2: qCInfo(lcLwk)     << message.c_str(); break;
        case 3: qCWarning(lcLwk)  << message.c_str(); break;
        case 4: qCCritical(lcLwk) << message.c_str(); break;
        default: return;
        }
    }

    lwk::LogLevel m_min_level;
};

struct Store : public lwk::ForeignStore
{
    static leveldb::DB* db;
    static int count;
    Store()
    {
        qDebug() << Q_FUNC_INFO << count;
        if (!db) {
            leveldb::Options options;
            options.create_if_missing = true;
            auto status = leveldb::DB::Open(options, GetDataDir("lwk").toStdString(), &db);
            Q_ASSERT(status.ok());
        }
        count++;
    }
    ~Store()
    {
        qDebug() << Q_FUNC_INFO << count;
        count--;
        if (count == 0) {
            delete db;
            db = nullptr;
        }
    }
    std::optional<std::vector<uint8_t>> get(const std::string &key) override
    {
        std::string raw;
        auto status = db->Get(leveldb::ReadOptions(), key, &raw);
        if (!status.ok()) return std::nullopt;
        return std::make_optional<std::vector<uint8_t>>(
            reinterpret_cast<const uint8_t*>(raw.data()),
            reinterpret_cast<const uint8_t*>(raw.data()) + raw.size());
    }
    void put(const std::string &key, const std::vector<uint8_t> &value) override
    {
        const auto raw = leveldb::Slice(reinterpret_cast<const char*>(value.data()), value.size());
        db->Put(leveldb::WriteOptions(), key, raw);
    }
    void remove(const std::string &key) override {
        db->Delete(leveldb::WriteOptions(), key);
    }
};

leveldb::DB* Store::db{nullptr};
int Store::count{0};

QString derive_mnemonic(bool mainnet, const QString& mnemonic, const QString& passphrase, int index)
{
    unsigned char seed_bytes[BIP39_SEED_LEN_512];

    bip39_mnemonic_to_seed512(mnemonic.toUtf8().constData(), passphrase.toUtf8().constData(), seed_bytes, BIP39_SEED_LEN_512);

    const uint32_t version = mainnet ? BIP32_VER_MAIN_PRIVATE : BIP32_VER_TEST_PRIVATE;

    ext_key key;
    bip32_key_from_seed(seed_bytes, BIP39_SEED_LEN_512, version, BIP32_FLAG_SKIP_HASH, &key);

    unsigned char entropy_bytes[HMAC_SHA512_LEN];
    size_t entropy_len;

    bip85_get_bip39_entropy(&key, NULL, 12, index, entropy_bytes, HMAC_SHA512_LEN, &entropy_len);

    char* derived_mnemonic_chars;
    bip39_mnemonic_from_bytes(nullptr, entropy_bytes, entropy_len, &derived_mnemonic_chars);

    const auto derived_mnemonic = QString::fromLatin1(derived_mnemonic_chars);

    wally_free_string(derived_mnemonic_chars);

    return derived_mnemonic;
}

LwkCreateSessionTask::LwkCreateSessionTask(Context* context)
    : ContextTask(context)
{
}

void LwkCreateSessionTask::update()
{
    if (m_status != Status::Ready) {
        return;
    }

    setStatus(Status::Active);

    if (context()->m_boltz_session) {
        setStatus(Status::Finished);
        return;
    }

    if (!context()->isMainnet()) {
        setStatus(Status::Failed);
        return;
    }

    constexpr int BOLTZ_BIP85_INDEX{26589};
    const auto m = context()->credentials().value("mnemonic").toString();
    const auto p = context()->credentials().value("bip39_passphrase").toString();
    const auto r = derive_mnemonic(context()->isMainnet(), m, p, BOLTZ_BIP85_INDEX);

    struct Result {
        std::shared_ptr<lwk::BoltzSession> session;
        std::vector<std::pair<QString, std::shared_ptr<lwk::PreparePayResponse>>> prepare_pay_responses;
        std::vector<std::shared_ptr<lwk::LockupResponse>> lockup_responses;
        std::vector<std::shared_ptr<lwk::InvoiceResponse>> invoice_responses;
        std::string swaps_infos;
    };

    auto future = QtConcurrent::run([=, this]() -> Result {
        try {
            Result result;
            auto mnemonic = lwk::Mnemonic::init(r.toStdString());
            auto network = context()->isMainnet() ? lwk::Network::mainnet() : lwk::Network::testnet();
            result.session = lwk::BoltzSession::from_builder({
                .network = network,
                .client = lwk::AnyClient::from_electrum(network->default_electrum_client()),
                .mnemonic = mnemonic,
                .logging = std::make_shared<Logger>(),
                .polling = true,
                .referral_id = "blockstream",
                .random_preimages = true,
                .store = lwk::ForeignStoreLink::init(std::make_shared<Store>())
            });

            try {
                result.session->refresh_swap_info();
                result.swaps_infos = result.session->fetch_swaps_info();
            } catch (const lwk::lwk_error::Generic& error) {
                qDebug() << Q_FUNC_INFO << "refresh_swap_info error";
            }

            auto load = [&](const std::string& swap_id) {
                auto data = result.session->get_swap_data(swap_id);
                if (!data) return;

                try {
                    const auto swap_data = QJsonDocument::fromJson(QByteArray::fromStdString(*data)).object();
                    const auto type = swap_data.value("swap_type").toString();
                    const auto last_state = swap_data.value("last_state").toString();

                    if (last_state == "swap.expired") return;
                    if (last_state == "invoice.failedToPay") return;

                    if (type == "submarine") {
                        auto invoice = swap_data.value("bolt11_invoice").toString();
                        auto prepare_pay_response = result.session->restore_prepare_pay(*data);
                        result.prepare_pay_responses.push_back(std::make_pair(invoice, prepare_pay_response));
                    } else if (type == "chain") {
                        result.lockup_responses.push_back(result.session->restore_lockup(*data));
                    } else if (type == "reverse") {
                        result.invoice_responses.push_back(result.session->restore_invoice(*data));
                    } else {
                        qWarning() << Q_FUNC_INFO << "unexpected swap type" << swap_id.c_str() << qPrintable(type);
                    }
                } catch (const lwk::lwk_error::Generic& error) {
                    qDebug() << Q_FUNC_INFO << "error: " << error.msg.c_str();
                    qDebug() << Q_FUNC_INFO << "swap: " << data->c_str();
                }
            };

            for (const auto& swap_id : result.session->pending_swap_ids()) {
                load(swap_id);
            }
            for (const auto& swap_id : result.session->completed_swap_ids()) {
                load(swap_id);
            }

            return result;
        } catch(const lwk::lwk_error::Generic& error) {
            qDebug() << Q_FUNC_INFO << "generic error";
            return {};
        } catch (...) {
            qDebug() << Q_FUNC_INFO << "unexpected error";
            return {};
        }
    });

    future.then(this, [=, this](Result result) {
        if (!result.session) {
            setStatus(Status::Failed);
            return;
        }

        for (const auto& [invoice, prepare_pay_response] : result.prepare_pay_responses) {
            context()->addSwap(new SubmarineSwap(invoice, prepare_pay_response, context()));
        }
        for (const auto& lockup_response : result.lockup_responses) {
            context()->addSwap(new ChainSwap(lockup_response, context()));
        }
        for (const auto& invoice_response : result.invoice_responses) {
            context()->addSwap(new ReverseSwap(invoice_response, context()));
        }

        context()->m_boltz_swaps_infos = QJsonDocument::fromJson(QByteArray::fromStdString(result.swaps_infos)).object();
        context()->m_boltz_session = result.session;

        setStatus(Status::Finished);
    });

    waitForFuture(future);
}
