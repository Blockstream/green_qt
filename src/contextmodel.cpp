#include "contextmodel.h"
#include "account.h"
#include "address.h"
#include "asset.h"
#include "context.h"
#include "network.h"
#include "output.h"
#include "payment.h"
#include "session.h"
#include "transaction.h"
#include "wallet.h"
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QStandardPaths>
#include <QTextStream>
#include <QUrl>

#include <algorithm>

ContextModel::ContextModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    sort(0, Qt::DescendingOrder);
}

void ContextModel::setContext(Context* context)
{
    if (m_context == context) return;
    if (m_context) {
        setSourceModel(nullptr);
    }
    m_context = context;
    if (m_context) {
        update(context);
    }
    emit contextChanged();
}

QQmlListProperty<Account> ContextModel::filterAccounts()
{
    return { this, &m_filter_accounts };
}

QQmlListProperty<Asset> ContextModel::filterAssets()
{
    return { this, &m_filter_assets };
}

void ContextModel::setFilterText(const QString& filter_text)
{
    if (m_filter_text == filter_text) return;
    m_filter_text = filter_text;
    emit filterTextChanged();
    invalidate();
}

void ContextModel::clearFilters()
{
    m_filter_accounts.clear();
    emit filterAccountsChanged();
    m_filter_assets.clear();
    emit filterAssetsChanged();
    m_filter_text.clear();
    emit filterTextChanged();
    m_filter_types.clear();
    emit filterTypesChanged();
    m_filter_statuses.clear();
    emit filterStatusesChanged();
    m_filter_has_transactions = false;
    emit filterHasTransactionsChanged();
    invalidate();
}

void ContextModel::setFilterAccount(Account* account)
{
    m_filter_accounts.clear();
    m_filter_accounts.append(account);
    emit filterAccountsChanged();
    invalidate();
}

void ContextModel::setFilterAsset(Asset* asset)
{
    m_filter_assets.clear();
    m_filter_assets.append(asset);
    emit filterAssetsChanged();
    invalidate();
}

void ContextModel::updateFilterAccounts(Account* account, bool filter)
{
    if (filter) {
        if (m_filter_accounts.contains(account)) return;
        m_filter_accounts.append(account);
    } else {
        if (!m_filter_accounts.contains(account)) return;
        m_filter_accounts.removeOne(account);
    }
    emit filterAccountsChanged();
    invalidate();
}

void ContextModel::updateFilterAssets(Asset* asset, bool filter)
{
    if (filter) {
        if (m_filter_assets.contains(asset)) return;
        m_filter_assets.append(asset);
    } else {
        if (!m_filter_assets.contains(asset)) return;
        m_filter_assets.removeOne(asset);
    }
    emit filterAssetsChanged();
    invalidate();
}

void ContextModel::updateFilterTypes(const QString& type, bool filter)
{
    if (filter) {
        if (m_filter_types.contains(type)) return;
        m_filter_types.append(type);
    } else {
        if (!m_filter_types.contains(type)) return;
        m_filter_types.removeOne(type);
    }
    emit filterTypesChanged();
    invalidate();
}

void ContextModel::updateFilterStatuses(const QString& status, bool filter)
{
    if (filter) {
        if (m_filter_statuses.contains(status)) return;
        m_filter_statuses.append(status);
    } else {
        if (!m_filter_statuses.contains(status)) return;
        m_filter_statuses.removeOne(status);
    }
    emit filterStatusesChanged();
    invalidate();
}

void ContextModel::updateFilterHasTransactions(bool filter)
{
    if (m_filter_has_transactions == filter) return;
    m_filter_has_transactions = filter;
    emit filterHasTransactionsChanged();
    invalidate();
}

void ContextModel::exportToFile()
{
}

TransactionModel::TransactionModel(QObject* parent)
    : ContextModel(parent)
{
    setSortRole(Qt::UserRole + 1);
}

