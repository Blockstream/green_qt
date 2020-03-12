#ifndef GREEN_WALLETMANAGER_H
#define GREEN_WALLETMANAGER_H

#include <QJsonObject>
#include <QObject>
#include <QQmlListProperty>
#include <QVector>

class Network;
class Wallet;

class WalletManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<Wallet> wallets READ wallets NOTIFY walletsChanged)

public:
    static WalletManager* instance();

    Q_INVOKABLE Wallet* createWallet();

    Q_INVOKABLE void insertWallet(Wallet* wallet);

    QQmlListProperty<Wallet> wallets();

    Q_INVOKABLE QString newWalletName(Network* network) const;

signals:
    void walletsChanged();

public slots:
    QStringList generateMnemonic() const;
    QJsonObject parseUrl(const QString &url);
    Wallet* signup(const QString& proxy, bool use_tor, Network* network, const QString& name, const QStringList &mnemonic, const QByteArray& pin);

private:
    explicit WalletManager();

    QVector<Wallet*> m_wallets;
};

#endif // GREEN_WALLETMANAGER_H
