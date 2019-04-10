#ifndef GREEN_ACCOUNT_H
#define GREEN_ACCOUNT_H

#include <QObject>
#include <QtQml>

class Wallet;

class Account : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(bool mainAccount READ isMainAccount NOTIFY jsonChanged)
    Q_PROPERTY(QJsonObject json READ json NOTIFY jsonChanged)
    Q_PROPERTY(QJsonArray txs READ txs NOTIFY txsChanged)
    Q_PROPERTY(QString name READ name NOTIFY jsonChanged)

public:
    explicit Account(Wallet* wallet);

    Wallet* wallet() const;

    bool isMainAccount() const;

    QString name() const;
    QJsonObject json() const;
    QJsonArray txs() const;

    void update(const QJsonObject& json);

    void handleNotification(const QJsonObject &notification);

signals:
    void walletChanged();
    void jsonChanged();
    void txsChanged();

public slots:
    void reload();

public:
    Wallet* const m_wallet;
    QJsonObject m_json;
    QJsonArray m_txs;
    int m_pointer;
};

QML_DECLARE_TYPE(Account*);

class ReceiveAddress : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(QString address READ address NOTIFY addressChanged)
    Q_PROPERTY(bool generating READ generating NOTIFY generatingChanged)

public:
    explicit ReceiveAddress(QObject* parent = nullptr);

    Account* account() const;
    QString address() const;
    bool generating() const;

    void setAccount(Account* account);

public slots:
    void generate();

signals:
    void accountChanged(Account* account);
    void addressChanged(QString address);
    void generatingChanged(bool generating);

public:
    Account* m_account{nullptr};
    QString m_address;
    bool m_generating{false};
};

#endif // GREEN_ACCOUNT_H
