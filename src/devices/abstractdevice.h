#ifndef GREEN_ABSTRACTDEVICE_H
#define GREEN_ABSTRACTDEVICE_H

#include <QObject>

class Command : public QObject
{
    Q_OBJECT
public:
};

class AbstractDevice : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString vendorName READ vendorName NOTIFY updated)
    Q_PROPERTY(QString productName READ productName NOTIFY updated)

public:
    explicit AbstractDevice(QObject *parent = nullptr);

    QString vendorName() const;
    QString productName() const;

    virtual void run(Command* command) = 0;

signals:
    void updated();

public slots:

protected:
    void setVendorName(const QString& vendor_name);
    void setProductName(const QString& product_name);

private:
    QString m_vendor_name;
    QString m_product_name;
};

#endif // GREEN_ABSTRACTDEVICE_H
