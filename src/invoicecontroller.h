#ifndef BLOCKSTREAM_INVOICECONTROLLER_H
#define BLOCKSTREAM_INVOICECONTROLLER_H

#include "controller.h"
#include "swap.h"

class InvoiceControllerPrivate;

class InvoiceController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY addressChanged)
    Q_PROPERTY(QString satoshi READ satoshi WRITE setSatoshi NOTIFY satoshiChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY descriptionChanged)
    Q_PROPERTY(bool busy READ isBusy NOTIFY busyChanged)
    Q_PROPERTY(ReverseSwap* swap READ swap NOTIFY swapChanged)
    Q_DECLARE_PRIVATE(InvoiceController)
    QML_ELEMENT
public:
    InvoiceController(QObject* parent = nullptr);
    QString address() const;
    void setAddress(const QString& address);
    QString satoshi() const;
    void setSatoshi(const QString& satoshi);
    QString description() const;
    void setDescription(const QString& description);
    bool isBusy() const;
    ReverseSwap* swap() const;
public slots:
    void request();
signals:
    void addressChanged();
    void satoshiChanged();
    void descriptionChanged();
    void busyChanged();
    void swapChanged();
protected:
    void timerEvent(QTimerEvent* event);
private:
    void invalidate(int timeout);
    void update();
    bool isValid() const;
    void setSwap(ReverseSwap* swap);
    void setBusy(bool busy);
};

#endif // BLOCKSTREAM_INVOICECONTROLLER_H
