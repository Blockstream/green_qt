#include "paymentparser.h"
#include "lwk/lwk.hpp"

#include <QtConcurrentRun>
#include <QFutureWatcher>
#include <QTimerEvent>

#include <memory>

namespace {

void fill(QVariantMap& result, std::shared_ptr<lwk::BitcoinAddress> bitcoin_address)
{
    QVariantMap address;
    const bool is_mainnet = bitcoin_address->is_mainnet();
    address.insert("network", is_mainnet ? "bitcoin" : "testnet");
    address.insert("address", QString::fromStdString(bitcoin_address->to_string()));
    result.insert("address", address);
}

void fill(QVariantMap& result, std::shared_ptr<lwk::Address> liquid_address)
{
    QVariantMap address;
    const bool is_mainnet = liquid_address->network()->is_mainnet();
    address.insert("network", is_mainnet ? "liquid" : "testnet-liquid");
    address.insert("address", QString::fromStdString(liquid_address->to_string()));
    result.insert("address", address);
}

void fill(QVariantMap& result, std::shared_ptr<lwk::Bolt11Invoice> lightning_invoice) {
    QVariantMap invoice;

    if (lightning_invoice->amount_milli_satoshis().has_value()) {
        invoice.insert("amount_milli_satoshis", QString::number(*lightning_invoice->amount_milli_satoshis()));
    }
    invoice.insert("expiry_time", QString::number(lightning_invoice->expiry_time()));
    invoice.insert("invoice", QString::fromStdString(lightning_invoice->to_string()));
    invoice.insert("description", QString::fromStdString(lightning_invoice->invoice_description()));
    invoice.insert("min_final_cltv_expiry_delta", QString::number(lightning_invoice->min_final_cltv_expiry_delta()));
    invoice.insert("network", QString::fromStdString(lightning_invoice->network()).toLower());
    if (lightning_invoice->payee_pub_key().has_value()) {
        invoice.insert("payee_pub_key", QString::fromStdString(*lightning_invoice->payee_pub_key()));
    }
    invoice.insert("payment_hash", QString::fromStdString(lightning_invoice->payment_hash()));
    invoice.insert("payment_secret", QString::fromStdString(lightning_invoice->payment_secret()));
    invoice.insert("timestamp", QDateTime::fromSecsSinceEpoch(lightning_invoice->timestamp()));

    result.insert("invoice", invoice);
}

void fill(QVariantMap& result, std::shared_ptr<lwk::Bip21> uri)
{
    fill(result, uri->address());
    QVariantMap bip21;
    if (uri->amount().has_value()) {
        bip21.insert("amount", QString::number(*uri->amount()));
    }
    if (uri->label().has_value()) {
        bip21.insert("label", QString::fromStdString(*uri->label()));
    }
    if (uri->message().has_value()) {
        bip21.insert("message", QString::fromStdString(*uri->message()));
    }
    result.insert("bip21", bip21);
}

void fill(QVariantMap& result, lwk::LiquidBip21 uri)
{
    fill(result, uri.address);
    QVariantMap bip21;
    bip21.insert("asset_id", QString::fromStdString(uri.asset));
    if (uri.satoshi.has_value()) {
        bip21.insert("amount", QString::number(*uri.satoshi));
    }
    result.insert(bip21);
}

void fill(QVariantMap& result, std::shared_ptr<lwk::Payment> payment, const QVariantMap& data)
{
    if (payment->kind() == lwk::PaymentKind::kBitcoinAddress) {
        fill(result, payment->bitcoin_address());
        return;
    }

    if (payment->kind() == lwk::PaymentKind::kLiquidAddress) {
        fill(result, payment->liquid_address());
        return;
    }

    if (payment->kind() == lwk::PaymentKind::kLightningInvoice) {
        fill(result, payment->lightning_invoice());
        return;
    }

    if (payment->kind() == lwk::PaymentKind::kLightningOffer) {
        try {
            const auto lightning_payment = payment->lightning_payment();
            QVariantMap bolt12;
            bolt12.insert("offer", QString::fromStdString(*payment->lightning_offer()));
            if (lightning_payment->bolt12_offer_has_amount()) {
                lightning_payment->set_bolt12_invoice_amount_via_items(1);
                const auto amount = lightning_payment->bolt12_invoice_amount().value_or(0);
                bolt12.insert("amount", QVariant::fromValue(amount));
            }
            if (lightning_payment->description()) {
                bolt12.insert("description", QString::fromStdString(lightning_payment->description().value_or("")));
            }
            result.insert("bolt12", bolt12);
        } catch (const lwk::lwk_error::Generic& error) {
            result.insert("error", QString::fromStdString(error.msg));
        } catch (...) {
            result.insert("error", "unknown");
        }
        return;
    }

    if (payment->kind() == lwk::PaymentKind::kLnUrl) {
        QVariantMap lnurl;
        lnurl.insert("address", QString::fromStdString(*payment->lnurl()));

        try {
            const auto info = payment->resolve_lnurl_info();

            lnurl.insert("callback", QString::fromStdString(info.callback));
            lnurl.insert("max_sendable", QVariant::fromValue(info.max_sendable));
            lnurl.insert("min_sendable", QVariant::fromValue(info.min_sendable));
            lnurl.insert("metadata", QString::fromStdString(info.metadata));
            lnurl.insert("tag", QString::fromStdString(info.tag));

            if (data.contains("satoshi")) {
                try {
                    auto satoshi = data.value("satoshi").toULongLong();
                    fill(result, payment->fetch_lnurl_invoice(info, satoshi), data);
                } catch (const lwk::lwk_error::Generic& error) {
                    qDebug() << Q_FUNC_INFO << error.msg << error.what();
                    result.insert("error", QString::fromStdString(error.msg));
                } catch (...) {
                    result.insert("error", "unknown");
                }
            }

            result.insert("lnurl", lnurl);
        } catch (const lwk::lwk_error::Generic& error) {
            result.insert("error", QString::fromStdString(error.msg));
        } catch (...) {
            result.insert("error", "unknown");
        }
        return;
    }

    if (payment->kind() == lwk::PaymentKind::kBip353) {
        try {
            fill(result, payment->resolve_bip353(), data);
            result.insert("bip353", QString::fromStdString(*payment->bip353()));
        } catch (const lwk::lwk_error::Generic& error) {
            result.insert("error", QString::fromStdString(error.msg));
        } catch (...) {
            result.insert("error", "unknown");
        }
        return;
    }

    if (payment->kind() == lwk::PaymentKind::kBip21) {
        fill(result, payment->bip21());
        return;
    }

    if (payment->kind() == lwk::PaymentKind::kLiquidBip21) {
        fill(result, *payment->liquid_bip21());
        return;
    }
}

QVariantMap parse(const QString& input, const QVariantMap& data)
{
    if (input.trimmed().isEmpty()) {
        return {};
    }

    QVariantMap result;
    result.insert("input", input);

    if (!data.isEmpty()) {
        result.insert("data", data);
    }

    try {
        fill(result, lwk::Payment::init(input.trimmed().toStdString()), data);
    } catch (const lwk::lwk_error::Generic& error) {
        result.insert("error", QString::fromStdString(error.msg));
    } catch (...) {
        result.insert("error", "unknown");
    }
    return result;
}

} // namespace

