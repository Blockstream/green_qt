#ifndef GREEN_RECEIVEADDRESSCONTROLLER_H
#define GREEN_RECEIVEADDRESSCONTROLLER_H

#include "sessioncontroller.h"

#include <QJsonObject>
#include <QObject>
#include <QtQml>

Q_MOC_INCLUDE("address.h")
Q_MOC_INCLUDE("convert.h")

class Convert;
class ReceiveAddressController : public SessionController
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(Asset* asset READ asset WRITE setAsset NOTIFY assetChanged)
    Q_PROPERTY(Convert* convert READ convert CONSTANT)
    Q_PROPERTY(Address* address READ address NOTIFY changed)
    Q_PROPERTY(QString uri READ uri NOTIFY changed)
    Q_PROPERTY(bool generating READ generating NOTIFY generatingChanged)
    QML_ELEMENT
public:
    explicit ReceiveAddressController(QObject* parent = nullptr);
    virtual ~ReceiveAddressController();
    Account* account() const;
    void setAccount(Account* account);
    Asset* asset() const { return m_asset; }
    void setAsset(Asset* asset);
    Convert* convert() const { return m_convert; }
    Address* address() const { return m_address; }
    QString uri() const;
    bool generating() const;
    void setGenerating(bool generating);
public slots:
    void generate();
signals:
    void accountChanged();
    void assetChanged();
    void changed();
    void generatingChanged(bool generating);
private:
    Account* m_account{nullptr};
    Asset* m_asset{nullptr};
    Convert* const m_convert;
    Address* m_address{nullptr};
    bool m_generating{false};
};

#endif // GREEN_RECEIVEADDRESSCONTROLLER_H
