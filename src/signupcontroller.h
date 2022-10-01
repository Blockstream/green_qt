#ifndef GREEN_SIGNUPCONTROLLER_H
#define GREEN_SIGNUPCONTROLLER_H

#include <QObject>
#include <QtQml>

#include "connectable.h"
#include "network.h"
#include "session.h"
#include "wallet.h"

QT_FORWARD_DECLARE_CLASS(Network);
QT_FORWARD_DECLARE_CLASS(Session);
QT_FORWARD_DECLARE_CLASS(Wallet);

class SignupController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList mnemonic READ mnemonic WRITE setMnemonic NOTIFY mnemonicChanged)
    Q_PROPERTY(Network* network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(QString type READ type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(QString pin READ pin WRITE setPin NOTIFY pinChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    QML_ELEMENT
public:
    explicit SignupController(QObject* parent = nullptr);
    QStringList mnemonic() const { return m_mnemonic; }
    void setMnemonic(const QStringList &mnemonic);
    Network* network() const { return m_network.get(); };
    void setNetwork(Network* network);
    QString type() const { return m_type; }
    void setType(const QString& type);
    Wallet* wallet() const { return m_wallet.get(); }
    QString pin() const { return m_pin; }
    void setPin(const QString& pin);
    bool active() const { return m_active; }
    void setActive(bool active);
public slots:
    QStringList generateMnemonic(int size);
private slots:
    void update();
signals:
    void networkChanged(Network* network);
    void walletChanged(Wallet* wallet);
    void pinChanged(const QString& pin);
    void activeChanged(bool active);
    void typeChanged(const QString& type);
    void mnemonicSizeChanged(int mnemonicSize);
    void mnemonicChanged(const QStringList &mnemonic);
    void finished();
private:
    QStringList m_mnemonic;
    Connectable<Network> m_network;
    Connectable<Wallet> m_wallet;
    Session* m_session{nullptr};
    QString m_pin;
    bool m_active{false};
    int m_mnemonic_size;
    QString m_type{"default"};
    QString m_wallet_hash_id;
};

#endif // GREEN_SIGNUPCONTROLLER_H
