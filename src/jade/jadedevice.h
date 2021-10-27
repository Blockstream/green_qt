#ifndef GREEN_JADEDEVICE_H
#define GREEN_JADEDEVICE_H

#include <QObject>
#include <QVariant>

#include "device.h"

QT_FORWARD_DECLARE_CLASS (JadeAPI)

class JadeDevice : public Device
{
    Q_OBJECT
    Q_PROPERTY(bool updateRequired READ updateRequired NOTIFY versionInfoChanged)
    Q_PROPERTY(QString version READ version NOTIFY versionInfoChanged)
    Q_PROPERTY(QVariantMap versionInfo READ versionInfo NOTIFY versionInfoChanged)
    Q_PROPERTY(QString systemLocation READ systemLocation CONSTANT)
    QML_ELEMENT
public:
    JadeDevice(JadeAPI* jade, QObject* parent = nullptr);
    Vendor vendor() const override { return Device::Blockstream; }
    Transport transport() const override { return Transport::USB; }
    Type type() const override { return Type::BlockstreamJade; }
    QString name() const override { return m_name; }
    QJsonObject details() const override;
    GetWalletPublicKeyActivity* getWalletPublicKey(Network* network, const QVector<uint32_t>& path) override;
    SignMessageActivity* signMessage(const QString& message, const QVector<uint32_t>& path) override;
    SignMessageActivity* signMessage(const QString& message, const QVector<uint32_t>& path, const QByteArray& ae_host_commitment, const QByteArray& ae_host_entropy) override;
    SignTransactionActivity* signTransaction(Network* network, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& transaction_outputs, const QJsonObject& signing_transactions, const QJsonArray& signing_address_types) override;
    GetBlindingKeyActivity* getBlindingKey(const QString& script) override;
    GetBlindingNonceActivity* getBlindingNonce(const QByteArray& pubkey, const QByteArray& script) override;
    SignLiquidTransactionActivity* signLiquidTransaction(Network* network, const QJsonObject& transaction, const QJsonArray& signing_inputs, const QJsonArray& outputs) override;
    GetMasterBlindingKeyActivity* getMasterBlindingKey() override;
    JadeAPI* m_jade;
    QString m_name;
    QString m_system_location;
    void updateVersionInfo();
    void setVersionInfo(const QVariantMap& version_info);
    QVariantMap versionInfo() const;
    bool updateRequired() const;
    QString version() const;
    QString systemLocation() const { return m_system_location; }
    bool isLocked() const;
signals:
    void versionInfoChanged();
private:
    QVariantMap m_version_info;
};

#endif // GREEN_JADEDEVICE_H
