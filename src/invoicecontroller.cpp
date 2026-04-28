#include "context.h"
#include "invoicecontroller.h"
#include "lwk/lwk.hpp"
#include "swap.h"

#include <QDebug>
#include <QtConcurrentRun>

#include <memory>

class InvoiceControllerPrivate
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
    : Controller(parent)
    , d(new InvoiceControllerPrivate)
{
}

InvoiceController::~InvoiceController()
{
    delete d;
}

QString InvoiceController::address() const
{
    return d->address;
}

void InvoiceController::setAddress(const QString& address)
{
    if (d->address == address) return;
    d->address = address;
    emit addressChanged();
    invalidate(50);
}

QString InvoiceController::satoshi() const
{
    return d->satoshi;
}

void InvoiceController::setSatoshi(const QString& satoshi)
{
    if (d->satoshi == satoshi) return;
    d->satoshi = satoshi;
    emit satoshiChanged();
    if (d->swap) {
        m_context->removeSwap(d->swap);
        d->swap->deleteLater();
        setSwap(nullptr);
    }
}

QString InvoiceController::description() const
{
    return d->description;
}

void InvoiceController::setDescription(const QString& description)
{
    if (d->description == description) return;
    d->description = description;
    emit descriptionChanged();
}

bool InvoiceController::isBusy() const
{
    return d->busy;
}

ReverseSwap *InvoiceController::swap() const
{
    return d->swap;
}

void InvoiceController::request()
{
    if (d->busy) return;
    setBusy(true);
    invalidate(50);
}

void InvoiceController::invalidate(int timeout)
{
    if (d->timer_id != -1) killTimer(d->timer_id);
    d->timer_id = startTimer(timeout);
}

bool InvoiceController::isValid() const
{
    if (!m_context) return false;
    if (!m_context->m_boltz_session) return false;
    if (d->address.isEmpty()) return false;
    bool ok = false;
    auto satoshi = d->satoshi.toULongLong(&ok);
    return ok && satoshi > 0;
}

void InvoiceController::setSwap(ReverseSwap* swap)
{
    if (d->swap == swap) return;
    d->swap = swap;
    emit swapChanged();
}

void InvoiceController::setBusy(bool busy)
{
    if (d->busy == busy) return;
    d->busy = busy;
    emit busyChanged();
}

void InvoiceController::update()
{
    try {
        if (isValid()) {
            const auto address = lwk::Address::init(d->address.toStdString());
            const auto satoshi = d->satoshi.toULongLong();
            const auto description = d->description.isEmpty() ? std::nullopt : std::make_optional(d->description.toStdString());

            using Watcher = QFutureWatcher<std::shared_ptr<lwk::InvoiceResponse>>;
            const auto watcher = new Watcher(this);
            watcher->setFuture(QtConcurrent::run([=, this]() -> std::shared_ptr<lwk::InvoiceResponse> {
                try {
                    return m_context->m_boltz_session->invoice(satoshi, description, address, nullptr);
                } catch (lwk::lwk_error::Generic error) {
                    qDebug() << Q_FUNC_INFO << "generic error";
                    return nullptr;
                } catch (...) {
                    qDebug() << Q_FUNC_INFO << "unknown error";
                    return nullptr;
                }
            }));
            connect(watcher, &Watcher::finished, this, [=, this] {
                watcher->deleteLater();
                auto invoice_response = watcher->result();
                if (invoice_response) {
                    auto swap = new ReverseSwap(invoice_response, m_context);
                    setSwap(swap);
                    setBusy(false);
                    m_context->addSwap(swap);
                } else {
                    qDebug() << Q_FUNC_INFO << "failed to create invoice, retry";
                    invalidate(200);
                }
            });
            return;
        }
    } catch (lwk::lwk_error::Generic error) {
        qDebug() << Q_FUNC_INFO << error.what();
    }

    setSwap(nullptr);
    setBusy(false);
}

void InvoiceController::timerEvent(QTimerEvent* event)
{
    if (event->timerId() == d->timer_id) {
        killTimer(d->timer_id);
        d->timer_id = -1;
        update();
    }
}
