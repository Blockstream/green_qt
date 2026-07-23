#ifndef GREEN_DEVICETASKS_H
#define GREEN_DEVICETASKS_H

#include "task.h"

#include <QByteArray>
#include <QList>
#include <QVector>

class Device;
class Network;

class DeviceGetWalletPublicKeyTask : public Task
{
    Q_OBJECT
public:
    DeviceGetWalletPublicKeyTask(Network* network, const QVector<uint32_t>& path, Device* device);
    Device* device() const { return m_device; }
    Network* network() const { return m_network; }
    QVector<uint32_t> path() const { return m_path; }
    QByteArray publicKey() const { return m_public_key; }
    void setPublicKey(const QByteArray& public_key);
    void update() override;
    virtual void fetch() = 0;
protected:
    Device* const m_device;
    Network* const m_network;
    const QVector<uint32_t> m_path;
    QByteArray m_public_key;
};

class DeviceSignMessageTask : public Task
{
    Q_OBJECT
public:
    DeviceSignMessageTask(QObject* parent) : Task(parent) {}
    virtual QByteArray signature() const = 0;
    virtual QByteArray signerCommitment() const { return {}; }
};

class DeviceSignTransactionTask : public Task
{
    Q_OBJECT
public:
    DeviceSignTransactionTask(QObject* parent) : Task(parent) {}
    virtual QList<QByteArray> signatures() const = 0;
    virtual QList<QByteArray> signerCommitments() const = 0;
};

class DeviceGetBlindingKeyTask : public Task
{
    Q_OBJECT
public:
    DeviceGetBlindingKeyTask(QObject* parent) : Task(parent) {}
    virtual QByteArray publicKey() const = 0;
};

class DeviceGetBlindingNonceTask : public Task
{
    Q_OBJECT
public:
    DeviceGetBlindingNonceTask(QObject* parent) : Task(parent) {}
    virtual QByteArray nonce() const = 0;
};

class DeviceSignLiquidTransactionTask : public Task
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject message READ message NOTIFY messageChanged)
public:
    DeviceSignLiquidTransactionTask(QObject* parent) : Task(parent) {}
    QJsonObject message() const { return m_message; }
    void setMessage(const QJsonObject& message);
    virtual QList<QByteArray> signatures() const = 0;
    virtual QList<QByteArray> signerCommitments() const = 0;
signals:
    void messageChanged(const QJsonObject& message);
private:
    QJsonObject m_message;
};

class DeviceGetMasterBlindingKeyTask : public Task
{
    Q_OBJECT
public:
    DeviceGetMasterBlindingKeyTask(QObject* parent) : Task(parent) {}
    virtual QByteArray masterBlindingKey() const = 0;
};

class DeviceGetBlindingFactorsTask : public Task
{
    Q_OBJECT
public:
    DeviceGetBlindingFactorsTask(QObject* parent) : Task(parent) {}
    virtual QList<QByteArray> assetBlinders() const = 0;
    virtual QList<QByteArray> amountBlinders() const = 0;
};

class DeviceLogoutTask : public Task
{
    Q_OBJECT
public:
    DeviceLogoutTask(QObject* parent) : Task(parent) {}
};

#endif // GREEN_DEVICETASKS_H
