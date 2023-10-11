#include "account.h"

#include <gdk.h>

#include <algorithm>

#include "address.h"
#include "asset.h"
#include "balance.h"
#include "context.h"
#include "network.h"
#include "output.h"
#include "session.h"
#include "task.h"
#include "transaction.h"

Account::Account(int pointer, Session* session)
    : QObject(session)
    , m_session(session)
    , m_context(session->context())
    , m_network(session->network())
    , m_pointer(pointer)
{
}

void Account::setSynced(bool synced)
{
    if (m_synced == synced) return;
    m_synced = synced;
    emit syncedChanged();
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
    setType(m_json.value("type").toString());
    setName(m_json.value("name").toString());
    setHidden(m_json.value("hidden").toBool());
    updateBalance();
}

void Account::updateBalance()
{
    if (m_network->isLiquid()) {
        auto satoshi = m_json.value("satoshi").toObject();
        auto balance_by_id = m_balance_by_id;
        m_balance_by_id.clear();
        m_balances.clear();
        for (auto i = satoshi.constBegin(); i != satoshi.constEnd(); ++i) {
            Balance* balance = balance_by_id.take(i.key());
            if (!balance) balance = new Balance(this);
            m_balance_by_id.insert(i.key(), balance);
            balance->setAsset(context()->getOrCreateAsset(i.key()));
            balance->setAmount(i.value().toDouble());
            m_balances.append(balance);
        }
        std::sort(m_balances.begin(), m_balances.end(), [=](const Balance* b1, const Balance* b2) {
            Asset* a1 = b1->asset();
            Asset* a2 = b2->asset();

            if (a1->id() == m_network->policyAsset()) return true;
            if (a2->id() ==  m_network->policyAsset()) return false;

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

void Account::loadBalance()
{
    m_context->dispatcher()->add(new LoadBalanceTask(this));
}

qint64 Account::balance() const
{
    const QString key = m_network->isLiquid() ? m_network->policyAsset() : "btc";
    return m_json.value("satoshi").toObject().value(key).toDouble();
}

QQmlListProperty<Balance> Account::balances()
{
    return { this, &m_balances };
}

bool Account::hasBalance() const
{
    if (m_network->isLiquid()) {
        for (auto balance : m_balances) {
            if (balance->amount() > 0) return true;
        }
        return false;
    } else {
        return balance() > 0;
    }
}

void Account::setBalanceData(const QJsonObject &data)
{
    m_json.insert("satoshi", data);
    emit jsonChanged();
    updateBalance();
}

void Account::setHidden(bool hidden)
{
    if (m_hidden == hidden) return;
    m_json["hidden"] = hidden;
    m_hidden = hidden;
    emit hiddenChanged();
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

bool Account::isBitcoin() const
{
    return !m_network->isLiquid();
}

bool Account::isLiquid() const
{
    return m_network->isLiquid();
}

bool Account::isLightning() const
{
    return false;
}

bool Account::isSinglesig() const
{
    return m_network->isElectrum();
}

bool Account::isMultisig() const
{
    return !m_network->isElectrum();
}

bool Account::isAmp() const
{
    return isLiquid() && m_type == "2of2_no_recovery";
}

void Account::setType(const QString& type)
{
    if (m_type == type) return;
    Q_ASSERT(m_type.isEmpty());
    m_type = type;
    emit typeChanged();
}

void Account::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    m_json["name"] = name;
    emit nameChanged();
}
