#ifndef GREEN_SIGNUPCONTROLLER_H
#define GREEN_SIGNUPCONTROLLER_H

#include "green.h"

#include <QObject>
#include <QQmlEngine>

#include "controller.h"
#include "task.h"

class SignupController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Network* network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic WRITE setMnemonic NOTIFY mnemonicChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    QML_ELEMENT
public:
    explicit SignupController(QObject* parent = nullptr);

    Network* network() const { return m_network; };
    void setNetwork(Network* network);

    QStringList mnemonic() const { return m_mnemonic; }
    void setMnemonic(const QStringList &mnemonic);

    bool active() const { return m_active; }
    void setActive(bool active);

    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);

signals:
    void networkChanged();
    void walletChanged();
    void activeChanged();
    void mnemonicSizeChanged();
    void mnemonicChanged();
    void registerFinished(Context* context);

private:
    Network* m_network{nullptr};
    QStringList m_mnemonic;
    bool m_active{false};
    Wallet* m_wallet{nullptr};
};

class SignupCreateWalletTask : public Task
{
    Q_OBJECT
public:
    SignupCreateWalletTask(SignupController* controller);
    void update() override;
private:
    SignupController* const m_controller;
};

class SignupPersistWalletTask : public Task
{
    Q_OBJECT
public:
    SignupPersistWalletTask(SignupController* controller);
    void update() override;
private:
    SignupController* const m_controller;
};

#endif // GREEN_SIGNUPCONTROLLER_H
