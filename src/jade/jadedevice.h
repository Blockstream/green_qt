#ifndef GREEN_JADEDEVICE_H
#define GREEN_JADEDEVICE_H

#include <QObject>
#include <QVariant>

#include "device.h"

class JadeAPI;

class JadeDevice : public Device
{
    Q_OBJECT
    Q_PROPERTY(QString systemLocation READ systemLocation NOTIFY systemLocationChanged)
    Q_PROPERTY(QVariantMap versionInfo READ versionInfo NOTIFY versionInfoChanged)
    Q_PROPERTY(QString version READ version NOTIFY versionInfoChanged)
    Q_PROPERTY(bool updateRequired READ updateRequired NOTIFY versionInfoChanged)
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool unlocking READ unlocking NOTIFY unlockingChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    enum State {
        StateReady,
        StateTemporary,
        StateUnsaved,
        StateLocked,
        StateUninitialized,
    };
    Q_ENUM(State)
    enum Status {
        StatusIdle,
        StatusHandleClientMessage,
        StatusHandleMenuNavigation,
    };
    Q_ENUM(Status)

    JadeDevice(QObject* parent = nullptr);
    Vendor vendor() const override { return Device::Blockstream; }
    Transport transport() const override { return Transport::USB; }
    Type type() const override { return Type::BlockstreamJade; }
    QString name() const override { return m_name; }
    void setName(const QString& name);
    JadeAPI *api() const { return m_api; }
    void setBackend(JadeAPI* api);
    QJsonObject details() const override;
    GetWalletPublicKeyActivity* getWalletPublicKey(Network* network, const QVector<uint32_t>& path) override;
    SignMessageActivity* signMessage(const QString& message, const QVector<uint32_t>& path) override;
    SignMessageActivity* signMessage(const QString& message, const QVector<uint32_t>& path, const QByteArray& ae_host_commitment, const QByteArray& ae_host_entropy) override;
    SignTransactionActivity* signTransaction(Network* network, const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions) override;
    GetBlindingKeyActivity* getBlindingKey(const QString& script) override;
    GetBlindingNonceActivity* getBlindingNonce(const QByteArray& pubkey, const QByteArray& script) override;
    SignLiquidTransactionActivity* signLiquidTransaction(Network* network, const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs) override;
    GetMasterBlindingKeyActivity* getMasterBlindingKey() override;
    GetBlindingFactorsActivity* getBlindingFactors(const QJsonArray& inputs, const QJsonArray& outputs) override;
    LogoutActivity* logout() override;
    void updateVersionInfo();
    void setVersionInfo(const QVariantMap& version_info);
    QVariantMap versionInfo() const;
    QVersionNumber minimumRequiredVersion() const;
    bool updateRequired() const;
    QString version() const;
    QString systemLocation() const { return m_system_location; }
    void setSystemLocation(const QString& system_location);
    State state() const { return m_state; }
    void setState(State state);
    Status status() const { return m_status; }
    void setStatus(Status status);
    bool unlocking() const { return m_unlocking; }
    void setUnlocking(bool unlocking);
    Q_INVOKABLE bool versionGreaterOrEqualThan(const QString& other);
    bool supportsNetwork(Network* network) override;
signals:
    void systemLocationChanged();
    void versionInfoChanged();
    void stateChanged();
    void statusChanged();
    void error();
    bool unlockingChanged();
private:
    JadeAPI* m_api{nullptr};
    Status m_status{StatusIdle};
    QString m_system_location;
    QVariantMap m_version_info;
    QString m_name;
    bool m_unlocking{false};
    JadeDevice::State m_state{StateLocked};
};

class JadeGetMasterBlindingKeyActivity : public GetMasterBlindingKeyActivity
{
    Q_OBJECT
    Q_PROPERTY(bool ask READ ask NOTIFY askChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeGetMasterBlindingKeyActivity(JadeDevice* device);
    QByteArray masterBlindingKey() const override { return m_master_blinding_key; }
    void exec() override;
    bool ask() const { return m_ask; }
public slots:
    void confirm();
signals:
    void askChanged();
private:
    JadeDevice* const m_device;
    QByteArray m_master_blinding_key;
    bool m_only_if_silent{true};
    bool m_ask{false};
};

#endif // GREEN_JADEDEVICE_H
