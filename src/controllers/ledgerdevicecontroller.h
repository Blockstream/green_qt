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
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    QML_ELEMENT
public:
    LedgerDeviceController(QObject* parent = nullptr);
    Device* device() const { return m_device; }
    Network* network() const { return m_network; }
    QString status() const { return m_status; }
    bool indeterminate() const { return m_progress == 0; }
    qreal progress() const { return m_progress; }
    void setDevice(Device* device);
    void login();
private slots:
    void initialize();
signals:
    void deviceChanged(Device* device);
    void networkChanged(Network* network);
    void statusChanged(const QString& status);
    void progressChanged(qreal progress);
private:
    void setStatus(const QString& status);
private:
    Device* m_device{nullptr};
    Network* m_network{nullptr};
    QJsonObject m_device_details;
    QString m_status;
    Wallet* m_wallet{nullptr};
    qreal m_progress{0};
};

#endif // GREEN_LEDGERDEVICECONTROLLER_H
