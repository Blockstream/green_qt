#include "account.h"
#include "ga.h"
#include "json.h"
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
    return name.toUpper();
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
    qDebug() << "ACCOUNT UPDATE DATA:" << json;
    emit jsonChanged();
    emit balanceChanged();
}

void Account::handleNotification(const QJsonObject &notification)
{
    reload();
}

qint64 Account::balance() const
{
    return m_json.value("satoshi").toObject().value("btc").toDouble();
}

static QJsonArray get_transactions(GA_session* session, int subaccount, int first, int count)
{
    return GA::process_auth([&] (GA_auth_handler** call) {
        GA_json* details = Json::fromObject({
            { "subaccount", subaccount },
            { "first", first },
            { "count", count }
        });

        int err = GA_get_transactions(session, details, call);
        Q_ASSERT(err == GA_OK);

        err = GA_destroy_json(details);
        Q_ASSERT(err == GA_OK);
    }).value("transactions").toArray();
}

void Account::reload()
{
    QMetaObject::invokeMethod(m_wallet->m_context, [this] {
        QJsonArray transactions;
        int first = 0;
        int count = 30;
        while (true) {
            auto values = get_transactions(m_wallet->m_session, m_pointer, first, count);
            for (auto value : values) {
                transactions.append(value);
            }
            if (values.size() < count) break;
            break;
        }

        QMetaObject::invokeMethod(this, [this, transactions] {
            m_transactions.clear();
            for (auto value : transactions) {
                QJsonObject data = value.toObject();
                auto hash = data.value("txhash").toString();
                auto transaction = m_transactions_by_hash.value(hash);
                if (!transaction) {
                    transaction = new Transaction(this);
                    m_transactions_by_hash.insert(hash, transaction);
                }
                transaction->updateFromData(data);
                m_transactions.append(transaction);
            }
            emit transactionsChanged();
        }, Qt::BlockingQueuedConnection);
    });
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

QString ReceiveAddress::address() const
{
    return m_address;
}

bool ReceiveAddress::generating() const
{
    return m_generating;
}

void ReceiveAddress::generate()
{
    if (!m_account && !m_address.isEmpty()) {
        m_address.clear();
        emit addressChanged(m_address);
        return;
    }

    if (m_generating) return;

    m_generating = true;
    emit generatingChanged(true);

    QMetaObject::invokeMethod(m_account->m_wallet->m_context, [this] {
        m_address = GA::process_auth([&] (GA_auth_handler** call) {
            auto address_details = Json::fromObject({
                { "subaccount", static_cast<qint64>(m_account->m_pointer) },
            });

            int err = GA_get_receive_address(m_account->m_wallet->m_session, address_details, call);
            Q_ASSERT(err == GA_OK);

            err = GA_destroy_json(address_details);
            Q_ASSERT(err == GA_OK);
        }).value("address").toString();

        m_generating = false;
        emit generatingChanged(true);
        emit addressChanged(m_address);
    });
}

void ReceiveAddress::copyToClipboard()
{
    QGuiApplication::clipboard()->setText(m_address);
}
