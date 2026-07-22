#include "context.h"
#include "invoicecontroller.h"
#include "lwk/lwk.hpp"
#include "swap.h"

#include <QDebug>
#include <QTimerEvent>
#include <QtConcurrentRun>

#include <memory>

class InvoiceControllerPrivate : public ControllerPrivate
{
public:
    QString address;
    QString satoshi;
    QString description;
    int timer_id{-1};
    bool busy{false};
    ReverseSwap* swap{nullptr};
};

InvoiceController::InvoiceController(QObject *parent)
    : Controller(new InvoiceControllerPrivate, parent)
{
}

QString InvoiceController::address() const
{
    Q_D(const InvoiceController);
    return d->address;
}

void InvoiceController::setAddress(const QString& address)
{
    Q_D(InvoiceController);
    if (d->address == address) return;
    d->address = address;
    emit addressChanged();
    invalidate(50);
}

QString InvoiceController::satoshi() const
{
    Q_D(const InvoiceController);
    return d->satoshi;
}

void InvoiceController::setSatoshi(const QString& satoshi)
{
    Q_D(InvoiceController);
    if (d->satoshi == satoshi) return;
    d->satoshi = satoshi;
    emit satoshiChanged();
    if (d->swap) {
        context()->removeSwap(d->swap);
        d->swap->deleteLater();
        setSwap(nullptr);
    }
}

QString InvoiceController::description() const
{
    Q_D(const InvoiceController);
    return d->description;
}

void InvoiceController::setDescription(const QString& description)
{
    Q_D(InvoiceController);
    if (d->description == description) return;
    d->description = description;
    emit descriptionChanged();
}

bool InvoiceController::isBusy() const
{
    Q_D(const InvoiceController);
    return d->busy;
}

ReverseSwap *InvoiceController::swap() const
{
    Q_D(const InvoiceController);
    return d->swap;
}

void InvoiceController::request()
{
    Q_D(InvoiceController);
    if (d->busy) return;
    setBusy(true);
    invalidate(50);
}

void InvoiceController::invalidate(int timeout)
{
    Q_D(InvoiceController);
    if (d->timer_id != -1) killTimer(d->timer_id);
    d->timer_id = startTimer(timeout);
}

bool InvoiceController::isValid() const
{
    Q_D(const InvoiceController);
    if (!context()) return false;
    if (!context()->m_boltz_session) return false;
    if (d->address.isEmpty()) return false;
    bool ok = false;
    auto satoshi = d->satoshi.toULongLong(&ok);
    return ok && satoshi > 0;
}

void InvoiceController::setSwap(ReverseSwap* swap)
{
    Q_D(InvoiceController);
    if (d->swap == swap) return;
    d->swap = swap;
    emit swapChanged();
}

void InvoiceController::setBusy(bool busy)
{
    Q_D(InvoiceController);
    if (d->busy == busy) return;
    d->busy = busy;
    emit busyChanged();
}

void InvoiceController::update()
{
    Q_D(InvoiceController);
    try {
        if (isValid()) {
            const auto address = lwk::Address::init(d->address.toStdString());
            const auto satoshi = d->satoshi.toULongLong();
            const auto description = d->description.isEmpty() ? std::nullopt : std::make_optional(d->description.toStdString());

            auto future = QtConcurrent::run([=, this]() -> std::shared_ptr<lwk::InvoiceResponse> {
                try {
                    return context()->m_boltz_session->invoice(satoshi, description, address, nullptr);
                } catch (const lwk::lwk_error::Generic& error) {
                    qDebug() << Q_FUNC_INFO << "generic error" << error.msg.c_str();
                    return nullptr;
                } catch (const lwk::lwk_error::GenericWithSwapId& error) {
                    qDebug() << Q_FUNC_INFO << "generic error" << error.swap_id.c_str() << error.msg.c_str();
                    return nullptr;
                } catch (...) {
                    qDebug() << Q_FUNC_INFO << "unknown error";
                    return nullptr;
                }
            });

            future.then(this, [=, this](std::shared_ptr<lwk::InvoiceResponse> invoice_response) {
                if (invoice_response) {
                    auto swap = new ReverseSwap(invoice_response, context());
                    setSwap(swap);
                    setBusy(false);
                    context()->addSwap(swap);
                } else {
                    qDebug() << Q_FUNC_INFO << "failed to create invoice, retry";
                    invalidate(200);
                }
            });

            waitForFuture(future);

            return;
        }
    } catch (const lwk::lwk_error::Generic& error) {
        qDebug() << Q_FUNC_INFO << "generic error" << error.msg.c_str();
    } catch (const lwk::lwk_error::GenericWithSwapId& error) {
        qDebug() << Q_FUNC_INFO << "generic error" << error.swap_id.c_str() << error.msg.c_str();
    }
    setSwap(nullptr);
    setBusy(false);
}

void InvoiceController::timerEvent(QTimerEvent* event)
{
    Q_D(InvoiceController);
    if (event->timerId() == d->timer_id) {
        killTimer(d->timer_id);
        d->timer_id = -1;
        update();
    }
}
