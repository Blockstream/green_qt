#ifndef GREEN_SIGNUPCONTROLLER_H
#define GREEN_SIGNUPCONTROLLER_H

#include "connectable.h"
#include "network.h"
#include "session.h"
#include "wallet.h"

#include <QtQml>
#include <QObject>

QT_FORWARD_DECLARE_CLASS(Network);
QT_FORWARD_DECLARE_CLASS(Session);
QT_FORWARD_DECLARE_CLASS(Wallet);

class SignupController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList mnemonic READ mnemonic CONSTANT)
    Q_PROPERTY(Network* network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(QString type READ type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(QString defaultName READ defaultName NOTIFY defaultNameChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(QByteArray pin READ pin WRITE setPin NOTIFY pinChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    QML_ELEMENT
public:
    explicit SignupController(QObject* parent = nullptr);
    QStringList mnemonic() const;
    Network* network() const;
    void setNetwork(Network* network);
    QString type() const { return m_type; }
    void setType(const QString& type);
    QString defaultName() const;
    QString name() const;
    void setName(const QString& name);
    Wallet* wallet() const;
    QByteArray pin() const { return m_pin; }
    void setPin(const QByteArray& pin);
    bool active() const { return m_active; }
    void setActive(bool active);
private slots:
    void update();
signals:
    void networkChanged(Network* network);
    void defaultNameChanged(const QString& default_name);
    void nameChanged(const QString& name);
    void walletChanged(Wallet* wallet);
    void pinChanged(const QByteArray& pin);
    void activeChanged(bool active);
    void typeChanged(const QString& type);
private:
    void setDefaultName(const QString& default_name);
private:
    QStringList m_mnemonic;
    Connectable<Network> m_network{nullptr};
    QString m_defaultName;
    QString m_name;
    Connectable<Wallet> m_wallet;
    Connectable<Session> m_session;
    QByteArray m_pin;
    bool m_active{false};
    QString m_type;
};

#endif // GREEN_SIGNUPCONTROLLER_H
