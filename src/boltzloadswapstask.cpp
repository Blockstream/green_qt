#include "boltzloadswapstask.h"

#include "context.h"
#include "lwk/lwk.hpp"
#include "swap.h"

#include <chrono>
#include <exception>
#include <memory>
#include <string>
#include <thread>
#include <typeinfo>
#include <utility>
#include <vector>

#include <QByteArray>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QString>
#include <QtConcurrentRun>

BoltzLoadSwapsTask::BoltzLoadSwapsTask(Context* context)
    : ContextTask(context)
{
}

void BoltzLoadSwapsTask::update()
{
    if (m_status != Status::Ready) {
        return;
    }

    setStatus(Status::Active);

    auto session = context()->m_boltz_session;
    if (!session) {
        setStatus(Status::Failed);
        return;
    }

    struct Result {
        std::vector<std::pair<QString, std::shared_ptr<lwk::PreparePayResponse>>> prepare_pay_responses;
        std::vector<std::shared_ptr<lwk::LockupResponse>> lockup_responses;
        std::vector<std::shared_ptr<lwk::InvoiceResponse>> invoice_responses;
        bool failed{false};
    };

    auto future = QtConcurrent::run([=, this]() -> Result {
        Result result;

        auto advance = [](const auto& response, const std::string& swap_id) {
            constexpr auto timeout = std::chrono::seconds(2);
            constexpr auto retry_interval = std::chrono::milliseconds(50);
            const auto deadline = std::chrono::steady_clock::now() + timeout;
            bool received_update{false};

            while (true) {
                try {
                    const auto state = response->advance();
                    received_update = true;
                    if (state != lwk::PaymentState::kContinue) return;
                } catch (const lwk::lwk_error::NoBoltzUpdate&) {
                    // Each restored response receives updates for every subscribed swap through
                    // the same bounded channel. Wait for its initial update before restoring the
                    // next swap, otherwise later subscriptions can overwrite that update.
                    if (received_update) return;
                    if (std::chrono::steady_clock::now() >= deadline) {
                        qWarning() << Q_FUNC_INFO << "initial update timed out for swap" << swap_id.c_str();
                        return;
                    }
                    std::this_thread::sleep_for(retry_interval);
                }
            }
        };

        auto load = [&](const std::string& swap_id, bool completed) {
            try {
                auto data = session->get_swap_data(swap_id);
                if (!data) return;

                const auto swap_data = QJsonDocument::fromJson(QByteArray::fromStdString(*data)).object();
                const auto type = swap_data.value("swap_type").toString();
                const auto last_state = swap_data.value("last_state").toString();

                if (last_state == "swap.expired") return;
                if (last_state == "invoice.failedToPay") return;

                if (type == "submarine") {
                    auto invoice = swap_data.value("bolt11_invoice").toString();
                    auto prepare_pay_response = session->restore_prepare_pay(*data);
                    if (!completed) advance(prepare_pay_response, swap_id);
                    result.prepare_pay_responses.push_back(std::make_pair(invoice, prepare_pay_response));
                } else if (type == "chain") {
                    auto lockup_response = session->restore_lockup(*data);
                    if (!completed) advance(lockup_response, swap_id);
                    result.lockup_responses.push_back(lockup_response);
                } else if (type == "reverse") {
                    auto invoice_response = session->restore_invoice(*data);
                    if (!completed) advance(invoice_response, swap_id);
                    result.invoice_responses.push_back(invoice_response);
                } else {
                    qWarning() << Q_FUNC_INFO << "unexpected swap type" << swap_id.c_str() << qPrintable(type);
                }
            } catch (const lwk::lwk_error::Generic& error) {
                qDebug() << Q_FUNC_INFO << "error: " << error.msg.c_str();
                qDebug() << Q_FUNC_INFO << "swap: " << swap_id.c_str();
            } catch (const lwk::lwk_error::GenericWithSwapId& error) {
                qDebug() << Q_FUNC_INFO << "error: " << error.msg.c_str();
                qDebug() << Q_FUNC_INFO << "swap: " << error.swap_id.c_str();
            } catch (const std::exception& error) {
                qDebug() << Q_FUNC_INFO << "error loading swap" << swap_id.c_str() << typeid(error).name() << error.what();
            }
        };

        try {
            for (const auto& swap_id : session->pending_swap_ids()) {
                load(swap_id, false);
            }
            for (const auto& swap_id : session->completed_swap_ids()) {
                load(swap_id, true);
            }
        } catch (const lwk::lwk_error::Generic& error) {
            qDebug() << Q_FUNC_INFO << "generic error" << error.msg.c_str();
            result.failed = true;
        } catch (const std::exception& error) {
            qDebug() << Q_FUNC_INFO << "error listing swaps" << typeid(error).name() << error.what();
            result.failed = true;
        } catch (...) {
            qDebug() << Q_FUNC_INFO << "unknown error listing swaps";
            result.failed = true;
        }

        return result;
    });

    future.then(this, [=, this](Result result) {
        for (const auto& [invoice, prepare_pay_response] : result.prepare_pay_responses) {
            context()->addSwap(new SubmarineSwap(invoice, prepare_pay_response, context()));
        }
        for (const auto& lockup_response : result.lockup_responses) {
            context()->addSwap(new ChainSwap(lockup_response, context()));
        }
        for (const auto& invoice_response : result.invoice_responses) {
            context()->addSwap(new ReverseSwap(invoice_response, context()));
        }

        setStatus(result.failed ? Status::Failed : Status::Finished);
    });

    waitForFuture(future);
}
