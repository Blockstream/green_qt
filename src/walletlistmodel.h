#ifndef GREEN_WALLETLISTMODEL_H
#define GREEN_WALLETLISTMODEL_H

#include <QtQml>
#include <QMap>
#include <QSortFilterProxyModel>
#include <QStandardItem>
#include <QStandardItemModel>

class Wallet;

class WalletListModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(bool justAuthenticated READ justAuthenticated WRITE setJustAuthenticated NOTIFY justAuthenticatedChanged)
    QML_ELEMENT
public:
    WalletListModel(QObject* parent = nullptr);
    Q_INVOKABLE int indexOf(Wallet* wallet) const;
    QString network() const { return m_network; }
    void setNetwork(const QString& network);
    bool justAuthenticated() const { return m_just_authenticated; }
    void setJustAuthenticated(bool just_authenticated);
signals:
    void networkChanged(const QString& network);
    void justAuthenticatedChanged(bool just_authenticated);
private slots:
    void update();
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const override;
    bool lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const override;
private:
    QStandardItemModel m_source_model;
    QMap<Wallet*, QStandardItem*> m_items;
    QString m_network;
    bool m_just_authenticated{false};
};

#endif // GREEN_WALLETLISTMODEL_H
