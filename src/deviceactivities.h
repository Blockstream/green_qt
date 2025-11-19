#ifndef GREEN_DEVICEACTIVITIES_H
#define GREEN_DEVICEACTIVITIES_H

#include "activity.h"

#include <QByteArray>
#include <QList>
#include <QVector>

class Device;
class Network;

class GetWalletPublicKeyActivity : public Activity
{
public:
    GetWalletPublicKeyActivity(Network* network, const QVector<uint32_t>& path, Device* device);
    Device* device() const { return m_device; }
    Network* network() const { return m_network; }
    QVector<uint32_t> path() const { return m_path; }
    QByteArray publicKey() const { return m_public_key; }
    void setPublicKey(const QByteArray& public_key);
    void exec() override;
    virtual void fetch() = 0;
protected:
    Device* const m_device;
    Network* const m_network;
    const QVector<uint32_t> m_path;
    QByteArray m_public_key;
};

class SignMessageActivity : public Activity
{
public:
    SignMessageActivity(QObject* parent) : Activity(parent) {}
    virtual QByteArray signature() const = 0;
    virtual QByteArray signerCommitment() const { return {}; }
};

class SignTransactionActivity : public Activity
{
public:
    SignTransactionActivity(QObject* parent) : Activity(parent) {}
    virtual QList<QByteArray> signatures() const = 0;
    virtual QList<QByteArray> signerCommitments() const = 0;
};

class GetBlindingKeyActivity : public Activity
{
public:
    GetBlindingKeyActivity(QObject* parent) : Activity(parent) {}
    virtual QByteArray publicKey() const = 0;
};

class GetBlindingNonceActivity : public Activity
{
public:
    GetBlindingNonceActivity(QObject* parent) : Activity(parent) {}
    virtual QByteArray nonce() const = 0;
};

class SignLiquidTransactionActivity : public Activity
{
public:
    SignLiquidTransactionActivity(QObject* parent) : Activity(parent) {}
    virtual QList<QByteArray> signatures() const = 0;
    virtual QList<QByteArray> signerCommitments() const = 0;
};

class GetMasterBlindingKeyActivity : public Activity
{
    Q_OBJECT
public:
    GetMasterBlindingKeyActivity(QObject* parent) : Activity(parent) {}
    virtual QByteArray masterBlindingKey() const = 0;
};

class GetBlindingFactorsActivity : public Activity
{
public:
    GetBlindingFactorsActivity(QObject* parent) : Activity(parent) {}
    virtual QList<QByteArray> assetBlinders() const = 0;
    virtual QList<QByteArray> amountBlinders() const = 0;
};

class LogoutActivity : public Activity
{
public:
    LogoutActivity(QObject* parent) : Activity(parent) {}
};

#endif // GREEN_DEVICEACTIVITIES_H
