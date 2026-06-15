#ifndef BLOCKSTREAM_SWAP_H
#define BLOCKSTREAM_SWAP_H

#include <QFuture>
#include <QObject>
#include <QQmlEngine>

#include <memory>

#include "context.h"
#include "green.h"
#include "lwk/lwk.hpp"

class Swap : public ContextTransaction
{
    Q_OBJECT
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Q_PROPERTY(QVariantMap data READ data CONSTANT)
    Q_PROPERTY(ChainTransaction* lockupTransaction READ lockupTransaction NOTIFY lockupTransactionChanged)
    Q_PROPERTY(ChainTransaction* claimTransaction READ claimTransaction NOTIFY claimTransactionChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    enum class Status {
        Pending,
        Completed,
        Failed,
    };
    Q_ENUM(Status)
    Swap(const QString& id, Context* context);
    virtual ~Swap();
    Status status() const { return m_status; }
    virtual QVariantMap data() const = 0;
    void sync();
    ChainTransaction* lockupTransaction() const { return m_lockup_transaction; }
    virtual void setLockupTransaction(ChainTransaction* lockup_transaction);
    ChainTransaction* claimTransaction() const { return m_claim_transaction; }
    void setClaimTransaction(ChainTransaction* claim_transaction);
signals:
    void statusChanged();
    void lockupTransactionChanged();
    void claimTransactionChanged();
protected:
    void setStatus(Status status);
    virtual lwk::PaymentState advance() = 0;
    virtual void update() = 0;
protected:
    Status m_status{Status::Pending};
    ChainTransaction* m_lockup_transaction{nullptr};
    ChainTransaction* m_claim_transaction{nullptr};
    QFuture<void> m_future;
};

class ReverseSwap : public Swap
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ReverseSwap(std::shared_ptr<lwk::InvoiceResponse> invoice_response, Context* context);
    QVariantMap data() const override;
    lwk::PaymentState advance() override;
protected:
    void update() override;
private:
    std::shared_ptr<lwk::InvoiceResponse> m_invoice_response;
};

class SubmarineSwap : public Swap
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SubmarineSwap(const QString& invoice, std::shared_ptr<lwk::PreparePayResponse> prepare_pay_response, Context* context);
    SubmarineSwap(uint64_t amount, const QString& address, Context* context);
    QString invoice() const { return m_invoice; }
    QVariantMap data() const override;
    void setLockupTransaction(ChainTransaction* lockup_transaction) override;
protected:
    lwk::PaymentState advance() override;
    void update() override;
private:
    std::shared_ptr<lwk::PreparePayResponse> m_prepare_pay_response;
    QString m_invoice;
    QString m_address;
    uint64_t m_amount;
};

class ChainSwap : public Swap
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ChainSwap(std::shared_ptr<lwk::LockupResponse> lockup_response, Context* context);
    QVariantMap data() const override;
    void setLockupTransaction(ChainTransaction* lockup_transaction) override;
protected:
    lwk::PaymentState advance() override;
    void update() override;
private:
    std::shared_ptr<lwk::LockupResponse> m_lockup_response;
};

#endif // BLOCKSTREAM_SWAP_H
