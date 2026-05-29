#ifndef BLOCKSTREAM_SWAPQUOTECONTROLLER_H
#define BLOCKSTREAM_SWAPQUOTECONTROLLER_H

#include "controller.h"

#include <QVariantMap>

class SwapQuoteControllerPrivate;

class SwapQuoteController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap quote READ quote NOTIFY updated)
    Q_PROPERTY(bool lightning READ isLightning WRITE setLightning NOTIFY updated)
    Q_PROPERTY(QString receiveNetworkKey READ receiveNetworkKey WRITE setReceiveNetworkKey NOTIFY updated)
    Q_PROPERTY(QString sendNetworkKey READ sendNetworkKey WRITE setSendNetworkKey NOTIFY updated)
    QML_ELEMENT
public:
    SwapQuoteController(QObject* parent = nullptr);
    ~SwapQuoteController();
    bool isLightning() const;
    void setLightning(bool lightning);
    void setReceiveNetworkKey(const QString& networkKey);
    void setSendNetworkKey(const QString& networkKey);
    QVariantMap quote() const;
    QString receiveNetworkKey() const;
    QString sendNetworkKey() const;
public slots:
    void receive(const QString& amount);
    void send(const QString& amount);
    void swapNetworks();
    void update();
signals:
    void updated();
private:
    SwapQuoteControllerPrivate* const d;
};

#endif // BLOCKSTREAM_SWAPQUOTECONTROLLER_H
