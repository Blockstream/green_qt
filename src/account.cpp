#include "account.h"
#include "balance.h"
#include "ga.h"
#include "json.h"
#include "network.h"
#include "transaction.h"
#include "wallet.h"

#include <QClipboard>
#include <QGuiApplication>
#include <QTimer>

#include <gdk.h>

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
    return QQmlListProperty<Balance>(this, m_balances);
}

static QJsonArray get_transactions(GA_session* session, int subaccount, int first, int count)
{
    auto result = GA::process_auth([&] (GA_auth_handler** call) {
        GA_json* details = Json::fromObject({
            { "subaccount", subaccount },
            { "first", first },
            { "count", count }
        });

        int err = GA_get_transactions(session, details, call);
        Q_ASSERT(err == GA_OK);

        err = GA_destroy_json(details);
        Q_ASSERT(err == GA_OK);
    });
    Q_ASSERT(result.value("status").toString() == "done");
    return result.value("result").toObject().value("transactions").toArray();
}

void Account::reload()
{
    QMetaObject::invokeMethod(m_wallet->m_context, [this] {
        QList<QJsonArray> transactions;
        int first = 0;
        int count = 30;
        while (true) {
            auto values = get_transactions(m_wallet->m_session, m_pointer, first, count);
            transactions.push_back(values);
            if (values.size() < count) break;
            first += count;
        }

        QMetaObject::invokeMethod(this, [this, transactions] {
            m_transactions.clear();
            m_have_unconfirmed = false;
            for (auto list : transactions) {
                for (auto value : list) {
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
            }
            emit transactionsChanged();
        }, Qt::QueuedConnection);
    });
}

void Account::copyAccountIdToClipboard()
{
    QGuiApplication::clipboard()->setText(m_json.value("receiving_id").toString());
}

Wallet *Account::wallet() const
{
    return m_wallet;
}

bool Account::isMainAccount() const
{
    return m_json.value("name").toString() == "";
}

ReceiveAddress::ReceiveAddress(QObject *parent) : QObject(parent)
{

}

ReceiveAddress::~ReceiveAddress()
{
    QMetaObject::invokeMethod(m_account->m_wallet->m_context, [] {}, Qt::BlockingQueuedConnection);
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
    if (m_account->m_wallet->isLocked()) return;

    if (!m_account && !m_address.isEmpty()) {
        m_address.clear();
        emit changed();
        return;
    }

    if (m_generating) return;

    setGenerating(true);

    QMetaObject::invokeMethod(m_account->m_wallet->m_context, [this] {
        auto result = GA::process_auth([&] (GA_auth_handler** call) {
            auto address_details = Json::fromObject({
                { "subaccount", static_cast<qint64>(m_account->m_pointer) },
            });

            int err = GA_get_receive_address(m_account->m_wallet->m_session, address_details, call);
            Q_ASSERT(err == GA_OK);

            err = GA_destroy_json(address_details);
            Q_ASSERT(err == GA_OK);
        });
        Q_ASSERT(result.value("status").toString() == "done");
        m_address = result.value("result").toObject().value("address").toString();
        setGenerating(false);
        emit changed();
    });
}

void ReceiveAddress::copyToClipboard()
{
    QGuiApplication::clipboard()->setText(m_address);
}

void ReceiveAddress::copyUriToClipboard() const
{
    QGuiApplication::clipboard()->setText(uri());
}
