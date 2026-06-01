#ifndef BLOCKSTREAM_SWAPQUOTECONTROLLER_H
#define BLOCKSTREAM_SWAPQUOTECONTROLLER_H

#include "controller.h"

#include <QVariantMap>

class SwapQuoteControllerPrivate;

class SwapQuoteController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap quote READ quote NOTIFY updated)
    Q_PROPERTY(QString receiveNetworkKey READ receiveNetworkKey WRITE setReceiveNetworkKey NOTIFY updated)
    Q_PROPERTY(QString sendNetworkKey READ sendNetworkKey WRITE setSendNetworkKey NOTIFY updated)
    QML_ELEMENT
public:
    SwapQuoteController(QObject* parent = nullptr);
    ~SwapQuoteController();
    void setReceiveNetworkKey(const QString& networkKey);
    void setSendNetworkKey(const QString& networkKey);
    QVariantMap quote() const;
    QString receiveNetworkKey() const;
    QString sendNetworkKey() const;
protected:
    void update();
    void timerEvent(QTimerEvent* event) override;
public slots:
    void receive(const QString& amount);
    void send(const QString& amount);
    void swapNetworks();
    void invalidate();
signals:
    void updated();
private:
    SwapQuoteControllerPrivate* const d;
};

#endif // BLOCKSTREAM_SWAPQUOTECONTROLLER_H
