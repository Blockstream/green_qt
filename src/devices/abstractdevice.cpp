#include "abstractdevice.h"

AbstractDevice::AbstractDevice(QObject *parent) : QObject(parent)
{

}

QString AbstractDevice::vendorName() const
{
    return m_vendor_name;
}

void AbstractDevice::setVendorName(const QString &vendor_name)
{
    if (vendor_name == m_vendor_name) return;
    m_vendor_name = vendor_name;
    emit updated();
}

QString AbstractDevice::productName() const
{
    return m_product_name;
}

void AbstractDevice::setProductName(const QString &product_name)
{
    if (product_name == m_product_name) return;
    m_product_name = product_name;
    emit updated();
}
