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

bool SwapQuoteController::isLightning() const
{
    return d->send_asset == lwk::SwapAsset::kLightning || d->receive_asset == lwk::SwapAsset::kLightning;
}

void SwapQuoteController::setLightning(bool lightning)
{
    if (d->send_asset == lwk::SwapAsset::kOnchain) {
        d->send_asset = lwk::SwapAsset::kLightning;
    } else if (d->receive_asset == lwk::SwapAsset::kOnchain) {
        d->receive_asset = lwk::SwapAsset::kLightning;
    }
    update();
}

static lwk::SwapAsset assetFromNetworkKey(const QString& key)
{
    return key == QLatin1String("liquid") ? lwk::SwapAsset::kLiquid : lwk::SwapAsset::kOnchain;
}

void SwapQuoteController::setReceiveNetworkKey(const QString& networkKey)
{
    const auto asset = assetFromNetworkKey(networkKey);
    if (d->receive_asset == asset) return;
    d->receive_asset = asset;
}

void SwapQuoteController::setSendNetworkKey(const QString& networkKey)
{
    const auto asset = assetFromNetworkKey(networkKey);
    if (d->send_asset == asset) return;
    d->send_asset = asset;
}

QVariantMap SwapQuoteController::quote() const
{
    return d->quote;
}

QString SwapQuoteController::receiveNetworkKey() const
{
    return d->receive_asset == lwk::SwapAsset::kLiquid ? "liquid" : "bitcoin";
}

QString SwapQuoteController::sendNetworkKey() const
{
    return d->send_asset == lwk::SwapAsset::kLiquid ? "liquid" : "bitcoin";
}

void SwapQuoteController::receive(const QString& amount)
{
    if (!context()) return;
    if (d->amount == amount) return;
    d->send_amount = false;
    d->amount = amount;
    update();
}

void SwapQuoteController::send(const QString& amount)
{
    if (!context()) return;
    if (d->amount == amount) return;
    d->send_amount = true;
    d->amount = amount;
    update();
}

void SwapQuoteController::swapNetworks()
{
    if (!context()) return;
    qSwap(d->send_asset, d->receive_asset);
    update();
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
        emit updated();
    });
}
