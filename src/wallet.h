#ifndef GREEN_WALLET_H
#define GREEN_WALLET_H

#include <QList>
#include <QObject>
#include <QQmlListProperty>
#include <QThread>
#include <QJsonObject>

class Account;

struct GA_session;
struct GA_auth_handler;
struct GA_json;

class Wallet : public QObject
{
    Q_OBJECT

public:
    enum StatusFlag {
        Disconnected    = 0x01,
        Connecting      = 0x02,
        Connected       = 0x04,
        Authenticating  = 0x10,
        Authenticated   = 0x20,

        Unauthenticated = Disconnected | Connecting | Connected,
        Working         = Connecting | Authenticating,
        Ready           = Connected | Authenticated
    };
    Q_DECLARE_FLAGS(Status, StatusFlag)
    Q_FLAG(Status)

private:
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Q_PROPERTY(QJsonObject settings READ settings NOTIFY settingsChanged)
    Q_PROPERTY(QJsonObject currencies READ currencies CONSTANT)
    Q_PROPERTY(QList<QObject*> accounts READ accounts NOTIFY accountsChanged)
    Q_PROPERTY(QJsonObject events READ events NOTIFY eventsChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic CONSTANT)
    Q_PROPERTY(int loginAttemptsRemaining READ loginAttemptsRemaining NOTIFY loginAttemptsRemainingChanged)
    Q_PROPERTY(QJsonObject balance READ balance NOTIFY balanceChanged)

public:
    explicit Wallet(QObject *parent = nullptr);
    virtual ~Wallet();

    Status status() const { return m_status; }

    QJsonObject settings() const;
    QJsonObject currencies() const;

    QList<QObject*> accounts() const;

    void handleNotification(const QJsonObject& notification);

    QJsonObject events() const;

    QStringList mnemonic() const;

    int loginAttemptsRemaining() const { return m_login_attempts_remaining; }

    QJsonObject balance() const { return m_balance; }
public slots:
    void connect();
    void test();
    void login(const QByteArray& pin);
    void signup(const QStringList &mnemonic, const QString& password, const QByteArray& pin);
    void recover(const QString& name, const QStringList& mnemonic, const QByteArray& pin);
    void reload();
    void setup2F();

signals:
    void statusChanged();
    void isOnlineChanged();
    void isLoggedChanged();
    void accountsChanged();

    void isAuthenticatingChanged(bool authenticating);

    void eventsChanged(QJsonObject events);

    void nameChanged(QString name);

    void loginAttemptsRemainingChanged(int loginAttemptsRemaining);

    void balanceChanged(const QJsonObject& balance);

    void settingsChanged();

private:
    void setStatus(Status status);
    void setBalance(const QJsonObject& balance);

public:
    int m_index{0};
    QThread* m_thread{nullptr};
    QObject* m_context{nullptr};
    GA_session* m_session{nullptr};
    Status m_status{Disconnected};
    QJsonObject m_settings;
    QJsonObject m_currencies;
    QList<QObject*> m_accounts;
    QMap<int, Account*> m_accounts_by_pointer;
    QJsonObject m_events;
    QStringList m_mnemonic;

    QByteArray getPinData() const;
    QByteArray m_pin_data;
    QString m_name;
    QString name() const
    {
        return m_name;
    }
    QString m_network;
    int m_login_attempts_remaining{3};
    QString m_proxy;
    bool m_use_tor{false};
    QJsonObject m_balance;
};

class AmountConverter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    Q_PROPERTY(bool valid READ valid NOTIFY validChanged)
    Q_PROPERTY(QJsonObject input READ input WRITE setInput NOTIFY inputChanged)
    Q_PROPERTY(QJsonObject output READ output NOTIFY outputChanged)

public:
    explicit AmountConverter(QObject* parent = nullptr);

    Wallet* wallet() const;
    QJsonObject input() const;
    QJsonObject output() const;

    void setWallet(Wallet* wallet);
    void setInput(const QJsonObject& input);

    bool valid() const;

signals:
    void walletChanged(Wallet* wallet);
    void inputChanged(QJsonObject input);
    void outputChanged(QJsonObject output);

    void validChanged(bool valid);

private:
    Wallet* m_wallet{nullptr};
    QJsonObject m_input;
    QJsonObject m_output;
    bool m_valid{false};

    void update();
};

Q_DECLARE_OPERATORS_FOR_FLAGS(Wallet::Status)

#endif // GREEN_WALLET_H