void TransactionModel::exportToFile()
{
    auto datetime = QDateTime::currentDateTime();

    const QString suggestion =
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + QDir::separator() +
        context()->wallet()->name() + " - transactions - " +
        datetime.toString("yyyyMMddhhmmss") + ".csv";

    auto dialog = new QFileDialog(nullptr, "Save As", suggestion);
    dialog->setAcceptMode(QFileDialog::AcceptSave);
    dialog->setFileMode(QFileDialog::AnyFile);
    dialog->selectFile(suggestion);
    connect(dialog, &QFileDialog::fileSelected, this, [=, this](const QString& filename) {
        if (filename.isEmpty()) return;

        const auto wallet = context()->wallet();
        const auto session = context()->primarySession();
        const auto settings = session->settings();
        const auto display_unit = session->displayUnit();
        const auto pricing = settings.value("pricing").toObject();
        const auto currency = session->network()->isMainnet() ? pricing.value("currency").toString() : "FIAT";
        const auto exchange = pricing.value("exchange").toString();
        const auto unit = session->unit().toLower().replace("µbtc", "ubtc");

        QString fee_field = QString("fee (%1)").arg(display_unit);
        QString fiat_field = QString("fiat (%1 %2 %3)").arg(currency, exchange, datetime.toString(Qt::ISODate));
        QStringList fields = QStringList{"time", "network", "account", "description", "amount", "unit", fee_field, fiat_field, "txhash", "memo"};
        QStringList lines;
        QString separator{","};

        lines.append(fields.join(separator));

        const auto row_count = rowCount();
        for (int row = 0; row < row_count; ++row) {
            const auto transaction = index(row, 0).data(Qt::UserRole).value<AccountTransaction*>();
            if (!transaction) continue;
            const auto network = transaction->account()->network();
            const auto data = transaction->data();
            const auto block_height = data.value("block_height").toInt();

            if (block_height == 0) continue;
            QJsonObject satoshi = transaction->data().value("satoshi").toObject();
            for (auto i = satoshi.begin(); i != satoshi.end(); ++i) {
                const auto asset = context()->getOrCreateAsset(i.key());
                QStringList values;
                for (auto field : fields) {
                    if (field == "network") {
                        values.append(network->displayName());
                    } else if (field == "account") {
                        auto name = transaction->account()->name();
                        values.append(name.isEmpty() ? qtTrId("id_main_account") : name);
                    } else if (field == "time") {
                        const auto created_at_ts = data.value("created_at_ts").toDouble();
                        const auto created_at = QDateTime::fromMSecsSinceEpoch(created_at_ts / 1000);
                        values.append(created_at.toString(Qt::ISODate));
                    } else if (field == "description") {
                        values.append(data.value("type").toString());
                    } else if (field == "amount") {
                        const auto amount = i.value().toInteger();
                        if (asset && asset->id() != network->policyAsset()) {
                            const auto precision = asset->data().value("precision").toInt(0);
                            const auto value = static_cast<double>(amount) / qPow(10, precision);
                            values.append(QString::number(value, 'f', precision));
                        } else {
                            const auto converted = wallet->convert({{ "satoshi", i.value() }});
                            values.append(converted.value(unit).toString());
                        }
                    } else if (field == "unit") {
                        if (asset && asset->id() != network->policyAsset()) {
                            values.append(asset->data().value("ticker").toString());
                        } else {
                            values.append(display_unit);
                        }
                    } else if (field == fee_field) {
                        if (data.value("type").toString() == "outgoing") {
                            const double fee = data.value("fee").toInt();
                            const auto converted = wallet->convert({{ "satoshi", fee }});
                            values.append(converted.value(unit).toString());
                        } else {
                            values.append("");
                        }
                    } else if (field == fiat_field) {
                        if (asset && asset->id() != network->policyAsset()) {
                            values.append("");
                        } else {
                            const auto amount = i.value().toInteger();
                            values.append(wallet->convert({{ "satoshi", amount }}).value("fiat").toString());
                        }
                    } else if (field == "txhash") {
                        values.append(data.value("txhash").toString());
                    } else if (field == "memo") {
                        values.append(data.value("memo").toString().replace("\n", " ").replace(",", "-"));
                    } else {
                        Q_UNREACHABLE();
                    }
                }
                lines.append(values.join(separator));
            }
        }

        QFile file(filename);
        bool result = file.open(QFile::WriteOnly);
        Q_ASSERT(result);

        QTextStream stream(&file);
        stream << lines.join("\n");

        QFileInfo info(file);
        QDesktopServices::openUrl(QUrl::fromLocalFile(info.absoluteFilePath()));
    });
    connect(this, &QObject::destroyed, dialog, &QFileDialog::deleteLater);
    dialog->open();
}

