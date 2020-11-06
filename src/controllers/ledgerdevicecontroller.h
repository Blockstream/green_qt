#ifndef GREEN_LEDGERDEVICECONTROLLER_H
#define GREEN_LEDGERDEVICECONTROLLER_H

#include <QtQml>
#include <QObject>
#include <QTimer>
#include <QJsonArray>

QT_FORWARD_DECLARE_CLASS(Device)
QT_FORWARD_DECLARE_CLASS(Network)
QT_FORWARD_DECLARE_CLASS(Wallet)

QT_FORWARD_DECLARE_STRUCT(GA_json)
QT_FORWARD_DECLARE_STRUCT(GA_auth_handler)

class LedgerDeviceController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Device* device READ device WRITE setDevice NOTIFY deviceChanged)
    Q_PROPERTY(Network* network READ network NOTIFY networkChanged)
    Q_PROPERTY(bool indeterminate READ indeterminate NOTIFY progressChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    QML_ELEMENT
public:
    LedgerDeviceController(QObject* parent = nullptr);
    Device* device() const { return m_device; }
    Network* network() const { return m_network; }
    bool indeterminate() const { return m_progress == 0; }
    qreal progress() const { return m_progress; }
    void setDevice(Device* device);
    void login();
    void login2();
    static Network *networkFromAppName(const QString& app_name);
private slots:
    void initialize();
signals:
    void deviceChanged(Device* device);
    void networkChanged(Network* network);
    void progressChanged(qreal progress);
private:
    Device* m_device{nullptr};
    Network* m_network{nullptr};
    QJsonObject m_device_details;
    Wallet* m_wallet{nullptr};
    GA_auth_handler* m_login_handler;
    QJsonArray m_paths;
    QJsonArray m_xpubs;
    qreal m_progress{0};

    QTimer* m_timer{nullptr};
};

#endif // GREEN_LEDGERDEVICECONTROLLER_H
