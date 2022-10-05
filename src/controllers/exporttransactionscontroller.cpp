#include "exporttransactionscontroller.h"

#include "account.h"
#include "asset.h"
#include "device.h"
#include "handlers/gettransactionshandler.h"
#include "network.h"
#include "resolver.h"
#include "transaction.h"
#include "wallet.h"

#include <QFile>
#include <QFileDialog>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>

ExportTransactionsController::ExportTransactionsController(QObject *parent) : QObject(parent)
{
}

void ExportTransactionsController::setAccount(Account *account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged(m_account);
}

void ExportTransactionsController::save()
{
    Q_ASSERT(m_account);
    auto wallet = m_account->wallet();
    auto settings = wallet->settings();

    const auto now = QDateTime::currentDateTime();
    const auto account_name = m_account->name().isEmpty() ? qtTrId("id_main_account") : m_account->name();
    const QString suggestion =
            QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + QDir::separator() +
            wallet->name() + " - " + account_name + " - " +
            now.toString("yyyyMMddhhmmss") + ".csv";
    m_file_name = QFileDialog::getSaveFileName(nullptr, "Export to CSV", suggestion);
    if (m_file_name.isEmpty()) {
        emit saved();
        return;
    }

    const auto pricing = settings.value("pricing").toObject();

    m_fee_field = QString("fee (%1)").arg(wallet->network()->isLiquid() ? "L-" + settings.value("unit").toString() : settings.value("unit").toString());
    m_fiat_field = QString("fiat (%1 %2 %3)").arg(pricing.value("currency").toString()).arg(pricing.value("exchange").toString(), now.toString(Qt::ISODate));
    m_fields = QStringList{"time", "description", "amount", "unit", m_fee_field, m_fiat_field, "txhash", "memo"};

    if (m_include_header) {
        m_lines.append(m_fields.join(m_separator));
    }

    QTimer::singleShot(1000, this, [=] { nextPage(); });
}

void ExportTransactionsController::nextPage()
{
    auto handler = new GetTransactionsHandler(m_account->pointer(), m_offset, m_count, m_account->wallet()->session());
    QObject::connect(handler, &Handler::done, this, [this, handler] {
        auto wallet = m_account->wallet();
        auto settings = wallet->settings();
        QJsonArray transactions = handler->result().value("result").toObject().value("transactions").toArray();
        for (auto value : transactions) {
            auto data = value.toObject();
            auto transaction = m_account->getOrCreateTransaction(data);
            const auto block_height = data.value("block_height").toInt();
            if (block_height == 0) continue;
            for (auto amount : transaction->m_amounts) {
                const auto asset = amount->asset();
                QStringList values;
                for (auto field : m_fields) {
                    if (field == "time") {
                        const auto created_at_ts = data.value("created_at_ts").toDouble();
                        const auto created_at = QDateTime::fromMSecsSinceEpoch(created_at_ts / 1000);
                        values.append(QLocale::system().toString(created_at));
                    } else if (field == "description") {
                        values.append(data.value("type").toString());
                    } else if (field == "amount") {
                        values.append(amount->formatAmount(false).replace(",", "."));
                    } else if (field == "unit") {
                        if (asset && !asset->isLBTC()) {
                            values.append(asset->data().value("ticker").toString());
                        } else if (asset && asset->isLBTC()) {
                            values.append("L-" + settings.value("unit").toString());
                        } else {
                            values.append(settings.value("unit").toString());
                        }
                    } else if (field == m_fee_field) {
                        if (data.value("type").toString() == "outgoing") {
                            values.append(wallet->formatAmount(data.value("fee").toInt(), false).replace(",", "."));
                        } else {
                            values.append("");
                        }
                    } else if (field == m_fiat_field) {
                        if (asset && !asset->isLBTC()) {
                            values.append("");
                        } else {
                            values.append(wallet->convert({{ "satoshi", amount->amount() }}).value("fiat").toString());
                        }
                    } else if (field == "txhash") {
                        values.append(data.value("txhash").toString());
                    } else if (field == "memo") {
                        values.append(data.value("memo").toString().replace("\n", " ").replace(",", "-"));
                    } else {
                        Q_UNREACHABLE();
                    }
                }
                m_lines.append(values.join(m_separator));
            }
        }
        if (transactions.size() < m_count) {
            QFile file(m_file_name);
            bool result = file.open(QFile::WriteOnly);
            Q_ASSERT(result);

            QTextStream stream(&file);
            stream << m_lines.join("\n");
            emit saved();
        } else {
            m_offset += m_count;
            QTimer::singleShot(100, this, [=] { nextPage(); });
        }
    });

    connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });

    handler->exec();
}
