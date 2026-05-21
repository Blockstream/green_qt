#include "submarinecontroller.h"

#include "context.h"
#include "lwk/lwk.hpp"
#include "swap.h"

#include <QDebug>
#include <QtConcurrentRun>

#include <string>
#include <utility>

class SubmarineControllerPrivate {
public:
    int timer_id{-1};
    QVariantMap recipient;
    QString refund_address;
    bool busy{false};
    QVariant error;
    SubmarineSwap* swap{nullptr};

    std::shared_ptr<lwk::LightningPayment> payment() const
    {
        if (recipient.contains("bolt12")) {
            const auto bolt12 = recipient.value("bolt12").toMap();
            const auto data = recipient.value("data").toMap();
            const auto offer = bolt12.value("offer").toString();

            auto lightning_payment = lwk::LightningPayment::init(offer.toStdString());

            if (lightning_payment->bolt12_offer_has_amount()) {
                const auto items = data.value("items", 1).toULongLong();

                lightning_payment->set_bolt12_invoice_amount_via_items(items);
            } else {
                const auto satoshi = data.value("satoshi").toULongLong();

                lightning_payment->set_bolt12_invoice_amount(satoshi);
            }

            return lightning_payment;
        }

        if (recipient.contains("invoice")) {
            auto invoice = recipient.value("invoice").toMap().value("invoice").toString();

            auto lightning_payment = lwk::LightningPayment::init(invoice.toStdString());

            return lightning_payment;
        }

            Q_UNREACHABLE();
    }
};

SubmarineController::SubmarineController(QObject* parent)
    : Controller(parent)
    , d(new SubmarineControllerPrivate)
{
}

SubmarineController::~SubmarineController()
{
    delete d;
}

QVariantMap SubmarineController::recipient() const
{
    return d->recipient;
}

void SubmarineController::setRecipient(const QVariantMap& recipient)
{
    if (d->recipient == recipient) return;
    d->recipient = recipient;
    emit recipientChanged();
    invalidate();
}

QString SubmarineController::refundAddress() const
{
    return d->refund_address;
}

void SubmarineController::setRefundAddress(const QString& refund_address)
{
    if (d->refund_address == refund_address) return;
    d->refund_address = refund_address;
    invalidate();
}

bool SubmarineController::isBusy() const
{
    return d->busy;
}

QVariant SubmarineController::error() const
{
    return d->error;
}

void SubmarineController::setError(const QVariant& error)
{
    if (d->error == error) return;
    d->error = error;
    emit errorChanged();
}

SubmarineSwap *SubmarineController::swap() const
{
    return d->swap;
}

void SubmarineController::setLockupTransaction(ChainTransaction *transaction)
{
    if (d->swap) {
        d->swap->setLockupTransaction(transaction);
    }
}

void SubmarineController::setSwap(SubmarineSwap* swap)
{
    if (d->swap == swap) return;
    d->swap = swap;
    emit swapChanged();
}

void SubmarineController::invalidate()
{
    if (d->timer_id != -1) killTimer(d->timer_id);
    d->timer_id = startTimer(50);
    d->busy = true;
    emit busyChanged();
}

void SubmarineController::timerEvent(QTimerEvent* event)
{
    if (event->timerId() == d->timer_id) {
        killTimer(d->timer_id);
        d->timer_id = -1;
        update();
    }
}

void SubmarineController::update()
{
    if (!m_context->m_boltz_session) return;
    if (d->recipient.isEmpty()) return;
    if (d->refund_address.isEmpty()) return;

    {
        const auto invoice = d->recipient.value("invoice").toMap().value("invoice").toString();
        if (!invoice.isEmpty()) {
            for (const auto swap : m_context->m_swaps) {
                auto submarine_swap = qobject_cast<SubmarineSwap*>(swap);
                if (submarine_swap && submarine_swap->invoice() == invoice) {
                    if (submarine_swap->status() == Swap::Status::Pending) {
                        qDebug() << Q_FUNC_INFO << "found swap for invoice";
                        d->busy = false;
                        emit busyChanged();
                        setSwap(submarine_swap);
                        setError({});
                    } else {
                        qDebug() << Q_FUNC_INFO << "found non pending swap for invoice" << submarine_swap->status();
                        d->busy = false;
                        emit busyChanged();
                        setSwap(nullptr);
                        setError(QString("id_there_is_already_a_swap_in"));
                    }
                    return;
                }
            }
        }
    }

    typedef std::variant<std::shared_ptr<lwk::PreparePayResponse>, std::pair<std::string, uint64_t>, std::string> Result;
    using Watcher = QFutureWatcher<Result>;
    const auto watcher = new Watcher(this);
    watcher->setFuture(QtConcurrent::run([=, this]() -> Result {
        try {
            auto address = lwk::Address::init(d->refund_address.toStdString());
            return m_context->m_boltz_session->prepare_pay(d->payment(), address, nullptr);
        } catch (const lwk::lwk_error::Generic& error) {
            qDebug() << Q_FUNC_INFO << "generic error"
                << QString::fromStdString(error.msg);
            return error.msg;
        } catch (const lwk::lwk_error::MagicRoutingHint& error) {
            qDebug() << Q_FUNC_INFO << "magic routing hint error"
                << QString::fromStdString(error.uri)
                << QString::fromStdString(error.address)
                << error.amount;
            return std::make_pair(error.address, error.amount);
        } catch (const lwk::lwk_error::BoltzBackendHttpError& error) {
            qDebug() << Q_FUNC_INFO << "BoltzBackendHttpError" << error.status << QString::fromStdString(error.error.value_or("unknown error"));
            return error.error.value_or("unknown error");
        } catch (...) {
            qDebug() << Q_FUNC_INFO << "unexpected error";
            return std::string();
        }
    }));
    connect(watcher, &Watcher::finished, this, [=, this] {
        watcher->deleteLater();
        const auto result = watcher->result();
        d->busy = false;
        emit busyChanged();

        if (result.index() == 0) {
            auto invoice = d->recipient.value("invoice").toMap().value("invoice").toString();
            auto prepare_pay_response = std::get<0>(result);
            auto swap = new SubmarineSwap(invoice, prepare_pay_response, context());
            context()->addSwap(swap);
            setSwap(swap);
            setError({});
            return;
        }

        if (result.index() == 1) {
            auto swap = new SubmarineSwap(std::get<1>(result).second, QString::fromStdString(std::get<1>(result).first), context());
            context()->addSwap(swap);
            setSwap(swap);
            setError({});
            return;
        }

        qDebug() << Q_FUNC_INFO << "failed to create swap";
        setSwap(nullptr);
        const auto error = QString::fromStdString(std::get<2>(result));
        if (error.contains("a swap with this invoice exists already")) {
            setError(QString("id_there_is_already_a_swap_in"));
        } else if (error.contains("could not find route to pay invoice")) {
            setError(QString("Could not find route to pay invoice"));
        } else {
            setError(QString(error));
        }
    });
}
