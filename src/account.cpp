#include "account.h"
#include "asset.h"
#include "balance.h"
#include "ga.h"
#include "handler.h"
#include "json.h"
#include "network.h"
#include "resolver.h"
#include "transaction.h"
#include "wallet.h"

#include <QFileDialog>
#include <QFile>
#include <QTextStream>
#include <QStandardPaths>
#include <QTimer>

#include <gdk.h>

class GetBalanceHandler : public Handler
{
    Account* const m_account;
    void init(GA_session* session) override
    {
        GA_json* details = Json::fromObject({
            { "subaccount", m_account->m_pointer },
            { "num_confs", 0 }
        });

        int err = GA_get_balance(session, details, &m_handler);
        Q_ASSERT(err == GA_OK);

        err = GA_destroy_json(details);
        Q_ASSERT(err == GA_OK);
    }
public:
    GetBalanceHandler(Account* account)
        : Handler(account->wallet())
        , m_account(account)
    {
    }
};

class GetTransactionsHandler : public Handler
{
    int m_subaccount;
    int m_first;
    int m_count;
    void init(GA_session* session) override
    {
        GA_json* details = Json::fromObject({
            { "subaccount", m_subaccount },
            { "first", m_first },
            { "count", m_count }
        });

        int err = GA_get_transactions(session, details, &m_handler);
        Q_ASSERT(err == GA_OK);

        err = GA_destroy_json(details);
        Q_ASSERT(err == GA_OK);
    }
public:
    GetTransactionsHandler(int subaccount, int first, int count, Wallet *wallet)
        : Handler(wallet)
        , m_subaccount(subaccount)
        , m_first(first)
        , m_count(count)
    {
    }
};

class GetReceiveAddressHandler : public Handler
{
    Account* const m_account;
    void init(GA_session* session) override
    {
        auto address_details = Json::fromObject({
            { "subaccount", static_cast<qint64>(m_account->m_pointer) },
        });

        int err = GA_get_receive_address(session, address_details, &m_handler);
        Q_ASSERT(err == GA_OK);

        err = GA_destroy_json(address_details);
        Q_ASSERT(err == GA_OK);
    }
public:
    GetReceiveAddressHandler(Account* account)
        : Handler(account->wallet())
        , m_account(account)
    {
    }
};

Account::Account(Wallet* wallet)
    : QObject(wallet)
    , m_wallet(wallet)
{
}

QString Account::name() const
{
    QString name = m_json.value("name").toString();
    if (name.isEmpty()) name = "Main Account";
    return name;
}

QJsonObject Account::json() const
{
    return m_json;
}

QQmlListProperty<Transaction> Account::transactions()
{
    return QQmlListProperty<Transaction>(this, &m_transactions,
        [](QQmlListProperty<Transaction>* property) { return static_cast<QVector<Transaction*>*>(property->data)->size(); },
    [](QQmlListProperty<Transaction>* property, int index) { return static_cast<QVector<Transaction*>*>(property->data)->at(index); });
}

void Account::update(const QJsonObject& json)
{
    m_json = json;
    m_pointer = m_json.value("pointer").toInt();
    emit jsonChanged();

    updateBalance();
}

