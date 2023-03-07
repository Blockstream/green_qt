#ifndef GREEN_CONTEXT_H
#define GREEN_CONTEXT_H

#include "green.h"

#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>

Q_MOC_INCLUDE("network.h")
Q_MOC_INCLUDE("device.h")
Q_MOC_INCLUDE("session.h")
Q_MOC_INCLUDE("wallet.h")

class Context : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    Q_PROPERTY(Network* network READ network NOTIFY networkChanged)
    Q_PROPERTY(Session* session READ session NOTIFY sessionChanged)
    Q_PROPERTY(Device* device READ device NOTIFY deviceChanged)
    Q_PROPERTY(bool locked READ isLocked NOTIFY lockedChanged)
    Q_PROPERTY(QJsonObject settings READ settings NOTIFY settingsChanged)
    Q_PROPERTY(QString unit READ unit NOTIFY unitChanged)
    Q_PROPERTY(QString displayUnit READ displayUnit NOTIFY unitChanged)
    Q_PROPERTY(QJsonObject config READ config NOTIFY configChanged)
    Q_PROPERTY(QJsonObject currencies READ currencies NOTIFY currenciesChanged)
    Q_PROPERTY(QJsonObject events READ events NOTIFY eventsChanged)
    Q_PROPERTY(QString username READ username NOTIFY usernameChanged)
    Q_PROPERTY(bool watchonly READ isWatchonly NOTIFY watchonlyChanged)
    Q_PROPERTY(QQmlListProperty<Account> accounts READ accounts NOTIFY accountsChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic NOTIFY mnemonicChanged)
    Q_PROPERTY(bool hasBalance READ hasBalance NOTIFY hasBalanceChanged)

    QML_ELEMENT

public:
    Context(QObject* parent = nullptr);

    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);

    Network* network() const { return m_network; }
    void setNetwork(Network* network);

    Session* session() const { return m_session; }

    Device* device() const { return m_device; }
    void setDevice(Device* device);

    QJsonObject credentials() const { return m_credentials; }
    void setCredentials(const QJsonObject& credentials);

    QStringList mnemonic() const { return m_mnemonic; }
    void setMnemonic(const QStringList& mnemonic);

    bool isLocked() const { return m_locked; }
    void setLocked(bool locked);

    QJsonObject settings() const { return m_settings; }
    void setSettings(const QJsonObject& settings);

    QString unit() const { return m_unit; }
    void setUnit(const QString& unit);
    QString displayUnit() const { return m_display_unit; }

    void setAltimeout(int altimeout);

    QJsonObject config() const { return m_config; }
    void setConfig(const QJsonObject& config);

    QJsonObject currencies() const { return m_currencies; }
    void setCurrencies(const QJsonObject& currencies);

    QJsonObject events() const { return m_events; }
    void setEvents(const QJsonObject& events);

    QString username() const { return m_username; }
    void setUsername(const QString& username);

    bool isWatchonly() const { return m_watchonly; }
    void setWatchonly(bool watchonly);

    bool hasBalance() const;

    QQmlListProperty<Account> accounts();

    Q_INVOKABLE Asset* getOrCreateAsset(const QString& id);
    Account* getOrCreateAccount(const QJsonObject& data);
    Account* getAccountByPointer(int pointer) const;

    QString m_wallet_hash_id;
    QString m_xpub_hash_id;
    QJsonObject m_pin_data;

signals:
    void walletChanged();
    void networkChanged();
    void deviceChanged();
    void credentialsChanged();
    void mnemonicChanged();
    void sessionChanged();
    void lockedChanged();
    void settingsChanged();
    void unitChanged();
    void configChanged();
    void currenciesChanged();
    void eventsChanged();
    void accountsChanged();
    void usernameChanged();
    void watchonlyChanged();
    void hasBalanceChanged();

protected:
    bool eventFilter(QObject* object, QEvent* event) override;
    void timerEvent(QTimerEvent* event) override;

private:
    Wallet* m_wallet{nullptr};
    Network* m_network{nullptr};
    Device* m_device{nullptr};
    QJsonObject m_credentials;
    QStringList m_mnemonic;
    Session* m_session{nullptr};
    bool m_locked{false};
    int m_logout_timer{-1};
    QJsonObject m_settings;
    QString m_unit;
    QString m_display_unit;
    QJsonObject m_config;
    QJsonObject m_currencies;
    QJsonObject m_events;
    int m_altimeout{0};
    QString m_username;
    bool m_watchonly{false};

public:
    QMap<QString, Asset*> m_assets;
    QList<Account*> m_accounts;
    QMap<int, Account*> m_accounts_by_pointer;
};

#endif // GREEN_CONTEXT_H
