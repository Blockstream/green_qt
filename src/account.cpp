#include "account.h"
#include "asset.h"
#include "balance.h"
#include "ga.h"
#include "handlers/getbalancehandler.h"
#include "json.h"
#include "network.h"
#include "resolver.h"
#include "transaction.h"
#include "wallet.h"

#include <gdk.h>

Account::Account(Wallet* wallet)
    : QObject(wallet)
    , m_wallet(wallet)
{
}

QString Account::name() const
{
    return m_json.value("name").toString();
}

QJsonObject Account::json() const
{
    return m_json;
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
    emit notificationHandled(notification);
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
    });
    QObject::connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    handler->exec();
}

Transaction* Account::getOrCreateTransaction(const QJsonObject& data)
{
    auto hash = data.value("txhash").toString();
    auto transaction = m_transactions_by_hash.value(hash);
    if (!transaction) {
        transaction = new Transaction(this);
        m_transactions_by_hash.insert(hash, transaction);
    }
    transaction->updateFromData(data);
    return transaction;
}

bool Account::isMainAccount() const
{
    return m_json.value("name").toString() == "";
}
