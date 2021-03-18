#ifndef GREEN_JADELOGINCONTROLLER_H
#define GREEN_JADELOGINCONTROLLER_H

#include <QtQml/qqml.h>
#include <QObject>
#include <QSet>

QT_FORWARD_DECLARE_CLASS(JadeDevice)
QT_FORWARD_DECLARE_CLASS(Wallet)

class JadeLoginController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(JadeDevice* device READ device WRITE setDevice NOTIFY deviceChanged)
    Q_PROPERTY(QString network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    QML_ELEMENT
public:
    JadeLoginController(QObject* parent = nullptr);
    JadeDevice* device() const { return m_device; }
    void setDevice(JadeDevice* device);
    QString network() const { return m_network; }
    void setNetwork(const QString& network);
    Wallet* wallet() const { return m_wallet; }
public slots:
    void login();
private slots:
    void update();
signals:
    void deviceChanged(JadeDevice* device);
    void networkChanged(const QString& network);
    void walletChanged(Wallet* wallet);
    void invalidPin();
private:
    JadeDevice* m_device{nullptr};
    QString m_network;
    Wallet* m_wallet{nullptr};
    bool m_active{false};
};

#endif // GREEN_JADELOGINCONTROLLER_H
