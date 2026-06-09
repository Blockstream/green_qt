#ifndef BLOCKSTREAM_CONTEXTMODEL_H
#define BLOCKSTREAM_CONTEXTMODEL_H

#include "green.h"
#include <QQmlEngine>
#include <QSortFilterProxyModel>

class ContextModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context WRITE setContext NOTIFY contextChanged)
    Q_PROPERTY(QQmlListProperty<Account> filterAccounts READ filterAccounts NOTIFY filterAccountsChanged)
    Q_PROPERTY(QQmlListProperty<Asset> filterAssets READ filterAssets NOTIFY filterAssetsChanged)
    Q_PROPERTY(QStringList filterTypes READ filterTypes NOTIFY filterTypesChanged)
    Q_PROPERTY(QStringList filterStatuses READ filterStatuses NOTIFY filterStatusesChanged)
    Q_PROPERTY(bool filterHasTransactions READ filterHasTransactions NOTIFY filterHasTransactionsChanged)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ContextModel(QObject* parent = nullptr);
    Context* context() const { return m_context; }
    void setContext(Context* context);
    QQmlListProperty<Account> filterAccounts();
    QQmlListProperty<Asset> filterAssets();
    QStringList filterTypes() const { return m_filter_types; }
    QStringList filterStatuses() const { return m_filter_statuses; }
    bool filterHasTransactions() const { return m_filter_has_transactions; }
    QString filterText() const { return m_filter_text; }
    void setFilterText(const QString& filter_text);
signals:
    void contextChanged();
    void filterAccountsChanged();
    void filterAssetsChanged();
    void filterTypesChanged();
    void filterStatusesChanged();
    void filterHasTransactionsChanged();
    void filterTextChanged();
public slots:
    void clearFilters();
    void setFilterAccount(Account* account);
    void setFilterAsset(Asset* asset);
    void updateFilterAccounts(Account* account, bool filter);
    void updateFilterAssets(Asset* asset, bool filter);
    void updateFilterTypes(const QString& type, bool filter);
    void updateFilterStatuses(const QString& status, bool filter);
    void updateFilterHasTransactions(bool has_transactions);
    virtual void exportToFile();
protected:
    virtual void update(Context* context) = 0;
protected:
    QList<Account*> m_filter_accounts;
    QList<Asset*> m_filter_assets;
    QStringList m_filter_types;
    QStringList m_filter_statuses;
    bool m_filter_has_transactions{false};
    QString m_filter_text;
private:
    Context* m_context{nullptr};
};

class TransactionModel : public ContextModel
{
    Q_OBJECT
    QML_ELEMENT
public:
    TransactionModel(QObject* parent = nullptr);
    void exportToFile() override;
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    void update(Context* context) override;
private:
    bool filterAccountsAcceptsTransaction(AccountTransaction* transaction) const;
    bool filterAssetsAcceptsTransaction(AccountTransaction* transaction) const;
    bool filterTextAcceptsTransaction(AccountTransaction* transaction) const;
    bool filterAccountsAcceptsLightningTransaction(LightningTransaction* transaction) const;
    bool filterAssetsAcceptsLightningTransaction(LightningTransaction* transaction) const;
    bool filterTextAcceptsLightningTransaction(LightningTransaction* transaction) const;
};

class AddressModel : public ContextModel
{
    Q_OBJECT
    QML_ELEMENT
public:
    AddressModel(QObject* parent = nullptr);
    void exportToFile() override;
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    void update(Context* context) override;
private:
    bool filterAccountsAcceptsAddress(Address* address) const;
    bool filterTextAcceptsAddress(Address* address) const;
    bool filterTypesAcceptsAddress(Address* address) const;
    bool filterHasTransactionAcceptsAddress(Address* address) const;
};

class CoinModel : public ContextModel
{
    Q_OBJECT
    QML_ELEMENT
public:
    CoinModel(QObject* parent = nullptr);
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    void update(Context* context) override;
private:
    bool filterAccountsAcceptsCoin(Output* coin) const;
    bool filterAssetsAcceptsCoin(Output* coin) const;
    bool filterTextAcceptsCoin(Output* coin) const;
};

class PaymentModel : public ContextModel
{
    Q_OBJECT
    QML_ELEMENT
public:
    PaymentModel(QObject* parent = nullptr);
protected:
    void update(Context* context) override;
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
private:
    bool filterStatusesAcceptsPayment(Payment* payment) const;
};

#endif // BLOCKSTREAM_CONTEXTMODEL_H
