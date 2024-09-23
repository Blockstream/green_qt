#ifndef GREEN_JADEVERIFYADDRESSCONTROLLER_H
#define GREEN_JADEVERIFYADDRESSCONTROLLER_H

#include "controller.h"

#include <QJsonObject>
#include <QObject>
#include <QtQml>

Q_MOC_INCLUDE("address.h")

class JadeVerifyAddressController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Address* address READ address WRITE setAddress NOTIFY addressChanged)
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

    explicit JadeVerifyAddressController(QObject* parent = nullptr);
    virtual ~JadeVerifyAddressController();
    Address* address() const { return m_address; }
    void setAddress(Address* address);
    AddressVerification addressVerification() const { return m_address_verification; }
    void setAddressVerification(AddressVerification address_verification);
public slots:
    void verify();
signals:
    void addressChanged();
    void addressVerificationChanged();
private:
    void verifyMultisig();
    void verifySinglesig();
public:
    Address* m_address{nullptr};
    AddressVerification m_address_verification{VerificationNone};
};

#endif // GREEN_JADEVERIFYADDRESSCONTROLLER_H
