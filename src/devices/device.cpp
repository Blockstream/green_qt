#include "device.h"

Device::Device(const QString& id, QObject *parent)
    : QObject(parent)
    , m_id(id)
{

}

QString Device::id() const
{
    return m_id;
}

QString Device::vendorName() const
{
    return m_vendor_name;
}

void Device::setVendorName(const QString &vendor_name)
{
    if (vendor_name == m_vendor_name) return;
    m_vendor_name = vendor_name;
    emit vendorNameChanged(m_vendor_name);
}

QString Device::productName() const
{
    return m_product_name;
}

void Device::setProductName(const QString &product_name)
{
    if (product_name == m_product_name) return;
    m_product_name = product_name;
    emit productNameChanged(m_product_name);
}

QVariantMap Device::properties() const
{
    return m_properties;
}
