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

class ChainSwapControllerPrivate
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
    : Controller(parent)
    , d(new ChainSwapControllerPrivate)
{
    invalidate();
}

ChainSwapController::~ChainSwapController()
{
    if (d->swap && !d->swap->lockupTransaction()) {
        context()->removeSwap(d->swap);
        d->swap->deleteLater();
    }
    delete d;
}

QString ChainSwapController::amount() const
{
    return d->amount;
}

void ChainSwapController::setAmount(const QString& amount)
{
    if (d->amount == amount) return;
    d->amount = amount;
    emit amountChanged();
    invalidate();
}

ChainSwap *ChainSwapController::swap() const
{
    return d->swap;
}

void ChainSwapController::setLockupTransaction(ChainTransaction* transaction)
{
    if (d->swap) {
        d->swap->setLockupTransaction(transaction);
    }
}

Address* ChainSwapController::refundAddress() const
{
    return d->refund_address;
}

void ChainSwapController::setRefundAddress(Address* refund_address)
{
    if (d->refund_address == refund_address) return;
    d->refund_address = refund_address;
    emit refundAddressChanged();
    invalidate();
}

Address* ChainSwapController::claimAddress() const
{
    return d->claim_address;
}

void ChainSwapController::setClaimAddress(Address* claim_address)
{
    if (d->claim_address == claim_address) return;
    d->claim_address = claim_address;
    emit claimAddressChanged();
    invalidate();
}

void ChainSwapController::invalidate()
{
    if (d->timer_id != -1) killTimer(d->timer_id);
    d->timer_id = startTimer(50);
    d->busy = true;
    emit busyChanged();
}

void ChainSwapController::timerEvent(QTimerEvent* event)
{
    if (event->timerId() == d->timer_id) {
        killTimer(d->timer_id);
        d->timer_id = -1;
        update();
    }
}

bool ChainSwapController::isValid() const
{
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
    return d->busy;
}

void ChainSwapController::update()
{
    if (!m_context->m_boltz_session) return;

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

    using Watcher = QFutureWatcher<std::pair<bool, std::shared_ptr<lwk::LockupResponse>>>;
    const auto watcher = new Watcher(this);
    const auto session = m_context->m_boltz_session;
    uint64_t amount = d->amount.toULongLong();
    watcher->setFuture(QtConcurrent::run([=, this]() -> std::pair<bool, std::shared_ptr<lwk::LockupResponse>> {
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
    }));
    connect(watcher, &Watcher::finished, this, [=, this] {
        watcher->deleteLater();
        auto result = watcher->result();
        if (!result.first) {
            d->timer_id = startTimer(200);
            return;
        }
        if (d->busy) {
            d->busy = false;
            emit busyChanged();
        }
        if (result.second) {
            d->swap = new ChainSwap(result.second, m_context);
            m_context->addSwap(d->swap);
            emit swapChanged();
        }
    });
}
