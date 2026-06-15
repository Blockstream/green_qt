#include "swapquotecontroller.h"

#include "context.h"
#include "lwk/lwk.hpp"

#include <QDebug>
#include <QtConcurrentRun>

static QVariantMap parseQuote(const lwk::Quote& quote)
{
    return {
        { "send_amount", QString::number(quote.send_amount) },
        { "receive_amount", QString::number(quote.receive_amount) },
        { "network_fee", QString::number(quote.network_fee) },
        { "boltz_fee", QString::number(quote.boltz_fee) },
        { "min", QString::number(quote.min) },
        { "max", QString::number(quote.max) }
    };
}

class SwapQuoteControllerPrivate : public ControllerPrivate
{
public:
    QVariantMap quote;
    lwk::SwapAsset send_asset{lwk::SwapAsset::kOnchain};
    lwk::SwapAsset receive_asset{lwk::SwapAsset::kLiquid};
    bool send_amount{true};
    QString amount;
    int timer_id{-1};
};

SwapQuoteController::SwapQuoteController(QObject* parent)
    : Controller(new SwapQuoteControllerPrivate, parent)
{
    connect(this, &Controller::contextChanged, this, &SwapQuoteController::update);
}

static lwk::SwapAsset assetFromNetworkKey(const QString& key)
{
    if (key == QLatin1String("liquid")) {
        return lwk::SwapAsset::kLiquid;
    }
    if (key == QLatin1String("bitcoin")) {
        return lwk::SwapAsset::kOnchain;
    }
    if (key == QLatin1String("lightning")) {
        return lwk::SwapAsset::kLightning;
    }
    Q_UNREACHABLE();
}

static QString assetToNetworkKey(lwk::SwapAsset asset)
{
    if (asset == lwk::SwapAsset::kLiquid) {
        return QLatin1String("liquid");
    }
    if (asset == lwk::SwapAsset::kOnchain) {
        return QLatin1String("bitcoin");
    }
    if (asset == lwk::SwapAsset::kLightning) {
        return QLatin1String("lightning");
    }
    Q_UNREACHABLE();
}

void SwapQuoteController::setReceiveNetworkKey(const QString& networkKey)
{
    Q_D(SwapQuoteController);
    const auto asset = assetFromNetworkKey(networkKey);
    if (d->receive_asset == asset) return;
    d->receive_asset = asset;
    invalidate();
}

void SwapQuoteController::setSendNetworkKey(const QString& networkKey)
{
    Q_D(SwapQuoteController);
    const auto asset = assetFromNetworkKey(networkKey);
    if (d->send_asset == asset) return;
    d->send_asset = asset;
    invalidate();
}

QVariantMap SwapQuoteController::quote() const
{
    Q_D(const SwapQuoteController);
    return d->quote;
}

QString SwapQuoteController::receiveNetworkKey() const
{
    Q_D(const SwapQuoteController);
    return assetToNetworkKey(d->receive_asset);
}

QString SwapQuoteController::sendNetworkKey() const
{
    Q_D(const SwapQuoteController);
    return assetToNetworkKey(d->send_asset);
}

void SwapQuoteController::receive(const QString& amount)
{
    Q_D(SwapQuoteController);
    if (!context()) return;
    if (d->amount == amount) return;
    d->send_amount = false;
    d->amount = amount;
    invalidate();
}

void SwapQuoteController::send(const QString& amount)
{
    Q_D(SwapQuoteController);
    if (!context()) return;
    if (d->amount == amount) return;
    d->send_amount = true;
    d->amount = amount;
    invalidate();
}

void SwapQuoteController::swapNetworks()
{
    Q_D(SwapQuoteController);
    if (!context()) return;
    qSwap(d->send_asset, d->receive_asset);
    invalidate();
}

void SwapQuoteController::timerEvent(QTimerEvent *event)
{
    Q_D(SwapQuoteController);
    if (event->timerId() == d->timer_id) {
        killTimer(d->timer_id);
        d->timer_id = -1;
        update();
    }
}

void SwapQuoteController::invalidate()
{
    Q_D(SwapQuoteController);
    if (d->timer_id != -1) killTimer(d->timer_id);
    d->timer_id = startTimer(10);
}

void SwapQuoteController::update()
{
    Q_D(SwapQuoteController);
    if (!context()) return;
    if (!context()->m_boltz_session) return;

    bool ok = false;
    uint64_t satoshi = d->amount.toULongLong(&ok);
    if (!ok) {
        d->quote.clear();
        emit updated();
        return;
    }

    const auto session = context()->m_boltz_session;
    auto future = QtConcurrent::run([=, this]() -> QVariantMap {
        try {
            auto builder = d->send_amount ? session->quote(satoshi) : session->quote_receive(satoshi);

            builder->send(d->send_asset);
            builder->receive(d->receive_asset);

            return parseQuote(builder->build());
        } catch (...) {
            return {};
        }
    });

    future.then(this, [=, this](QVariantMap quote) {
        d->quote = quote;
        emit updated();
    });

    waitForFuture(future);
}
