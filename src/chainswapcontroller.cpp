#include "chainswapcontroller.h"

#include "account.h"
#include "address.h"
#include "context.h"
#include "lwk/lwk.hpp"
#include "network.h"
#include "swap.h"

#include <QDebug>
#include <QJsonObject>
#include <QtConcurrentRun>

#include <algorithm>
#include <memory>
#include <utility>

class ChainSwapControllerPrivate : public ControllerPrivate
{
public:
    int timer_id{-1};
    QJsonObject swaps_info;
    Address* refund_address{nullptr};
    Address* claim_address{nullptr};
    QString amount;
    bool busy{false};
    ChainSwap* swap{nullptr};
};

ChainSwapController::ChainSwapController(QObject* parent)
    : Controller(new ChainSwapControllerPrivate, parent)
{
    invalidate();
}

ChainSwapController::~ChainSwapController()
{
    Q_D(ChainSwapController);
    if (d->swap && !d->swap->lockupTransaction()) {
        context()->removeSwap(d->swap);
        d->swap->deleteLater();
    }
}

QString ChainSwapController::amount() const
{
    Q_D(const ChainSwapController);
    return d->amount;
}

void ChainSwapController::setAmount(const QString& amount)
{
    Q_D(ChainSwapController);
    if (d->amount == amount) return;
    d->amount = amount;
    emit amountChanged();
    invalidate();
}

ChainSwap *ChainSwapController::swap() const
{
    Q_D(const ChainSwapController);
    return d->swap;
}

void ChainSwapController::setLockupTransaction(ChainTransaction* transaction)
{
    Q_D(ChainSwapController);
    if (d->swap) {
        d->swap->setLockupTransaction(transaction);
    }
}

Address* ChainSwapController::refundAddress() const
{
    Q_D(const ChainSwapController);
    return d->refund_address;
}

void ChainSwapController::setRefundAddress(Address* refund_address)
{
    Q_D(ChainSwapController);
    if (d->refund_address == refund_address) return;
    d->refund_address = refund_address;
    emit refundAddressChanged();
    invalidate();
}

Address* ChainSwapController::claimAddress() const
{
    Q_D(const ChainSwapController);
    return d->claim_address;
}

void ChainSwapController::setClaimAddress(Address* claim_address)
{
    Q_D(ChainSwapController);
    if (d->claim_address == claim_address) return;
    d->claim_address = claim_address;
    emit claimAddressChanged();
    invalidate();
}

void ChainSwapController::invalidate()
{
    Q_D(ChainSwapController);
    if (d->timer_id != -1) killTimer(d->timer_id);
    d->timer_id = startTimer(50);
    d->busy = true;
    emit busyChanged();
}

void ChainSwapController::timerEvent(QTimerEvent* event)
{
    Q_D(ChainSwapController);
    if (event->timerId() == d->timer_id) {
        killTimer(d->timer_id);
        d->timer_id = -1;
        update();
    }
}

bool ChainSwapController::isValid() const
{
    Q_D(const ChainSwapController);
    if (!context()) return false;
    if (!d->claim_address) return false;
    if (!d->refund_address) return false;
    bool ok = false;
    uint64_t amount = d->amount.toULongLong(&ok);
    if (!ok || amount == 0) return false;
    return true;
}

bool ChainSwapController::isBusy() const
{
    Q_D(const ChainSwapController);
    return d->busy;
}

void ChainSwapController::update()
{
    Q_D(ChainSwapController);
    if (!context()) return;
    if (!context()->m_boltz_session) return;

    if (!isValid()) {
        if (d->busy) {
            d->busy = false;
            emit busyChanged();
        }
        if (d->swap) {
            d->swap = nullptr;
            emit swapChanged();
        }
        return;
    }

    const auto session = context()->m_boltz_session;
    uint64_t amount = d->amount.toULongLong();
    auto future = QtConcurrent::run([=, this]() -> std::pair<bool, std::shared_ptr<lwk::LockupResponse>> {
        try {
            auto claim_network = d->claim_address->account()->network();
            auto refund_network = d->refund_address->account()->network();

            std::shared_ptr<lwk::LockupResponse> lockup_response;
            if (claim_network->isLiquid() && !refund_network->isLiquid()) {
                auto refund_address = lwk::BitcoinAddress::init(d->refund_address->address().toStdString());
                auto claim_address = lwk::Address::init(d->claim_address->address().toStdString());

                lockup_response = session->btc_to_lbtc(amount, refund_address, claim_address, nullptr);
            }
            if (!claim_network->isLiquid() && refund_network->isLiquid()) {
                auto refund_address = lwk::Address::init(d->refund_address->address().toStdString());
                auto claim_address = lwk::BitcoinAddress::init(d->claim_address->address().toStdString());

                lockup_response = session->lbtc_to_btc(amount, refund_address, claim_address, nullptr);
            }
            return std::make_pair(true, lockup_response);
        } catch (...) {
            return std::make_pair(false, nullptr);
        }
    });

    future.then(this, [=, this](std::pair<bool, std::shared_ptr<lwk::LockupResponse>> result) {
        if (!result.first) {
            d->timer_id = startTimer(200);
            return;
        }
        if (d->busy) {
            d->busy = false;
            emit busyChanged();
        }
        if (result.second) {
            d->swap = new ChainSwap(result.second, context());
            context()->addSwap(d->swap);
            emit swapChanged();
        }
    });

    waitForFuture(future);
}
