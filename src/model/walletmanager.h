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
    Q_PROPERTY(bool hasOpenUrl READ hasOpenUrl NOTIFY openUrlChanged FINAL)
    Q_PROPERTY(QString openUrl READ openUrl WRITE setOpenUrl NOTIFY openUrlChanged FINAL)
public:
    explicit WalletManager();
    virtual ~WalletManager();
    static WalletManager* instance();

    bool hasOpenUrl() const { return !m_open_url.isEmpty(); }
    QString openUrl() const { return m_open_url; }
    void setOpenUrl(const QString& open_url);

    void loadWallets();
    Wallet* createWallet();
    Q_INVOKABLE Wallet* wallet(const QString& id) const;
    Wallet* walletWithHashId(const QString& hash_id, bool watch_only) const;

    void addWallet(Wallet *wallet);

    Q_INVOKABLE void insertWallet(Wallet* wallet);
    Q_INVOKABLE void removeWallet(Wallet* wallet);

    int size() const { return m_wallets.size(); }

    QVector<Wallet*> getWallets() const { return m_wallets; }
    QQmlListProperty<Wallet> wallets();

    QString newWalletName() const;
    QString uniqueWalletName(const QString& base) const;

signals:
    void changed();
    void walletAdded(Wallet* wallet);
    void aboutToRemove(Wallet* wallet);
    void openUrlChanged();

public slots:
    QStringList generateMnemonic(int size);
    void printBackupTemplate();
    void clearOpenUrl();
public:
    QVector<Wallet*> m_wallets;
    QString m_open_url;
};

#endif // GREEN_WALLETMANAGER_H
