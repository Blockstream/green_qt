#include "account.h"

#include <gdk.h>

#include <algorithm>

#include "address.h"
#include "asset.h"
#include "balance.h"
#include "ga.h"
#include "handlers/getbalancehandler.h"
#include "json.h"
#include "network.h"
#include "output.h"
#include "resolver.h"
#include "transaction.h"
#include "updateaccounthandler.h"
#include "wallet.h"

Account::Account(const QJsonObject& data, Network* network, Wallet* wallet)
    : QObject(wallet)
    , m_wallet(wallet)
    , m_network(network)
    , m_pointer(data.value("pointer").toDouble())
    , m_type(data.value("type").toString())
{
    Q_ASSERT(m_pointer >= 0);
    Q_ASSERT(!m_type.isEmpty());
    update(data);
}

QJsonObject Account::json() const
{
    return m_json;
}

void Account::update(const QJsonObject& json)
{
    Q_ASSERT(m_pointer == static_cast<qint64>(json.value("pointer").toDouble()));
    m_json = json;
    emit jsonChanged();
    setName(m_json.value("name").toString());
    setHidden(m_json.value("hidden").toBool());
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

void Account::handleNotification(const QJsonObject& notification)
{
    const auto event = notification.value("event").toString();
    if (event == "transaction") {
        reload();
        emit notificationHandled(notification);
    } else if (event == "block") {
        // FIXME: Until gdk notifies of chain reorgs, resync balance every
        // 10 blocks in case a reorged tx is somehow evicted from the mempool
        const auto block = notification.value("block").toObject();
        uint32_t block_height = block.value("block_height").toDouble();
        if (!wallet()->network()->isLiquid() || (block_height % 10) == 0) {
            reload();
        }
        emit notificationHandled(notification);
    }
}

qint64 Account::balance() const
{
    const QString key = m_wallet->network()->isLiquid() ? m_wallet->network()->policyAsset() : "btc";
    return m_json.value("satoshi").toObject().value(key).toDouble();
}

QQmlListProperty<Balance> Account::balances()
{
    return { this, &m_balances };
}

bool Account::hasBalance() const
{
    if (m_wallet->network()->isLiquid()) {
        for (auto balance : m_balances) {
            if (balance->amount() > 0) return true;
        }
        return false;
    } else {
        return balance() > 0;
    }
}

void Account::reload()
{
    auto handler = new GetBalanceHandler(this);
    connect(handler, &Handler::done, this, [this, handler] {
        auto balance = handler->result().value("result").toObject();
        m_json.insert("satoshi", balance);
        emit jsonChanged();
        updateBalance();
        if (!m_ready) {
            m_ready = true;
            emit readyChanged();
        }
    });
    QObject::connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    handler->exec();
}

bool Account::rename(QString name, bool active_focus)
{
    if (!active_focus) name = name.trimmed();
    if (name.isEmpty() && !active_focus) {
        emit jsonChanged();
        return false;
    }
    if (this->name() == name) return false;
    if (active_focus) return false;
    auto handler = new UpdateAccountHandler({
        { "subaccount", static_cast<qint64>(m_pointer) },
        { "name", name }
    }, wallet()->session());
    connect(handler, &Handler::done, this, [=] {
        handler->deleteLater(),
        setName(name);
    });
    handler->exec();
    return true;
}

void Account::show()
{
    return setHiddenAsync(false);
}

void Account::hide()
{
    return setHiddenAsync(true);
}

void Account::setHiddenAsync(bool hidden)
{
    auto handler = new UpdateAccountHandler({
        { "subaccount", static_cast<qint64>(m_pointer) },
        { "hidden", hidden }
    }, wallet()->session());
    connect(handler, &Handler::done, this, [=] {
        handler->deleteLater();
        m_json["hidden"] = hidden;
        setHidden(hidden);
    });
    handler->exec();
}

void Account::setHidden(bool hidden)
{
    if (m_hidden == hidden) return;
    m_hidden = hidden;
    emit hiddenChanged(m_hidden);
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

Output* Account::getOrCreateOutput(const QJsonObject& data)
{
    auto txhash = data.value("txhash").toString();
    auto pt_idx = data.value("pt_idx").toInt();
    auto output = m_outputs_by_hash.value(QPair<QString,int>(txhash, pt_idx));
    if (!output) {
        output = new Output(data, this);
        m_outputs_by_hash.insert(QPair<QString,int>(txhash, pt_idx), output);
    } else {
        output->updateFromData(data);
    }
    return output;
}

Address* Account::getOrCreateAddress(const QJsonObject& data)
{
    auto hash = data.value("address").toString();
    auto address = m_address_by_hash.value(hash);
    if (!address) {
        address = new Address(this);
        m_address_by_hash.insert(hash, address);
    }
    address->updateFromData(data);
    return address;
}

Balance *Account::getBalanceByAssetId(const QString &id) const
{
    return m_balance_by_id.value(id);
}

Transaction *Account::getTransactionByTxHash(const QString &id) const
{
    return m_transactions_by_hash.value(id);
}

bool Account::isMainAccount() const
{
    return m_pointer == 0;
}

void Account::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged(m_name);
}
