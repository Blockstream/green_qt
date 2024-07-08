#ifndef GREEN_RECEIVEADDRESSCONTROLLER_H
#define GREEN_RECEIVEADDRESSCONTROLLER_H

#include "controller.h"

#include <QJsonObject>
#include <QObject>
#include <QtQml>

Q_MOC_INCLUDE("address.h")
Q_MOC_INCLUDE("convert.h")

class Convert;
class ReceiveAddressController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(Asset* asset READ asset WRITE setAsset NOTIFY assetChanged)
    Q_PROPERTY(Convert* convert READ convert CONSTANT)
    Q_PROPERTY(Address* address READ address NOTIFY changed)
    Q_PROPERTY(QJsonObject result READ result NOTIFY changed)
    Q_PROPERTY(QString uri READ uri NOTIFY changed)
    Q_PROPERTY(bool generating READ generating NOTIFY generatingChanged)
    Q_PROPERTY(AddressVerification addressVerification READ addressVerification NOTIFY addressVerificationChanged)
    QML_ELEMENT
public:
    enum AddressVerification {
        VerificationNone,
        VerificationPending,
        VerificationAccepted,
        VerificationRejected,
    };
    Q_ENUM(AddressVerification)

    explicit ReceiveAddressController(QObject* parent = nullptr);
    virtual ~ReceiveAddressController();
    Account* account() const;
    void setAccount(Account* account);
    Asset* asset() const { return m_asset; }
    void setAsset(Asset* asset);
    Convert* convert() const { return m_convert; }
    Address* address() const;
    QJsonObject result() const { return m_result; }
    QString uri() const;
    bool generating() const;
    void setGenerating(bool generating);
    AddressVerification addressVerification() const { return m_address_verification; }
    void setAddressVerification(AddressVerification address_verification);
public slots:
    void generate();
    void verify();
signals:
    void accountChanged();
    void assetChanged();
    void changed();
    void generatingChanged(bool generating);
    void addressVerificationChanged(AddressVerification address_verification);
private:
    void verifyMultisig();
    void verifySinglesig();
public:
    Account* m_account{nullptr};
    Asset* m_asset{nullptr};
    Convert* const m_convert;
    QString m_address;
    QJsonObject m_result;
    bool m_generating{false};
    AddressVerification m_address_verification{VerificationNone};
};

#endif // GREEN_RECEIVEADDRESSCONTROLLER_H
