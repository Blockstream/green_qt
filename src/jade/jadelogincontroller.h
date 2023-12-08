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
    QML_UNCREATABLE("")
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
    Network* network() const { return m_network; }
public slots:
    void setup(const QString& deployment);
signals:
    void setupFinished(Context* context);
private:
    Network* m_network{nullptr};
};


class JadeSetupTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
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
    Q_PROPERTY(bool remember READ remember WRITE setRemember NOTIFY rememberChanged)
    QML_ELEMENT
public:
    JadeUnlockController(QObject* parent = nullptr);
    bool remember() const { return m_remember; }
    void setRemember(bool remember);
    Network* network() const { return m_network; }
public slots:
    void unlock();
signals:
    void rememberChanged();
    void unlocked(Context* context);
    void invalidPin();
private:
    bool m_remember{false};
    Network* m_network{nullptr};
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

    QString walletHashId() const { return m_wallet_hash_id; }
    void setWalletHashId(const QString& wallet_hash_id);

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
    QString m_network;
    bool m_enabled{false};
    Wallet* m_wallet{nullptr};
private:
    QString m_wallet_hash_id;
};

class JadeUnlockTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeUnlockTask(JadeUnlockController* controller);
private:
    void update() override;
private:
    JadeUnlockController* const m_controller;
};

class JadeIdentifyTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeIdentifyTask(JadeController* controller);
private:
    void update() override;
private:
    JadeController* const m_controller;
};

class JadeLoginTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeLoginTask(JadeLoginController* controller);
private:
    void update() override;
private:
    JadeLoginController* const m_controller;
};

#endif // GREEN_JADELOGINCONTROLLER_H
