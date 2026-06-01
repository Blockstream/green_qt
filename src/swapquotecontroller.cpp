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

class SwapQuoteControllerPrivate
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
    : Controller(parent)
    , d(new SwapQuoteControllerPrivate)
{
    connect(this, &Controller::contextChanged, this, &SwapQuoteController::update);
}

SwapQuoteController::~SwapQuoteController()
{
    delete d;
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
    const auto asset = assetFromNetworkKey(networkKey);
    if (d->receive_asset == asset) return;
    d->receive_asset = asset;
    invalidate();
}

void SwapQuoteController::setSendNetworkKey(const QString& networkKey)
{
    const auto asset = assetFromNetworkKey(networkKey);
    if (d->send_asset == asset) return;
    d->send_asset = asset;
    invalidate();
}

QVariantMap SwapQuoteController::quote() const
{
    return d->quote;
}

QString SwapQuoteController::receiveNetworkKey() const
{
    return assetToNetworkKey(d->receive_asset);
}

QString SwapQuoteController::sendNetworkKey() const
{
    return assetToNetworkKey(d->send_asset);
}

void SwapQuoteController::receive(const QString& amount)
{
    if (!context()) return;
    if (d->amount == amount) return;
    d->send_amount = false;
    d->amount = amount;
    invalidate();
}

void SwapQuoteController::send(const QString& amount)
{
    if (!context()) return;
    if (d->amount == amount) return;
    d->send_amount = true;
    d->amount = amount;
    invalidate();
}

void SwapQuoteController::swapNetworks()
{
    if (!context()) return;
    qSwap(d->send_asset, d->receive_asset);
    invalidate();
}

void SwapQuoteController::timerEvent(QTimerEvent *event)
{
    if (event->timerId() == d->timer_id) {
        killTimer(d->timer_id);
        d->timer_id = -1;
        update();
    }
}

void SwapQuoteController::invalidate()
{
    if (d->timer_id != -1) killTimer(d->timer_id);
    d->timer_id = startTimer(10);
}

void SwapQuoteController::update()
{
    if (!m_context) return;
    if (!m_context->m_boltz_session) return;

    bool ok = false;
    uint64_t satoshi = d->amount.toULongLong(&ok);
    if (!ok) {
        d->quote.clear();
        emit updated();
        return;
    }

    using Watcher = QFutureWatcher<QVariantMap>;
    const auto watcher = new Watcher(this);
    const auto session = m_context->m_boltz_session;
    watcher->setFuture(QtConcurrent::run([=, this]() -> QVariantMap {
        try {
            auto builder = d->send_amount ? session->quote(satoshi) : session->quote_receive(satoshi);

            builder->send(d->send_asset);
            builder->receive(d->receive_asset);

            return parseQuote(builder->build());
        } catch (...) {
            return {};
        }
    }));
    connect(watcher, &Watcher::finished, this, [=, this] {
        watcher->deleteLater();
        d->quote = watcher->result();

        if (d->send_asset == lwk::SwapAsset::kLiquid && d->receive_asset == lwk::SwapAsset::kLightning) {
            const auto submarine = m_context->m_boltz_swaps_infos.value("submarine").toObject();
            const auto lbtc = submarine.value("L-BTC").toObject();
            const auto btc = lbtc.value("BTC").toObject();
            const auto limits = btc.value("limits").toObject();
            const auto minimalBatched = limits.value("minimalBatched").toInt();
            d->quote.insert("min", minimalBatched);
        }

        emit updated();
    });
}
