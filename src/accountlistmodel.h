#ifndef GREEN_ACCOUNTLISTMODEL_H
#define GREEN_ACCOUNTLISTMODEL_H

#include <QSet>
#include <QSortFilterProxyModel>
#include <QStandardItemModel>
#include <QtQml>

QT_FORWARD_DECLARE_CLASS(Account)
QT_FORWARD_DECLARE_CLASS(Wallet)

class AccountListModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    QML_ELEMENT
public:
    explicit AccountListModel(QObject* parent = nullptr);

    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    QString filter() const { return m_filter; }
    void setFilter(const QString& filter);
private:
    void update();
signals:
    void walletChanged(Wallet* wallet);
    void filterChanged(const QString& filter);
private:
    Wallet* m_wallet{nullptr};
    QStandardItemModel* m_model{nullptr};
    QMap<Account*, QStandardItem*> m_items;
    QString m_filter;
};

#endif // GREEN_ACCOUNTLISTMODEL_H
