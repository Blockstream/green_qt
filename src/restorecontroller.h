#ifndef GREEN_RESTORECONTROLLER_H
#define GREEN_RESTORECONTROLLER_H

#include "entity.h"
#include "session.h"
#include "wallet.h"

#include <QtQml>
#include <QObject>

QT_FORWARD_DECLARE_CLASS(Network)
QT_FORWARD_DECLARE_CLASS(Wallet)

class RestoreController : public Entity
{
    Q_OBJECT
    Q_PROPERTY(Network* network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(QString type READ type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic WRITE setMnemonic NOTIFY mnemonicChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(bool valid READ isValid NOTIFY validChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(QString pin READ pin WRITE setPin NOTIFY pinChanged)
    Q_PROPERTY(bool active READ isActive WRITE setActive NOTIFY activeChanged)
    QML_ELEMENT
public:
    explicit RestoreController(QObject *parent = nullptr);
    Network* network() const { return m_network; }
    void setNetwork(Network* network);
    QString type() const { return m_type; }
    void setType(const QString& type);
    QStringList mnemonic() const { return m_mnemonic; }
    void setMnemonic(const QStringList& mnemonic);
    QString password() const { return m_password; }
    void setPassword(const QString& password);
    bool isValid() const { return m_valid; }
    Wallet* wallet() const { return m_wallet; }
    QString pin() const { return m_pin; }
    void setPin(const QString& pin);
    bool isActive() const { return m_active; }
    void setActive(bool active);
public slots:
    void accept();
private slots:
    void update();
signals:
    void networkChanged(Network* network);
    void typeChanged(const QString& type);
    void mnemonicChanged(const QStringList& mnemonic);
    void passwordChanged(const QString& password);
    void walletChanged(Wallet* wallet);
    void pinChanged(const QString& pin);
    void activeChanged(bool active);
    void validChanged(bool valid);
    void loginError(const QString& error);
private:
    Network* m_network{nullptr};
    QString m_type;
    QStringList m_mnemonic;
    QString m_password;
    bool m_valid{false};
    Wallet* m_wallet{nullptr};
    QString m_pin;
    bool m_active{false};
    Connectable<Session> m_session;
    bool m_accepted{false};
};

class CheckRestoreActivity : public WalletActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    CheckRestoreActivity(Wallet* wallet, QObject* parent);
    void exec() override {}
};

class AcceptRestoreActivity : public WalletActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    AcceptRestoreActivity(Wallet* wallet, QObject* parent);
    void exec() override {}
};

#endif // GREEN_RESTORECONTROLLER_H
