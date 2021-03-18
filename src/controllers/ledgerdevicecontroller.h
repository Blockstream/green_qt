#ifndef GREEN_LEDGERDEVICECONTROLLER_H
#define GREEN_LEDGERDEVICECONTROLLER_H

#include "connectable.h"

#include <QtQml>
#include <QObject>
#include <QTimer>
#include <QJsonArray>

QT_FORWARD_DECLARE_CLASS(Activity)
QT_FORWARD_DECLARE_CLASS(Device)
QT_FORWARD_DECLARE_CLASS(Network)
QT_FORWARD_DECLARE_CLASS(Session)
QT_FORWARD_DECLARE_CLASS(Wallet)

class LedgerDeviceController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Session* session READ session NOTIFY sessionChanged)
    Q_PROPERTY(Device* device READ device WRITE setDevice NOTIFY deviceChanged)
    Q_PROPERTY(Network* network READ network NOTIFY networkChanged)
    Q_PROPERTY(bool indeterminate READ indeterminate NOTIFY progressChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    QML_ELEMENT
public:
    LedgerDeviceController(QObject* parent = nullptr);
    virtual ~LedgerDeviceController();
    Session* session() const { return m_session; }
    Device* device() const { return m_device; }
    Network* network() const { return m_network; }
    QString status() const { return m_status; }
    bool indeterminate() const { return m_progress == 0; }
    qreal progress() const { return m_progress; }
    void setDevice(Device* device);
    Wallet* wallet() const { return m_wallet; }

public slots:
    void login();
private slots:
    void initialize();
signals:
    void activityCreated(Activity* activity);
    void sessionChanged(Session* session);
    void deviceChanged(Device* device);
    void networkChanged(Network* network);
    void statusChanged(const QString& status);
    void progressChanged(qreal progress);
    void walletChanged(Wallet* wallet);
private:
    void setStatus(const QString& status);
private:
    Connectable<Session> m_session;
    Device* m_device{nullptr};
    Network* m_network{nullptr};
    QJsonObject m_device_details;
    QString m_status;
    Wallet* m_wallet{nullptr};
    qreal m_progress{0};
};

#endif // GREEN_LEDGERDEVICECONTROLLER_H
