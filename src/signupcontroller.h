#ifndef GREEN_SIGNUPCONTROLLER_H
#define GREEN_SIGNUPCONTROLLER_H

#include <QtQml>
#include <QObject>

class Network;
class Wallet;

class SignupController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList mnemonic READ mnemonic CONSTANT)
    Q_PROPERTY(Network* network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(QString defaultName READ defaultName NOTIFY defaultNameChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    QML_ELEMENT
public:
    explicit SignupController(QObject* parent = nullptr);
    QStringList mnemonic() const;
    Network* network() const;
    void setNetwork(Network* network);
    QString defaultName() const;
    QString name() const;
    void setName(const QString& name);
    Wallet* wallet() const;
public slots:
    Wallet* signup(const QString& proxy, bool use_tor, const QByteArray& pin);
signals:
    void networkChanged(Network* network);
    void defaultNameChanged(const QString& default_name);
    void nameChanged(const QString& name);
    void walletChanged(Wallet* wallet);
private:
    void setDefaultName(const QString& default_name);
private:
    QStringList m_mnemonic;
    Network* m_network{nullptr};
    QString m_defaultName;
    QString m_name;
    Wallet* m_wallet;
};

#endif // GREEN_SIGNUPCONTROLLER_H
