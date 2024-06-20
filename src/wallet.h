#ifndef GREEN_WALLET_H
#define GREEN_WALLET_H

#include "green.h"

#include <QAtomicInteger>
#include <QJsonObject>
#include <QList>
#include <QQmlEngine>
#include <QQmlListProperty>
#include <QObject>

QString ComputeDisplayUnit(Network* network, QString unit);

class LoginData : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoginData(Wallet* wallet);
    virtual bool write(QJsonObject& data) = 0;
    virtual bool read(const QJsonObject& data) = 0;
protected:
    Wallet* const m_wallet;
};

class PinData : public LoginData
{
    Q_OBJECT
    Q_PROPERTY(Network* network READ network NOTIFY networkChanged)
    Q_PROPERTY(bool passphrase READ passphrase WRITE setPassphrase NOTIFY passphraseChanged)
    Q_PROPERTY(int attempts READ attempts NOTIFY attemptsChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    PinData(Wallet* wallet) : LoginData(wallet) {}
    Network* network() const { return m_network; }
    void setNetwork(Network* network);
    bool passphrase() const { return m_passphrase; }
    void setPassphrase(bool passphrase);
    QJsonObject data() const { return m_data; }
    void setData(const QJsonObject& data);
    int attempts() const { return m_attempts; }
    void setAttempts(int attempts);
    void resetAttempts();
    void decrementAttempts();
    virtual bool write(QJsonObject& data) override;
    virtual bool read(const QJsonObject& data) override;
signals:
    void networkChanged();
    void passphraseChanged();
    void attemptsChanged();
private:
    Network* m_network{nullptr};
    bool m_passphrase{false};
    QJsonObject m_data;
    int m_attempts{3};
};

class DeviceData : public LoginData
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject device READ device NOTIFY deviceChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    DeviceData(Wallet* wallet) : LoginData(wallet) {}
    QJsonObject device() const { return m_device; }
    void setDevice(const QJsonObject& device);
    bool write(QJsonObject& data) override;
    bool read(const QJsonObject& data) override;
signals:
    void deviceChanged();
private:
    QJsonObject m_device;
};

class WatchonlyData : public LoginData
{
    Q_OBJECT
    Q_PROPERTY(Network* network READ network NOTIFY networkChanged)
    Q_PROPERTY(QString username READ username NOTIFY usernameChanged)
    Q_PROPERTY(QStringList coreDescriptors READ coreDescriptors NOTIFY coreDescriptorsChanged)
    Q_PROPERTY(QStringList extendedPubkeys READ extendedPubkeys NOTIFY extendedPubkeysChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    WatchonlyData(Wallet* wallet) : LoginData(wallet) {}
    Network* network() const { return m_network; }
    void setNetwork(Network* network);
    QString username() const { return m_username; }
    void setUsername(const QString& username);
    QStringList coreDescriptors() const { return m_core_descriptors; }
    void setCoreDescriptors(const QStringList& core_descriptors);
    QStringList extendedPubkeys() const { return m_extended_pubkeys; }
    void setExtendedPubkeys(const QStringList& extended_pubkeys);
    bool write(QJsonObject& data) override;
    bool read(const QJsonObject& data) override;
signals:
    void networkChanged();
    void usernameChanged();
    void coreDescriptorsChanged();
    void extendedPubkeysChanged();
private:
    Network* m_network{nullptr};
    QString m_username;
    QStringList m_core_descriptors;
    QStringList m_extended_pubkeys;
};

class Wallet : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString deployment READ deployment CONSTANT)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(bool persisted READ isPersisted NOTIFY isPersistedChanged)
    Q_PROPERTY(Context* context READ context NOTIFY contextChanged)
    Q_PROPERTY(QString xpubHashId READ xpubHashId NOTIFY xpubHashIdChanged)
    Q_PROPERTY(LoginData* login READ login NOTIFY loginChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    explicit Wallet(QObject* parent = nullptr);
    virtual ~Wallet();

    Context* context() const { return m_context; }
    void setContext(Context* context);

    QString id() const;
    QString deployment() const { return m_deployment; }
    bool isPersisted() const { return m_is_persisted; }
    QString name() const { return m_name; }
    void setName(const QString& name);

    LoginData* login() const { return m_login; }
    void setLogin(LoginData* login);

    Q_INVOKABLE QJsonObject convert(const QJsonObject& value) const;

    QString formatAmount(qint64 amount, bool include_ticker) const;
    Q_INVOKABLE QString formatAmount(qint64 amount, bool include_ticker, const QString& unit) const;

    void updateHashId(const QString& hash_id);

    QString xpubHashId() const { return m_xpub_hash_id; }
    void setXPubHashId(const QString& xpub_hash_id);

public slots:
    void disconnect();
    void reload(bool refresh_accounts = false);

    bool rename(QString name, bool active_focus);
signals:
    void contextChanged();
    void isPersistedChanged();
    void nameChanged();
    void xpubHashIdChanged();
    void incognitoChanged();
    void loginChanged();
public:
    bool m_is_persisted{false};
    QString m_deployment;
    QString m_id;
    QString m_name;
    LoginData* m_login{nullptr};

    QString m_xpub_hash_id;
    QSet<QString> m_hashes;
    bool m_busy{false};

    void save();
private:
    Context* m_context{nullptr};
};

#endif // GREEN_WALLET_H
