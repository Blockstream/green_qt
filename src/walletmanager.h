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
    Q_PROPERTY(QQmlListProperty<Wallet> wallets READ wallets NOTIFY changed)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY changed)
    Q_PROPERTY(QQmlListProperty<Wallet> filteredWallets READ filteredWallets NOTIFY changed)
public:
    static WalletManager* instance();

    Q_INVOKABLE Wallet* createWallet();

    Q_INVOKABLE void insertWallet(Wallet* wallet);
    Q_INVOKABLE void removeWallet(Wallet* wallet);

    QQmlListProperty<Wallet> wallets();
    QQmlListProperty<Wallet> filteredWallets();

    Q_INVOKABLE QString newWalletName(Network* network) const;

    QString filter() const { return m_filter; }
    void setFilter(const QString &filter);
signals:
    void changed();

public slots:
    QStringList generateMnemonic() const;
    QJsonObject parseUrl(const QString &url);
    Wallet* signup(const QString& proxy, bool use_tor, Network* network, const QString& name, const QStringList &mnemonic, const QByteArray& pin);

private:
    explicit WalletManager();
    void addWallet(Wallet *wallet);

    QVector<Wallet*> m_wallets;
    QVector<Wallet*> m_filtered_wallets;
    QString m_filter;
    void updateFilteredWallets();
};

#endif // GREEN_WALLETMANAGER_H
