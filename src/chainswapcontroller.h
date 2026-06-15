#ifndef BLOCKSTREAM_CHAINSWAPCONTROLLER_H
#define BLOCKSTREAM_CHAINSWAPCONTROLLER_H

#include "controller.h"
#include "swap.h"

class Address;
class ChainSwapControllerPrivate;

class ChainSwapController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QString amount READ amount WRITE setAmount NOTIFY amountChanged)
    Q_PROPERTY(Address* refundAddress READ refundAddress WRITE setRefundAddress NOTIFY refundAddressChanged)
    Q_PROPERTY(Address* claimAddress READ claimAddress WRITE setClaimAddress NOTIFY claimAddressChanged)
    Q_PROPERTY(bool busy READ isBusy NOTIFY busyChanged)
    Q_PROPERTY(ChainSwap* swap READ swap NOTIFY swapChanged)
    Q_DECLARE_PRIVATE(ChainSwapController)
    QML_ELEMENT
public:
    ChainSwapController(QObject* parent = nullptr);
    ~ChainSwapController();
    QString amount() const;
    void setAmount(const QString& amount);
    Address* refundAddress() const;
    void setRefundAddress(Address* refund_address);
    Address* claimAddress() const;
    void setClaimAddress(Address* claim_address);
    bool isValid() const;
    bool isBusy() const;
    ChainSwap* swap() const;
public slots:
    void setLockupTransaction(ChainTransaction* transaction);
signals:
    void amountChanged();
    void refundAddressChanged();
    void claimAddressChanged();
    void busyChanged();
    void swapChanged();
protected:
    void timerEvent(QTimerEvent* event);
private:
    void invalidate();
    void update();
};

#endif // BLOCKSTREAM_CHAINSWAPCONTROLLER_H