bool TransactionModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    auto context_transaction = sourceModel()->index(source_row, 0, source_parent).data(Qt::UserRole).value<ContextTransaction*>();

    if (const auto transaction = qobject_cast<AccountTransaction*>(context_transaction)) {
        if (!transaction->data().contains("satoshi")) return false;
        if (!transaction->data().contains("type")) return false;

        if (!filterAccountsAcceptsTransaction(transaction)) return false;
        if (!filterAssetsAcceptsTransaction(transaction)) return false;
        if (!filterTextAcceptsTransaction(transaction)) return false;
    } else if (const auto transaction = qobject_cast<LightningTransaction*>(context_transaction)) {
        if (!transaction->data().contains("satoshi")) return false;
        if (!transaction->data().contains("type")) return false;

        if (!filterAccountsAcceptsLightningTransaction(transaction)) return false;
        if (!filterAssetsAcceptsLightningTransaction(transaction)) return false;
        if (!filterTextAcceptsLightningTransaction(transaction)) return false;
    }
    return ContextModel::filterAcceptsRow(source_row, source_parent);
}

bool TransactionModel::filterAccountsAcceptsTransaction(AccountTransaction* transaction) const
{
    if (m_filter_accounts.isEmpty()) return true;

    for (auto account : m_filter_accounts) {
        if (transaction->account() == account) return true;
    }

    return false;
}

bool TransactionModel::filterAssetsAcceptsTransaction(AccountTransaction* transaction) const
{
    if (m_filter_assets.isEmpty()) return true;

    for (auto asset : m_filter_assets) {
        if (transaction->hasAsset(asset)) return true;
    }

    return false;
}

bool TransactionModel::filterTextAcceptsTransaction(AccountTransaction* transaction) const
{
    if (m_filter_text.isEmpty()) {
        return true;
    }
    if (transaction->hash().contains(m_filter_text)) {
        return true;
    }
    if (!transaction->memo().isEmpty() && transaction->memo().contains(m_filter_text)) {
        return true;
    }
    for (const auto output : transaction->data().value("outputs").toArray()) {
        if (output.toObject().value("address").toString().contains(m_filter_text)) {
            return true;
        }
    }
    return false;
}

bool TransactionModel::filterAccountsAcceptsLightningTransaction(LightningTransaction* transaction) const
{
    Q_UNUSED(transaction)
    return m_filter_accounts.isEmpty();
}

bool TransactionModel::filterAssetsAcceptsLightningTransaction(LightningTransaction* transaction) const
{
    if (m_filter_assets.isEmpty()) return true;

    for (auto asset : m_filter_assets) {
        if (asset->isLightning() && transaction->data().value("satoshi").toObject().contains(asset->id())) return true;
    }

    return false;
}

bool TransactionModel::filterTextAcceptsLightningTransaction(LightningTransaction* transaction) const
{
    if (m_filter_text.isEmpty()) return true;

    const auto data = transaction->data();
    if (transaction->id().contains(m_filter_text, Qt::CaseInsensitive)) return true;
    if (data.value("description").toString().contains(m_filter_text, Qt::CaseInsensitive)) return true;
    if (data.value("destination").toString().contains(m_filter_text, Qt::CaseInsensitive)) return true;
    if (data.value("bolt11").toString().contains(m_filter_text, Qt::CaseInsensitive)) return true;

    return false;
}

void TransactionModel::update(Context* context)
{
    setSourceModel(context->transactionModel());
    connect(context, &Context::transactionUpdated, this, [=, this] {
        sort(0, Qt::DescendingOrder);
    });
}

AddressModel::AddressModel(QObject* parent)
    : ContextModel(parent)
{
    setSortRole(Qt::UserRole + 1);
}

void AddressModel::exportToFile()
{
    auto datetime = QDateTime::currentDateTime();

    const QString suggestion =
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + QDir::separator() +
        context()->wallet()->name() + " - addresses - " +
        datetime.toString("yyyyMMddhhmmss") + ".csv";

    auto dialog = new QFileDialog(nullptr, "Save As", suggestion);
    dialog->setAcceptMode(QFileDialog::AcceptSave);
    dialog->setFileMode(QFileDialog::AnyFile);
    dialog->selectFile(suggestion);
    connect(dialog, &QFileDialog::fileSelected, this, [=, this](const QString& filename) {
        if (filename.isEmpty()) return;

        QStringList fields = QStringList{"network", "account", "address", "tx_count"};
        QStringList lines;
        QString separator{","};

        lines.append(fields.join(separator));

        const auto row_count = rowCount();
        for (int row = 0; row < row_count; ++row) {
            const auto address = index(row, 0).data(Qt::UserRole).value<Address*>();
            QStringList values;
            values.append(address->account()->network()->displayName());
            auto name = address->account()->name();
            values.append(name.isEmpty() ? qtTrId("id_main_account") : name);
            values.append(address->address());
            values.append(QString::number(address->data().value("tx_count").toInt()));
            lines.append(values.join(separator));
        }

        QFile file(filename);
        bool result = file.open(QFile::WriteOnly);
        Q_ASSERT(result);

        QTextStream stream(&file);
        stream << lines.join("\n");

        QFileInfo info(file);
        QDesktopServices::openUrl(QUrl::fromLocalFile(info.absoluteFilePath()));
    });
    connect(this, &QObject::destroyed, dialog, &QFileDialog::deleteLater);
    dialog->open();
}

