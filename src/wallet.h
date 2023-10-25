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

class Wallet : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(bool persisted READ isPersisted NOTIFY isPersistedChanged)
    Q_PROPERTY(bool hasPinData READ hasPinData NOTIFY hasPinDataChanged)
    Q_PROPERTY(int loginAttemptsRemaining READ loginAttemptsRemaining NOTIFY loginAttemptsRemainingChanged)
    Q_PROPERTY(bool watchOnly READ isWatchOnly CONSTANT)
    Q_PROPERTY(QString username READ username NOTIFY usernameChanged)
    Q_PROPERTY(Network* network READ network CONSTANT)
    Q_PROPERTY(Context* context READ context NOTIFY contextChanged)
    Q_PROPERTY(QJsonObject deviceDetails READ deviceDetails NOTIFY deviceDetailsChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    explicit Wallet(QObject *parent = nullptr);
    explicit Wallet(Network* network, const QString& hash_id, QObject *parent = nullptr);
    virtual ~Wallet();

    Context* context() const { return m_context; }
    void setContext(Context* context);

    Session* session() const;
    QString id() const;
    bool isPersisted() const { return m_is_persisted; }
    Network* network() const { return m_network; }
    QString name() const { return m_name; }
    void setName(const QString& name);
    QJsonObject pinData() const;

    int loginAttemptsRemaining() const { return m_login_attempts_remaining; }

    Q_INVOKABLE QJsonObject convert(const QJsonObject& value) const;

    qint64 amountToSats(const QString& amount) const;
    Q_INVOKABLE qint64 parseAmount(const QString& amount, const QString& unit) const;

    QString formatAmount(qint64 amount, bool include_ticker) const;
    Q_INVOKABLE QString formatAmount(qint64 amount, bool include_ticker, const QString& unit) const;

    QJsonObject deviceDetails() const { return m_device_details; }
    void updateDeviceDetails(const QJsonObject& device_details);

    void updateHashId(const QString& hash_id);

    Q_INVOKABLE QString getDisplayUnit(const QString& unit);

    void resetLoginAttempts();
    void decrementLoginAttempts();
    void updateDisplayUnit();
    QString username() const { return m_username; }
public slots:
    void disconnect();
    void reload(bool refresh_accounts = false);

    bool rename(QString name, bool active_focus);
signals:
    void contextChanged();
    void isPersistedChanged(bool is_persisted);
    void sessionChanged(Session* session);
    void hasPinDataChanged();
    void nameChanged(QString name);
    void loginAttemptsRemainingChanged();
    void pinSet();
    void emptyChanged(bool empty);
    void blockHeightChanged(int block_height);
    void deviceChanged(Device* device);
    void deviceDetailsChanged();
    void usernameChanged();
public:
    bool m_is_persisted{false};
    QString m_id;

    QByteArray m_pin_data;
    QString m_name;
    QString m_username;
    QJsonObject m_device_details;
    Network* const m_network{nullptr};
    QString m_xpub_hash_id;
    QString m_hash_id;
    int m_login_attempts_remaining{3};
    bool m_busy{false};

    void save();
    bool hasPinData() const { return !m_pin_data.isEmpty(); }
    void clearPinData();

    bool m_watch_only{false};
    bool isWatchOnly() const { return m_watch_only; }

    void setPinData(const QByteArray &pin_data);
private:
    Context* m_context{nullptr};
};

#endif // GREEN_WALLET_H
