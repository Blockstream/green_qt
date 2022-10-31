#ifndef GREEN_LEDGERDEVICECONTROLLER_H
#define GREEN_LEDGERDEVICECONTROLLER_H

#include "connectable.h"

#include <QtQml>
#include <QObject>
#include <QTimer>
#include <QJsonArray>

QT_FORWARD_DECLARE_CLASS(Activity)
QT_FORWARD_DECLARE_CLASS(LedgerDevice)
QT_FORWARD_DECLARE_CLASS(LoginHandler)
QT_FORWARD_DECLARE_CLASS(Network)
QT_FORWARD_DECLARE_CLASS(Session)
QT_FORWARD_DECLARE_CLASS(Wallet)

class LedgerDeviceController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Session* session READ session NOTIFY sessionChanged)
    Q_PROPERTY(LedgerDevice* device READ device WRITE setDevice NOTIFY deviceChanged)
    Q_PROPERTY(Network* network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(bool indeterminate READ indeterminate NOTIFY progressChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(QString firmwareVersion READ firmwareVersion NOTIFY firmwareChanged)
    Q_PROPERTY(QString appVersion READ appVersion NOTIFY appChanged)
    Q_PROPERTY(bool enabled READ enabled NOTIFY enabledChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    QML_ELEMENT
public:
    LedgerDeviceController(QObject* parent = nullptr);
    virtual ~LedgerDeviceController();
    Session* session() const { return m_session; }
    LedgerDevice* device() const { return m_device; }
    Network* network() const { return m_network; }
    void setNetwork(Network* network);
    QString status() const { return m_status; }
    bool indeterminate() const { return m_progress == 0; }
    qreal progress() const { return m_progress; }
    void setDevice(LedgerDevice* device);
    Wallet* wallet() const { return m_wallet; }
    QString firmwareVersion() const { return m_fw_version.toString(); }
    QString appVersion() const { return m_app_version.toString(); }
    bool enabled() const { return m_enabled; }
    bool active() const { return m_active; }
public slots:
    void setActive(bool active);

private slots:
    void initialize();
signals:
    void activityCreated(Activity* activity);
    void sessionChanged(Session* session);
    void deviceChanged(LedgerDevice* device);
    void networkChanged(Network* network);
    void statusChanged(const QString& status);
    void progressChanged(qreal progress);
    void walletChanged(Wallet* wallet);
    void firmwareChanged();
    void appChanged();
    void activeChanged(bool active);
    void enabledChanged();
    void loginDone();
private:
    void update();
    void connect();
    void identify();
    void login();
    void signup();
    void setEnabled(bool enabled);
    void setStatus(const QString& status);
private:
    Connectable<Session> m_session;
    LedgerDevice* m_device{nullptr};
    QString m_network_key;
    Network* m_network{nullptr};
    QJsonObject m_device_details;
    QString m_status;
    QString m_wallet_hash_id;
    Wallet* m_wallet{nullptr};
    qreal m_progress{0};
    QVersionNumber m_fw_version;
    QVersionNumber m_app_version;
    QString m_app_name;
    bool m_active{false};
    LoginHandler* m_login_handler{nullptr};
    bool m_enabled{false};
};

#endif // GREEN_LEDGERDEVICECONTROLLER_H