void Account::updateBalance()
{
    if (wallet()->network()->isLiquid()) {
        auto satoshi = m_json.value("satoshi").toObject();
        auto balance_by_id = m_balance_by_id;
        m_balance_by_id.clear();
        m_balances.clear();
        for (auto i = satoshi.constBegin(); i != satoshi.constEnd(); ++i) {
            Balance* balance = balance_by_id.take(i.key());
            if (!balance) balance = new Balance(this);
            m_balance_by_id.insert(i.key(), balance);
            balance->setAsset(wallet()->getOrCreateAsset(i.key()));
            balance->setAmount(i.value().toDouble());
            m_balances.append(balance);
        }
        std::sort(m_balances.begin(), m_balances.end(), [](const Balance* b1, const Balance* b2) {
            Asset* a1 = b1->asset();
            Asset* a2 = b2->asset();

            if (a1->isLBTC()) return true;
            if (a2->isLBTC()) return false;

            if (a1->hasIcon() && !a2->hasIcon()) return true;
            if (a2->hasIcon() && !a1->hasIcon()) return false;
            if (a1->hasIcon() && a2->hasIcon()) return a1->name() < a2->name();

            if (a1->hasData() && !a2->hasData()) return true;
            if (a2->hasData() && !a1->hasData()) return false;
            if (a1->hasData() && a2->hasData()) return a1->name() < a2->name();

            return a1->name() < a2->name();
        });
        emit balancesChanged();
        qDeleteAll(balance_by_id.values());
    }

    emit balanceChanged();
}

void Account::handleNotification(const QJsonObject &notification)
{
    Q_UNUSED(notification);
    reload();
}

qint64 Account::balance() const
{
    return m_json.value("satoshi").toObject().value("btc").toDouble();
}

QQmlListProperty<Balance> Account::balances()
{
    return { this, &m_balances };
}

void Account::reload()
{
    auto handler = new GetBalanceHandler(this);
    connect(handler, &Handler::done, this, [this, handler] {
        auto balance = handler->result().value("result").toObject();
        m_json.insert("satoshi", balance);
        emit jsonChanged();
        updateBalance();
        m_transactions_data = {};
        loadNextPage();
    });
    QObject::connect(handler, &Handler::resolver, [](Resolver* resolver) {
        resolver->resolve();
    });
    handler->exec();
}

void Account::loadNextPage()
{
    auto handler = new GetTransactionsHandler(m_pointer, m_transactions_data.size(), 30, wallet());
    QObject::connect(handler, &Handler::done, this, [this, handler] {
        auto transactions = handler->result().value("result").toObject().value("transactions").toArray();
        for (auto data : transactions) m_transactions_data.append(data);
        if (transactions.size() < 30) {
            m_transactions.clear();
            m_have_unconfirmed = false;
            for (auto value : m_transactions_data) {
                QJsonObject data = value.toObject();
                auto hash = data.value("txhash").toString();
                auto transaction = m_transactions_by_hash.value(hash);
                if (!transaction) {
                    transaction = new Transaction(this);
                    m_transactions_by_hash.insert(hash, transaction);
                }
                transaction->updateFromData(data);
                m_transactions.append(transaction);
                if (transaction->isUnconfirmed()) m_have_unconfirmed = true;
            }
            emit transactionsChanged();
        } else {
            loadNextPage();
        }
    });
    QObject::connect(handler, &Handler::resolver, [](Resolver* resolver) {
        resolver->resolve();
    });
    handler->exec();
}

Wallet *Account::wallet() const
{
    return m_wallet;
}

bool Account::isMainAccount() const
{
    return m_json.value("name").toString() == "";
}

