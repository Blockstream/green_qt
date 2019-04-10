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
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(bool online READ isOnline NOTIFY isOnlineChanged)
    Q_PROPERTY(bool logged READ isLogged NOTIFY isLoggedChanged)
    Q_PROPERTY(bool authenticating READ isAuthenticating NOTIFY isAuthenticatingChanged)
    Q_PROPERTY(QList<QObject*> accounts READ accounts NOTIFY accountsChanged)
    Q_PROPERTY(QJsonObject events READ events NOTIFY eventsChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic)

public:
    explicit Wallet(QObject *parent = nullptr);
    virtual ~Wallet();

    bool isOnline() const { return m_online; }
    bool isLogged() const { return m_logged; }

    QList<QObject*> accounts() const;

    bool isAuthenticating() const;

    void handleNotification(const QJsonObject& notification);

    QJsonObject events() const;

    QStringList mnemonic() const;

public slots:
    void test();
    void login(const QByteArray& pin);
    void signup(const QString& name, const QStringList &mnemonic, const QByteArray& pin);
    void recover(const QString& name, const QStringList& mnemonic, const QByteArray& pin);
    void reload();
    QStringList generateMnemonic() const;
    void setup2F();

signals:
    void isOnlineChanged();
    void isLoggedChanged();
    void accountsChanged();

    void isAuthenticatingChanged(bool authenticating);

    void eventsChanged(QJsonObject events);

    void nameChanged(QString name);

public:
    QThread* m_thread{new QThread};
    QObject* m_context{new QObject};
    GA_session* m_session{nullptr};
    bool m_online{false};
    bool m_logged{false};
    bool m_authenticating{false};
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

#endif // GREEN_WALLET_H
