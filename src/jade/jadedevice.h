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
    Q_PROPERTY(bool secureBoot READ secureBoot NOTIFY versionInfoChanged)
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool unlocking READ unlocking NOTIFY unlockingChanged)
    Q_PROPERTY(bool usbAvailable READ usbAvailable NOTIFY backendsChanged)
    Q_PROPERTY(bool bluetoothAvailable READ bluetoothAvailable NOTIFY backendsChanged)
    Q_PROPERTY(ConnectionType connectionType READ connectionType NOTIFY connectionTypeChanged)
    Q_PROPERTY(bool connectionSelected READ connectionSelected NOTIFY connectionSelectedChanged)
    Q_PROPERTY(BluetoothState bluetoothState READ bluetoothState NOTIFY bluetoothStateChanged)
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
    enum ConnectionType {
        NoConnection,
        USB,
        Bluetooth,
    };
    Q_ENUM(ConnectionType)
    // What Bluetooth discovery knows about the device while it is not connected.
    enum BluetoothState {
        BluetoothNone,
        BluetoothUnpaired,
        BluetoothPairing,
        BluetoothPaired,
    };
    Q_ENUM(BluetoothState)

    JadeDevice(QObject* parent = nullptr);
    static QString nameForEfusemac(const QString& efusemac);
    Vendor vendor() const override { return Device::Blockstream; }
    Type type() const override { return Type::BlockstreamJade; }
    QString name() const override { return m_name; }
    void setName(const QString& name);
    BluetoothState bluetoothState() const { return m_bluetooth_state; }
    void setBluetoothState(BluetoothState state);
    Q_INVOKABLE void pairBluetooth() { emit bluetoothPairRequested(); }
    JadeAPI *api() const { return m_api; }
    JadeAPI* usbApi() const { return m_usb_api; }
    JadeAPI* bluetoothApi() const { return m_bluetooth_api; }
    void setUsbBackend(JadeAPI* api);
    void setBluetoothBackend(JadeAPI* api);
    bool usbAvailable() const { return m_usb_api; }
    bool bluetoothAvailable() const { return m_bluetooth_api; }
    ConnectionType connectionType() const;
    bool connectionSelected() const { return m_connection_selected; }
    Q_INVOKABLE void selectConnection(ConnectionType type);
    QJsonObject details() const override;
    DeviceGetWalletPublicKeyTask* getWalletPublicKey(Network* network, const QVector<uint32_t>& path) override;
    DeviceSignMessageTask* signMessage(const QString& message, const QVector<uint32_t>& path) override;
    DeviceSignMessageTask* signMessage(const QString& message, const QVector<uint32_t>& path, const QByteArray& ae_host_commitment, const QByteArray& ae_host_entropy) override;
    DeviceSignTransactionTask* signTransaction(Network* network, const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions) override;
    DeviceGetBlindingKeyTask* getBlindingKey(const QString& script) override;
    DeviceGetBlindingNonceTask* getBlindingNonce(const QByteArray& pubkey, const QByteArray& script) override;
    DeviceSignLiquidTransactionTask* signLiquidTransaction(Network* network, const QByteArray& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs, const QList<Asset*>& assets) override;
    DeviceGetMasterBlindingKeyTask* getMasterBlindingKey() override;
    DeviceGetBlindingFactorsTask* getBlindingFactors(const QJsonArray& inputs, const QJsonArray& outputs) override;
    DeviceLogoutTask* logout() override;
    void updateVersionInfo();
    void setVersionInfo(const QVariantMap& version_info);
    QVariantMap versionInfo() const;
    QVersionNumber minimumRequiredVersion() const;
    bool updateRequired() const;
    bool secureBoot() const;
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
    void backendsChanged();
    void connectionTypeChanged();
    void connectionSelectedChanged();
    void bluetoothStateChanged();
    void bluetoothPairRequested();
private:
    void setBackend(JadeAPI* api);
    void updateBackend();
    void setConnectionSelected(bool connection_selected);
private:
    JadeAPI* m_api{nullptr};
    JadeAPI* m_usb_api{nullptr};
    JadeAPI* m_bluetooth_api{nullptr};
    bool m_connection_selected{false};
    Status m_status{StatusIdle};
    QString m_system_location;
    QVariantMap m_version_info;
    QString m_name;
    bool m_unlocking{false};
    JadeDevice::State m_state{StateLocked};
    BluetoothState m_bluetooth_state{BluetoothNone};
};

class JadeGetMasterBlindingKeyTask : public DeviceGetMasterBlindingKeyTask
{
    Q_OBJECT
    Q_PROPERTY(bool ask READ ask NOTIFY askChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeGetMasterBlindingKeyTask(JadeDevice* device);
    QByteArray masterBlindingKey() const override { return m_master_blinding_key; }
    void update() override;
    bool ask() const { return m_ask; }
public slots:
    void confirm();
signals:
    void askChanged();
private:
    void request();
private:
    JadeDevice* const m_device;
    QByteArray m_master_blinding_key;
    bool m_only_if_silent{true};
    bool m_ask{false};
};

#endif // GREEN_JADEDEVICE_H
