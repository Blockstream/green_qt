#ifndef GREEN_LEDGERDEVICECONTROLLER_H
#define GREEN_LEDGERDEVICECONTROLLER_H

#include "connectable.h"

#include <QtQml>
#include <QObject>
#include <QTimer>
#include <QJsonArray>

class Activity;
class LedgerDevice;
class Network;
class Session;
class Wallet;

Q_MOC_INCLUDE("session.h")
Q_MOC_INCLUDE("network.h")
Q_MOC_INCLUDE("ledger/ledgerdevice.h")

#include "controller.h"
#include "task.h"

class LedgerDeviceController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(LedgerDevice* device READ device WRITE setDevice NOTIFY deviceChanged)
    Q_PROPERTY(Network* network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(bool indeterminate READ indeterminate NOTIFY progressChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(QString firmwareVersion READ firmwareVersion NOTIFY firmwareChanged)
    Q_PROPERTY(bool enabled READ enabled NOTIFY enabledChanged)
    Q_PROPERTY(QString appName READ appName NOTIFY appNameChanged)
    QML_ELEMENT
public:
    LedgerDeviceController(QObject* parent = nullptr);
    virtual ~LedgerDeviceController();
    LedgerDevice* device() const { return m_device; }
    Network* network() const { return m_network; }
    void setNetwork(Network* network);
    QString status() const { return m_status; }
    bool indeterminate() const { return m_progress == 0; }
    qreal progress() const { return m_progress; }
    void setDevice(LedgerDevice* device);
    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);
    QString firmwareVersion() const { return m_fw_version.toString(); }
    bool enabled() const { return m_enabled; }
    QString appName() const;

public slots:
    void login();

private slots:
    void initialize();
signals:
    void activityCreated(Activity* activity);
    void sessionChanged();
    void deviceChanged();
    void networkChanged();
    void statusChanged();
    void progressChanged(qreal progress);
    void walletChanged();
    void firmwareChanged();
    void appChanged();
    void enabledChanged();
    void loginDone();
    void appNameChanged();

public:
    void setEnabled(bool enabled);
    void setStatus(const QString& status);
public:
    Connectable<Session> m_session;
    LedgerDevice* m_device{nullptr};
    Network* m_network{nullptr};
    QJsonObject m_device_details;
    QString m_status;
    QString m_wallet_hash_id;
    Wallet* m_wallet{nullptr};
    qreal m_progress{0};
    QVersionNumber m_fw_version;
    bool m_enabled{false};
};

class LedgerInitializeTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
public:
    LedgerInitializeTask(LedgerDeviceController* controller);
private:
    void update() override;
private:
    LedgerDeviceController* const m_controller;
};

class LedgerIdentifyTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
public:
    LedgerIdentifyTask(LedgerDeviceController* controller);
private:
    void update() override;
private:
    LedgerDeviceController* const m_controller;
};

class LedgerLoginTask : public ContextTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    LedgerLoginTask(LedgerDeviceController* controller);
private:
    void update() override;
private:
    LedgerDeviceController* const m_controller;
};

#endif // GREEN_LEDGERDEVICECONTROLLER_H