void Account::exportCSV()
{
    const auto now = QDateTime::currentDateTime();
    const QString suggestion =
            QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + QDir::separator() +
            wallet()->name() + " - " + name() + " - " +
            now.toString("yyyyMMddhhmmss") + ".csv";
    const QString name = QFileDialog::getSaveFileName(nullptr, "Export to CSV", suggestion);
    if (name.isEmpty()) return;

    QFile file(name);
    bool result = file.open(QFile::WriteOnly);
    Q_ASSERT(result);

    const auto pricing = wallet()->settings().value("pricing").toObject();

    const QString fee_field = QString("fee (%1)").arg(wallet()->network()->isLiquid() ? "L-" + wallet()->settings().value("unit").toString() : wallet()->settings().value("unit").toString());
    const QString fiat_field = QString("fiat (%1 %2 %3)").arg(pricing.value("currency").toString()).arg(pricing.value("exchange").toString(), now.toString(Qt::ISODate));
    const bool header = true;
    const QString separator = ",";
    const QStringList fields{"time", "description", "amount", "unit", fee_field, fiat_field, "txhash", "memo"};

    QStringList lines;
    if (header) {
        lines.append(fields.join(separator));
    }
    for (auto transaction : m_transactions) {
        const auto data = transaction->data();
        const auto block_height = data.value("block_height").toInt();
        if (block_height == 0) continue;
        for (auto amount : transaction->m_amounts) {
            const auto asset = amount->asset();
            QStringList values;
            for (auto field : fields) {
                if (field == "time") {
                    values.append(data.value("created_at").toString());
                } else if (field == "description") {
                    values.append(data.value("type").toString());
                } else if (field == "amount") {
                    values.append(amount->formatAmount(false).replace(",", "."));
                } else if (field == "unit") {
                    if (asset && !asset->isLBTC()) {
                        values.append(asset->data().value("ticker").toString());
                    } else if (asset && asset->isLBTC()) {
                        values.append("L-" + wallet()->settings().value("unit").toString());
                    } else {
                        values.append(wallet()->settings().value("unit").toString());
                    }
                } else if (field == fee_field) {
                    if (data.value("type").toString() == "outgoing") {
                        values.append(wallet()->formatAmount(data.value("fee").toInt(), false).replace(",", "."));
                    } else {
                        values.append("");
                    }
                } else if (field == fiat_field) {
                    if (asset && !asset->isLBTC()) {
                        values.append("");
                    } else {
                        values.append(wallet()->convert({{ "satoshi", amount->amount() }}).value("fiat").toString());
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

    QTextStream stream(&file);
    stream << lines.join("\n");
}

ReceiveAddress::ReceiveAddress(QObject *parent) : QObject(parent)
{

}

ReceiveAddress::~ReceiveAddress()
{
    if (m_account) {
        QMetaObject::invokeMethod(m_account->m_wallet->m_context, [] {}, Qt::BlockingQueuedConnection);
    }
}

Account *ReceiveAddress::account() const
{
    return m_account;
}

void ReceiveAddress::setAccount(Account *account)
{
    if (m_account == account) return;

    m_account = account;
    emit accountChanged(m_account);

    generate();
}

QString ReceiveAddress::amount() const
{
    return m_amount;
}

void ReceiveAddress::setAmount(const QString& amount)
{
    if (m_amount == amount) return;
    m_amount = amount;
    emit changed();
}

QString ReceiveAddress::address() const
{
    return m_address;
}

QString ReceiveAddress::uri() const
{
    if (!m_account || m_generating) return {};
    const auto wallet = m_account->wallet();
    auto unit = wallet->settings().value("unit").toString();
    unit = unit == "\u00B5BTC" ? "ubtc" : unit.toLower();
    auto amount = m_amount;
    amount.replace(',', '.');
    amount = wallet->convert({{ unit, amount }}).value("btc").toString();
    if (amount.toDouble() > 0) {
        return QString("%1:%2?amount=%3")
                .arg(wallet->network()->data().value("bip21_prefix").toString())
                .arg(m_address)
                .arg(amount);
    } else {
        return m_address;
    }
}

bool ReceiveAddress::generating() const
{
    return m_generating;
}

void ReceiveAddress::setGenerating(bool generating)
{
    if (m_generating == generating) return;
    m_generating = generating;
    emit generatingChanged(m_generating);
}

void ReceiveAddress::generate()
{
    if (!m_account || m_account->m_wallet->isLocked()) return;


    if (m_generating) return;

    setGenerating(true);

    auto handler = new GetReceiveAddressHandler(m_account);
    connect(handler, &Handler::done, [this, handler] {
        m_address = handler->result().value("result").toObject().value("address").toString();
        setGenerating(false);
        emit changed();
    });
    connect(handler, &Handler::resolver, [](Resolver* resolver) {
        resolver->resolve();
    });
    handler->exec();
}