class RecipientParserPrivate
{
public:
    QString input;
    QVariantMap data;
    QVariantMap recipient;
    int timer_id{-1};
    bool busy{false};
};

RecipientParser::RecipientParser(QObject* parent)
    : QObject(parent)
    , d(new RecipientParserPrivate)
{
}

RecipientParser::~RecipientParser()
{
    delete d;
}

QString RecipientParser::input() const
{
    return d->input;
}

void RecipientParser::setInput(const QString& input)
{
    if (d->input == input) return;
    d->input = input;
    emit inputChanged();
    invalidate();
}

QVariantMap RecipientParser::data() const
{
    return d->data;
}

void RecipientParser::setData(const QVariantMap& data)
{
    if (d->data== data) return;
    d->data = data;
    emit dataChanged();
    invalidate();
}

bool RecipientParser::isBusy() const
{
    return d->busy;
}

QVariantMap RecipientParser::recipient() const
{
    return d->recipient;
}

void RecipientParser::invalidate()
{
    if (d->timer_id != -1) killTimer(d->timer_id);
    d->timer_id = startTimer(50);
    d->busy = true;
    emit busyChanged();
}

void RecipientParser::timerEvent(QTimerEvent* event)
{
    if (event->timerId() == d->timer_id) {
        killTimer(d->timer_id);
        d->timer_id = -1;
        update();
    }
}

void RecipientParser::update()
{
    using Watcher = QFutureWatcher<QVariantMap>;
    auto watcher = new Watcher(this);

    connect(watcher, &Watcher::finished, this, [=, this] {
        watcher->deleteLater();
        d->busy = false;
        emit busyChanged();
        d->recipient = watcher->result();
        emit recipientChanged();
    });

    watcher->setFuture(QtConcurrent::run(parse, d->input, d->data));
}
