#ifndef GREEN_RESTORECONTROLLER_H
#define GREEN_RESTORECONTROLLER_H

#include "green.h"

#include <QObject>
#include <QQmlEngine>

#include "controller.h"
#include "task.h"

class RestoreController : public Controller
{
    Q_OBJECT
//    Q_PROPERTY(Network* network READ network WRITE setNetwork NOTIFY networkChanged)
//    Q_PROPERTY(QString type READ type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic WRITE setMnemonic NOTIFY mnemonicChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
//    Q_PROPERTY(bool valid READ isValid NOTIFY validChanged)
//    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
//    Q_PROPERTY(QString pin READ pin WRITE setPin NOTIFY pinChanged)
//    Q_PROPERTY(bool active READ isActive WRITE setActive NOTIFY activeChanged)
//    Q_PROPERTY(bool accepted READ accepted NOTIFY acceptedChanged)
    QML_ELEMENT

public:
    explicit RestoreController(QObject *parent = nullptr);
//    Network* network() const { return m_network; }
//    void setNetwork(Network* network);
//    QString type() const { return m_type; }
//    void setType(const QString& type);
    QStringList mnemonic() const { return m_mnemonic; }
    void setMnemonic(const QStringList& mnemonic);
    QString password() const { return m_password; }
    void setPassword(const QString& password);
//    bool isValid() const { return m_valid; }
//    void setValid(bool valid);
//    Wallet* wallet() const { return m_wallet; }
//    void setWallet(Wallet* wallet);
//    QString pin() const { return m_pin; }
//    void setPin(const QString& pin);
//    bool isActive() const { return m_active; }
//    void setActive(bool active);
//    bool accepted() const { return m_accepted; }

public slots:
    void restore(const QString& deployment);

private slots:
//    void update();

signals:
    void progressChanged();
    void networkChanged();
    void typeChanged();
    void mnemonicChanged();
    void passwordChanged();
    void walletChanged();
    void pinChanged();
    void activeChanged();
    void validChanged();
    void loginError();
    void acceptedChanged();
    void walletRestored(Wallet* wallet);
    void restoreFinished(Context* context);
    void alreadyRestored(Wallet* wallet);
private:
//    Network* m_network{nullptr};
//    QString m_type;
    QStringList m_mnemonic;
    QString m_password;
//    bool m_valid{false};
//    Wallet* m_wallet{nullptr};
//    QString m_pin;
//    bool m_active{false};
//    bool m_accepted{false};
//    QString m_wallet_hash_id;
    //    QJsonArray m_subaccounts;
    TaskGroup* check(Network* network);

    QList<Account*> m_accounts;
};

class RestoreCheckTask : public Task
{
    Q_OBJECT
public:
    RestoreCheckTask(RestoreController* controller);
    void update() override;
private:
    RestoreController* const m_controller;
};

#endif // GREEN_RESTORECONTROLLER_H
