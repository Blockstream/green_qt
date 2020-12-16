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

#include <gdk.h>

class GetBalanceHandler : public Handler
{
    Account* const m_account;
    void call(GA_session* session, GA_auth_handler** auth_handler) override
    {
        GA_json* details = Json::fromObject({
            { "subaccount", m_account->m_pointer },
            { "num_confs", 0 }
        });

        int err = GA_get_balance(session, details, auth_handler);
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

class GetReceiveAddressHandler : public Handler
{
    Account* const m_account;
    void call(GA_session* session, GA_auth_handler** auth_handler) override
    {
        auto address_details = Json::fromObject({
            { "subaccount", static_cast<qint64>(m_account->m_pointer) },
        });

        int err = GA_get_receive_address(session, address_details, auth_handler);
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
        m_transactions_data = {};
    });
    QObject::connect(handler, &Handler::resolver, [](Resolver* resolver) {
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

Wallet *Account::wallet() const
{
    return m_wallet;
}

bool Account::isMainAccount() const
{
    return m_json.value("name").toString() == "";
}

ReceiveAddressController::ReceiveAddressController(QObject *parent) : QObject(parent)
{

}

ReceiveAddressController::~ReceiveAddressController()
{
    if (m_account) {
        QMetaObject::invokeMethod(m_account->m_wallet->m_context, [] {}, Qt::BlockingQueuedConnection);
    }
}

Account *ReceiveAddressController::account() const
{
    return m_account;
}

void ReceiveAddressController::setAccount(Account *account)
{
    if (m_account == account) return;

    m_account = account;
    emit accountChanged(m_account);

    generate();
}

QString ReceiveAddressController::amount() const
{
    return m_amount;
}

void ReceiveAddressController::setAmount(const QString& amount)
{
    if (m_amount == amount) return;
    m_amount = amount;
    emit changed();
}

QString ReceiveAddressController::address() const
{
    return m_address;
}

QString ReceiveAddressController::uri() const
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

bool ReceiveAddressController::generating() const
{
    return m_generating;
}

void ReceiveAddressController::setGenerating(bool generating)
{
    if (m_generating == generating) return;
    m_generating = generating;
    emit generatingChanged(m_generating);
}

void ReceiveAddressController::generate()
{
    if (!m_account || m_account->m_wallet->isLocked()) return;


    if (m_generating) return;

    setGenerating(true);

    auto handler = new GetReceiveAddressHandler(m_account);
    connect(handler, &Handler::done, this, [this, handler] {
        m_address = handler->result().value("result").toObject().value("address").toString();
        setGenerating(false);
        emit changed();
    });
    connect(handler, &Handler::resolver, [](Resolver* resolver) {
        resolver->resolve();
    });
    handler->exec();
}
