#ifndef BLOCKSTREAM_SUBMARINECONTROLLER_H
#define BLOCKSTREAM_SUBMARINECONTROLLER_H

#include "controller.h"
#include "swap.h"

#include <QVariant>

class SubmarineControllerPrivate;

class SubmarineController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap recipient READ recipient WRITE setRecipient NOTIFY recipientChanged)
    Q_PROPERTY(QString refundAddress READ refundAddress WRITE setRefundAddress NOTIFY refundAddressChanged)
    Q_PROPERTY(bool busy READ isBusy NOTIFY busyChanged)
    Q_PROPERTY(QVariant error READ error NOTIFY errorChanged)
    Q_PROPERTY(SubmarineSwap* swap READ swap NOTIFY swapChanged)
    Q_DECLARE_PRIVATE(SubmarineController)
    QML_ELEMENT
public:
    SubmarineController(QObject* parent = nullptr);
    QVariantMap recipient() const;
    void setRecipient(const QVariantMap& recipient);
    QString refundAddress() const;
    void setRefundAddress(const QString& refund_address);
    bool isBusy() const;
    QVariant error() const;
    SubmarineSwap* swap() const;
public slots:
    void setLockupTransaction(ChainTransaction* transaction);
signals:
    void recipientChanged();
    void refundAddressChanged();
    void busyChanged();
    void swapChanged();
    void errorChanged();
protected:
    void timerEvent(QTimerEvent* event);
private:
    void invalidate();
    void update();
    void setError(const QVariant& error);
    void setSwap(SubmarineSwap* swap);
};

#endif // BLOCKSTREAM_SUBMARINECONTROLLER_H
