#ifndef GREEN_JADELOGINCONTROLLER_H
#define GREEN_JADELOGINCONTROLLER_H

#include "green.h"

#include <QObject>
#include <QtQml/qqml.h>

#include "controller.h"
#include "task.h"

class JadeDevice;

class JadeController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(JadeDevice* device READ device WRITE setDevice NOTIFY deviceChanged)
    QML_ELEMENT

public:
    JadeController(QObject* parent = nullptr);

    JadeDevice* device() const { return m_device; }
    void setDevice(JadeDevice* device);

signals:
    void deviceChanged();
    void setPin(QVariantMap info);

protected:
    JadeDevice* m_device{nullptr};
};

class JadeSetupController : public JadeController
{
    Q_OBJECT
    QML_ELEMENT
public:
    JadeSetupController(QObject* parent = nullptr);

public slots:
    void setup(const QString& network);
};


class JadeSetupTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
public:
    JadeSetupTask(JadeSetupController* controller);
private:
    void update() override;
private:
    JadeSetupController* const m_controller;
};

class JadeUnlockController : public JadeController
{
    Q_OBJECT
    QML_ELEMENT
public:
    JadeUnlockController(QObject* parent = nullptr);

public slots:
    void unlock();
};

class JadeLoginController : public JadeController
{
    Q_OBJECT
    Q_PROPERTY(QString network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(bool enabled READ isEnabled NOTIFY isEnabledChanged)
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    QML_ELEMENT
public:
    JadeLoginController(QObject* parent = nullptr);
    QString network() const { return m_network; }
    void setNetwork(const QString& network);
    bool isEnabled() const { return m_enabled; }
    void setEnabled(bool enabled);
    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);

public slots:
    void login();

signals:
    void deviceChanged();
    void networkChanged();
    void isEnabledChanged();
    void walletChanged();
    void invalidPin();
    void loginDone();
public:
    JadeDevice* m_device{nullptr};
    QString m_network;
    bool m_enabled{false};
    QString m_wallet_hash_id;
    Wallet* m_wallet{nullptr};
};

class JadeUnlockTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
public:
    JadeUnlockTask(JadeController* controller);
private:
    void update() override;
private:
    JadeController* const m_controller;
};

class JadeIdentifyTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
public:
    JadeIdentifyTask(JadeLoginController* controller);
private:
    void update() override;
private:
    JadeLoginController* const m_controller;
};

class JadeLoginTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
public:
    JadeLoginTask(JadeLoginController* controller);
private:
    void update() override;
private:
    JadeLoginController* const m_controller;
};

#endif // GREEN_JADELOGINCONTROLLER_H
