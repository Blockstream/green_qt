#ifndef GREEN_DEVICE_H
#define GREEN_DEVICE_H

#include <QObject>
#include <QVariantMap>

class Device : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString vendorName READ vendorName CONSTANT)
    Q_PROPERTY(QString productName READ productName CONSTANT)
    Q_PROPERTY(QVariantMap properties READ properties NOTIFY propertiesChanged)

public:
    explicit Device(const QString& id, QObject *parent = nullptr);

    QString id() const;
    QString vendorName() const;
    QString productName() const;
    QVariantMap properties() const;

signals:
    void vendorNameChanged(const QString& vendor_name);
    void productNameChanged(const QString& product_name);
    void propertiesChanged();

protected:
    void setVendorName(const QString& vendor_name);
    void setProductName(const QString& product_name);

private:
    const QString m_id;
    QString m_vendor_name;
    QString m_product_name;
    QVariantMap m_properties;
};

#endif // GREEN_DEVICE_H
