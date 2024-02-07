#include "exporttransactionscontroller.h"

#include "account.h"
#include "asset.h"
#include "context.h"
#include "device.h"
#include "network.h"
#include "resolver.h"
#include "session.h"
#include "task.h"
#include "transaction.h"
#include "wallet.h"

#include <QDesktopServices>
#include <QFile>
#include <QFileDialog>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>
#include <QUrl>

ExportTransactionsController::ExportTransactionsController(QObject* parent)
    : Controller(parent)
{
}

void ExportTransactionsController::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();

    auto wallet = account->context()->wallet();
    connect(wallet, &Wallet::contextChanged, this, [=] {
        if (!wallet->context()) {
            emit finished();
        }
    });
}

void ExportTransactionsController::save()
{
    Q_ASSERT(m_account);
    const auto context = m_account->context();
    const auto wallet = context->wallet();

    m_datetime = QDateTime::currentDateTime();

    const auto account_name = m_account->name().isEmpty() ? qtTrId("id_main_account") : m_account->name();
    const QString suggestion =
            QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + QDir::separator() +
            wallet->name() + " - " + account_name + " - " +
            m_datetime.toString("yyyyMMddhhmmss") + ".csv";

    auto dialog = new QFileDialog(nullptr, "Save As", suggestion);
    dialog->setAcceptMode(QFileDialog::AcceptSave);
    dialog->setFileMode(QFileDialog::AnyFile);
    dialog->selectFile(suggestion);
    connect(dialog, &QFileDialog::fileSelected, this, &ExportTransactionsController::saveToFile);
    connect(dialog, &QFileDialog::rejected, this, &ExportTransactionsController::rejected);
    connect(this, &QObject::destroyed, dialog, &QFileDialog::deleteLater);
    dialog->open();
}

void ExportTransactionsController::saveToFile(const QString& file)
{
    m_file_name = file;
    if (m_file_name.isEmpty()) {
        emit finished();
        return;
    }
    const auto context = m_account->context();
    const auto network = m_account->network();
    const auto session = m_account->session();
    const auto settings = session->settings();

    const auto display_unit = session->displayUnit();
    const auto pricing = settings.value("pricing").toObject();
    const auto currency = network->isMainnet() ? pricing.value("currency").toString() : "FIAT";
    const auto exchange = pricing.value("exchange").toString();

    m_fee_field = QString("fee (%1)").arg(display_unit);
    m_fiat_field = QString("fiat (%1 %2 %3)").arg(currency, exchange, m_datetime.toString(Qt::ISODate));
    m_fields = QStringList{"time", "description", "amount", "unit", m_fee_field, m_fiat_field, "txhash", "memo"};

    if (m_include_header) {
        m_lines.append(m_fields.join(m_separator));
    }

    QTimer::singleShot(100, this, [=] { nextPage(); });
}

void ExportTransactionsController::nextPage()
{
    const auto context = m_account->context();
    const auto wallet = context->wallet();
    const auto network = m_account->network();
    const auto session = m_account->session();
    const auto settings = session->settings();
    const auto unit = session->unit().toLower().replace("µbtc", "ubtc");
    const auto display_unit = session->displayUnit();
    auto get_transactions = new GetTransactionsTask(m_offset, m_count, m_account);
    connect(get_transactions, &Task::finished, this, [=] {
        const auto transactions = get_transactions->transactions();
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
                        values.append(created_at.toString(Qt::ISODate));
                    } else if (field == "description") {
                        values.append(data.value("type").toString());
                    } else if (field == "amount") {
                        const double satoshi = amount->amount();
                        if (asset && asset->id() != network->policyAsset()) {
                            const auto precision = asset->data().value("precision").toInt(0);
                            const auto value = static_cast<double>(satoshi) / qPow(10, precision);
                            values.append(QString::number(value, 'f', precision));
                        } else {
                            const auto converted = wallet->convert({{ "satoshi", satoshi }});
                            values.append(converted.value(unit).toString());
                        }
                    } else if (field == "unit") {
                        if (asset && asset->id() != network->policyAsset()) {
                            values.append(asset->data().value("ticker").toString());
                        } else {
                            values.append(display_unit);
                        }
                    } else if (field == m_fee_field) {
                        if (data.value("type").toString() == "outgoing") {
                            const double fee = data.value("fee").toInt();
                            const auto converted = wallet->convert({{ "satoshi", fee }});
                            values.append(converted.value(unit).toString());
                        } else {
                            values.append("");
                        }
                    } else if (field == m_fiat_field) {
                        if (asset && asset->id() != network->policyAsset()) {
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

            QFileInfo info(file);
            emit saved(info.baseName(), QUrl::fromLocalFile(info.absoluteFilePath()));
        } else {
            m_offset += m_count;
            QTimer::singleShot(10, this, [=] { nextPage(); });
        }
    });

    m_context->dispatcher()->add(get_transactions);
}
