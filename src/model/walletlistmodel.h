#ifndef GREEN_WALLETLISTMODEL_H
#define GREEN_WALLETLISTMODEL_H

#include <QMap>
#include <QSortFilterProxyModel>
#include <QStandardItem>
#include <QStandardItemModel>
#include <QtQml>

class Wallet;

class WalletListModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(Filter watchOnly READ watchOnly WRITE setWatchOnly NOTIFY watchOnlyChanged)
    Q_PROPERTY(Filter pinData READ filterPinData WRITE setFilterPinData NOTIFY filterPinDataChanged)
    Q_PROPERTY(Filter deviceDetails READ filterDeviceDetails WRITE setFilterDeviceDetails NOTIFY filterDeviceDetailsChanged)
    QML_ELEMENT
public:
    enum class Filter {
        Any,
        Yes,
        No,
    };
    Q_ENUM(Filter)

    WalletListModel(QObject* parent = nullptr);
    Q_INVOKABLE int indexOf(Wallet* wallet) const;
    Filter watchOnly() const { return m_watch_only; }
    void setWatchOnly(Filter watch_only);
    Filter filterPinData() const { return m_filter_pin_data; }
    void setFilterPinData(Filter filter_pin_data);
    Filter filterDeviceDetails() const { return m_filter_device_details; }
    void setFilterDeviceDetails(Filter filter_device_details);
signals:
    void watchOnlyChanged(Filter watch_only);
    void filterPinDataChanged();
    void filterDeviceDetailsChanged();
private slots:
    void update();
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const override;
    bool lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const override;
private:
    QStandardItemModel m_source_model;
    QMap<Wallet*, QStandardItem*> m_items;
    Filter m_watch_only{Filter::Any};
    Filter m_filter_pin_data{Filter::Any};
    Filter m_filter_device_details{Filter::Any};
};

#endif // GREEN_WALLETLISTMODEL_H
