#ifndef GREEN_WALLETLISTMODEL_H
#define GREEN_WALLETLISTMODEL_H

#include <QMap>
#include <QSortFilterProxyModel>
#include <QStandardItem>
#include <QStandardItemModel>

class Wallet;

class WalletListModel : public QSortFilterProxyModel
{
public:
    WalletListModel(QObject* parent = nullptr);
private slots:
    void update();
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const override;
    bool lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const override;
private:
    QStandardItemModel m_source_model;
    QMap<Wallet*, QStandardItem*> m_items;
};

#endif // GREEN_WALLETLISTMODEL_H
