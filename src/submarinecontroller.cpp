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
    QString payment;
    QString refund_address;
    bool busy{false};
    QVariant error;
    SubmarineSwap* swap{nullptr};
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

QString SubmarineController::payment() const
{
    return d->payment;
}

void SubmarineController::setPayment(const QString& payment)
{
    if (d->payment == payment) return;
    d->payment = payment;
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
    if (d->payment.isEmpty()) return;
    if (d->refund_address.isEmpty()) return;

    for (const auto swap : m_context->m_swaps) {
        auto submarine_swap = qobject_cast<SubmarineSwap*>(swap);
        if (submarine_swap && submarine_swap->invoice() == d->payment) {
            qDebug() << Q_FUNC_INFO << "found swap for invoice" << submarine_swap->status();
            d->busy = false;
            emit busyChanged();
            setSwap(submarine_swap);
            setError({});
            return;
        }
    }

    typedef std::variant<std::shared_ptr<lwk::PreparePayResponse>, std::pair<std::string, uint64_t>, std::string> Result;
    using Watcher = QFutureWatcher<Result>;
    const auto watcher = new Watcher(this);
    watcher->setFuture(QtConcurrent::run([=, this]() -> Result {
        try {
            auto lightning_payment = lwk::LightningPayment::init(d->payment.toStdString());
            auto address = lwk::Address::init(d->refund_address.toStdString());
            return m_context->m_boltz_session->prepare_pay(lightning_payment, address, nullptr);
        } catch (lwk::lwk_error::Generic error) {
            qDebug() << Q_FUNC_INFO << "generic error"
                << QString::fromStdString(error.msg);
            return error.msg;
        } catch (lwk::lwk_error::MagicRoutingHint error) {
            qDebug() << Q_FUNC_INFO << "magic routing hint error"
                << QString::fromStdString(error.uri)
                << QString::fromStdString(error.address)
                << error.amount;
            return std::make_pair(error.address, error.amount);
        } catch (lwk::lwk_error::BoltzBackendHttpError error) {
            qDebug() << Q_FUNC_INFO << "BoltzBackendHttpError" << error.status << QString::fromStdString(error.error.value_or("unknonw error"));
            return error.error.value_or("unknonw error");
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
            auto prepare_pay_response = std::get<0>(result);
            auto swap = new SubmarineSwap(d->payment, prepare_pay_response, context());
            context()->addSwap(swap);
            setSwap(swap);
            setError({});
            return;
        }

        if (result.index() == 1) {
            auto swap = new SubmarineSwap(QString::fromStdString(std::get<1>(result).first), std::get<1>(result).second, context());
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