bool AddressModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    auto address = sourceModel()->index(source_row, 0, source_parent).data(Qt::UserRole).value<Address*>();

    if (!filterAccountsAcceptsAddress(address)) return false;
    if (!filterTextAcceptsAddress(address)) return false;
    if (!filterTypesAcceptsAddress(address)) return false;
    if (!filterHasTransactionAcceptsAddress(address)) return false;

    return ContextModel::filterAcceptsRow(source_row, source_parent);
}

bool AddressModel::filterAccountsAcceptsAddress(Address* address) const
{
    if (m_filter_accounts.isEmpty()) return true;

    for (auto account : m_filter_accounts) {
        if (address->account() == account) return true;
    }

    return false;
}

bool AddressModel::filterTextAcceptsAddress(Address* address) const
{
    if (m_filter_text.isEmpty()) {
        return true;
    }
    if (address->address().contains(m_filter_text)) {
        return true;
    }
    return false;
}


bool AddressModel::filterTypesAcceptsAddress(Address* address) const
{
    if (m_filter_types.isEmpty()) {
        return true;
    }
    if (m_filter_types.contains(address->type())) {
        return true;
    }
    return false;
}

bool AddressModel::filterHasTransactionAcceptsAddress(Address* address) const
{
    if (!m_filter_has_transactions) {
        return true;
    }
    return address->data().value("tx_count").toInt() > 0;
}

void AddressModel::update(Context* context)
{
    setSourceModel(context->addressModel());
    connect(context, &Context::addressUpdated, this, [=, this] {
        sort(0, Qt::DescendingOrder);
    });
}

CoinModel::CoinModel(QObject* parent)
    : ContextModel(parent)
{
    setSortRole(Qt::UserRole + 1);
}

bool CoinModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    auto coin = sourceModel()->index(source_row, 0, source_parent).data(Qt::UserRole).value<Output*>();

    if (coin->spendingTransaction()) return false;

    if (!filterAccountsAcceptsCoin(coin)) return false;
    if (!filterAssetsAcceptsCoin(coin)) return false;
    if (!filterTextAcceptsCoin(coin)) return false;

    return ContextModel::filterAcceptsRow(source_row, source_parent);
}

void CoinModel::update(Context* context)
{
    setSourceModel(context->coinModel());
    connect(context, &Context::coinUpdated, this, [=, this] {
        beginFilterChange();
        endFilterChange();
        sort(0, Qt::DescendingOrder);
    });
}

bool CoinModel::filterAccountsAcceptsCoin(Output* coin) const
{
    if (m_filter_accounts.isEmpty()) return true;

    for (auto account : m_filter_accounts) {
        if (coin->account() == account) return true;
    }

    return false;
}

bool CoinModel::filterAssetsAcceptsCoin(Output* coin) const
{
    if (m_filter_assets.isEmpty()) return true;

    for (auto asset : m_filter_assets) {
        if (coin->asset() == asset) {
            return true;
        }
    }

    return false;
}

bool CoinModel::filterTextAcceptsCoin(Output* coin) const
{
    if (m_filter_text.isEmpty()) {
        return true;
    }
    if (coin->address().contains(m_filter_text)) {
        return true;
    }
    return false;
}

PaymentModel::PaymentModel(QObject* parent)
    : ContextModel(parent)
{
    setSortRole(Qt::UserRole + 1);
}

void PaymentModel::update(Context* context)
{
    setSourceModel(context->paymentModel());
    connect(context, &Context::paymentUpdated, this, &PaymentModel::invalidate);
}

bool PaymentModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    auto payment = sourceModel()->index(source_row, 0, source_parent).data(Qt::UserRole).value<Payment*>();

    if (!filterStatusesAcceptsPayment(payment)) return false;

    if (payment->transaction()) return false;
    if (payment->status() == "SETTLING") return true;

    return false;
}

bool PaymentModel::filterStatusesAcceptsPayment(Payment* payment) const
{
    if (m_filter_statuses.isEmpty()) {
        return true;
    }
    if (m_filter_statuses.contains(payment->status())) {
        return true;
    }
    return false;
}
