#ifndef GREEN_ADDRESSLISTMODEL_H
#define GREEN_ADDRESSLISTMODEL_H

#include <QAbstractListModel>
#include <QtQml>

class Account;
class Address;
class Handler;

class AddressListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(bool fetching READ fetching NOTIFY fetchingChanged)
    QML_ELEMENT
public:
    enum AddressRoles {
        AddressRole = Qt::UserRole,
        PointerRole = Qt::UserRole + 1,
        AddressStringRole,
        CountRole
    };

    AddressListModel(QObject* parent = nullptr);
    ~AddressListModel();

    Account* account() const { return m_account; }
    void setAccount(Account* account);
    bool fetching() const { return m_fetching; }

    QHash<int,QByteArray> roleNames() const override;
    void fetchMore(const QModelIndex& parent) override;
    bool canFetchMore(const QModelIndex& parent) const override;
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    int columnCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
public slots:
    void reload();
signals:
    void accountChanged();
    void fetchingChanged();
private:
    void fetch(bool reset);
private:
    Account* m_account{nullptr};
    QVector<Address*> m_addresses;
    bool m_has_unconfirmed{false};
    Handler* m_handler{nullptr};
    QTimer* const m_reload_timer;
    bool m_fetching{false};
    int m_last_pointer{0};
};

#endif // ADDRESSLISTMODEL_H
