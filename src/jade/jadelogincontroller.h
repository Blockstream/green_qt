#ifndef GREEN_JADELOGINCONTROLLER_H
#define GREEN_JADELOGINCONTROLLER_H

#include <QObject>
#include <QtQml/qqml.h>

QT_FORWARD_DECLARE_CLASS(JadeDevice)
QT_FORWARD_DECLARE_CLASS(Session)
QT_FORWARD_DECLARE_CLASS(Wallet)

class JadeLoginController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(JadeDevice* device READ device WRITE setDevice NOTIFY deviceChanged)
    Q_PROPERTY(Session* session READ session NOTIFY sessionChanged)
    Q_PROPERTY(QString network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(bool enabled READ isEnabled NOTIFY isEnabledChanged)
    Q_PROPERTY(bool active READ isActive WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    QML_ELEMENT
public:
    JadeLoginController(QObject* parent = nullptr);
    JadeDevice* device() const { return m_device; }
    void setDevice(JadeDevice* device);
    Session* session() const { return m_session; }
    QString network() const { return m_network; }
    void setNetwork(const QString& network);
    bool isEnabled() const { return m_enabled; }
    void setEnabled(bool enabled);
    bool isActive() const { return m_active; }
    void setActive(bool active);
    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);
    QString status() const { return m_status; }
private slots:
    void update();
private:
    void connect();
    void unlock();
    void identify();
    void login();
    void signup();
signals:
    void deviceChanged(JadeDevice* device);
    void sessionChanged(Session* session);
    void networkChanged(const QString& network);
    void isEnabledChanged(bool enabled);
    void walletChanged(Wallet* wallet);
    void invalidPin();
    void statusChanged();
    void activeChanged(bool active);
    void loginDone();
private:
    JadeDevice* m_device{nullptr};
    Session* m_session{nullptr};
    QString m_network;
    bool m_enabled{false};
    bool m_active{false};
    QString m_wallet_hash_id;
    Wallet* m_wallet{nullptr};
    QString m_status;
    bool m_identifying{false};
};

#endif // GREEN_JADELOGINCONTROLLER_H
