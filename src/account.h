#ifndef GREEN_ACCOUNT_H
#define GREEN_ACCOUNT_H

#include "green.h"

#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>

Q_MOC_INCLUDE("address.h")
Q_MOC_INCLUDE("context.h")
Q_MOC_INCLUDE("network.h")
Q_MOC_INCLUDE("session.h")
Q_MOC_INCLUDE("transaction.h")
Q_MOC_INCLUDE("wallet.h")

class Account : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context CONSTANT)
    Q_PROPERTY(Network* network READ network CONSTANT)
    Q_PROPERTY(Session* session READ session CONSTANT)
    Q_PROPERTY(int pointer READ pointer CONSTANT)
    Q_PROPERTY(QString type READ type NOTIFY typeChanged)
    Q_PROPERTY(bool synced READ synced NOTIFY syncedChanged)
    Q_PROPERTY(bool mainAccount READ isMainAccount CONSTANT)
    Q_PROPERTY(QJsonObject json READ json NOTIFY jsonChanged)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(bool hidden READ isHidden NOTIFY hiddenChanged)
    Q_PROPERTY(qint64 balance READ balance NOTIFY balanceChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    explicit Account(Network* network, int pointer, Context* context);

    Context* context() const { return m_context; }
    Session* session() const;
    Network* network() const { return m_network; }
    quint32 pointer() const { return m_pointer; }
    QString type() const { return m_type; }
    void setType(const QString& type);
    bool synced() const { return m_synced; }
    void setSynced(bool synced);
    bool isMainAccount() const;

    bool isBitcoin() const;
    bool isLiquid() const;
    bool isLightning() const;
    bool isSinglesig() const;
    bool isMultisig() const;
    bool isAmp() const;

    QString name() const { return m_name; }
    void setName(const QString& name);
    bool isHidden() const { return m_hidden; }
    void setHidden(bool hidden);
    QJsonObject json() const;

    void update(QJsonObject json);

    void loadBalance();

    qint64 balance() const;

    bool isEmpty() const;
    void setBalanceData(const QJsonObject& data);
    void updateBalance();
    Transaction* getTransaction(const QString& hash);
    Transaction* getOrCreateTransaction(const QJsonObject& data);
    Output *getOrCreateOutput(const QJsonObject &data);
    Q_INVOKABLE Address *getOrCreateAddress(const QJsonObject &data);
    Q_INVOKABLE Transaction* getTransactionByTxHash(const QString &id) const;
protected:
    void timerEvent(QTimerEvent* event) override;
signals:
    void typeChanged();
    void syncedChanged();
    void blockEvent(const QJsonObject& event);
    void transactionEvent(const QJsonObject& event);
    void jsonChanged();
    void nameChanged();
    void hiddenChanged();
    void balanceChanged();
    void addressGenerated();
private:
    Context* const m_context;
    Network* const m_network;
    const quint32 m_pointer;
    QString m_type;
    bool m_synced{false};
    QJsonObject m_json;
    QString m_name;
    bool m_hidden{false};
    QMap<QString, Transaction*> m_transactions_by_hash;
    QMap<QPair<QString, int>, Output*> m_outputs_by_hash;
    QMap<QString, Address*> m_address_by_hash;
    int m_load_balance_timer_id{-1};
    friend class Wallet;
};

#endif // GREEN_ACCOUNT_H
