#include "account.h"
#include "address.h"
#include "resolver.h"
#include "addresslistmodel.h"
#include "handlers/getaddresseshandler.h"

AddressListModel::AddressListModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_reload_timer(new QTimer(this))
{
    m_reload_timer->setSingleShot(true);
    m_reload_timer->setInterval(200);
    connect(m_reload_timer, &QTimer::timeout, [this] {
        m_has_unconfirmed = false;
        fetch(true);
    });
}

AddressListModel::~AddressListModel()
{

}

void AddressListModel::setAccount(Account* account)
{
    if (m_account) {
        beginResetModel();
        m_handler = nullptr;
        m_addresses.clear();
        m_account = nullptr;
        emit accountChanged(nullptr);
        endResetModel();
    }
    if (!account) return;
    m_account = account;
    emit accountChanged(account);
    if (m_account) {
        fetchMore(QModelIndex());
    }
}

void AddressListModel::fetch(bool reset)
{
    auto handler = new GetAddressesHandler(m_last_pointer, m_account);

    QObject::connect(handler, &Handler::done, this, [this, reset, handler] {
        handler->deleteLater();
        m_handler = nullptr;
        m_last_pointer = handler->lastPointer();
        emit fetchingChanged(false);
        // instantiate missing transactions
        QVector<Address*> addresses;
        for (QJsonValue data : handler->addresses()) {
            auto address = m_account->getOrCreateAddress(data.toObject());
            addresses.append(address);
        }
        if (reset) {
            // just swap rows instead of incremental update
            // this happens after a bump fee for instance
            beginResetModel();
            m_addresses = addresses;
            endResetModel();
        } else if (addresses.size() > 0) {
            // new page of transactions, just append to existing transaction
            beginInsertRows(QModelIndex(), m_addresses.size(), m_addresses.size() + addresses.size() - 1);
            m_addresses.append(addresses);
            endInsertRows();
        }
    });

    connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });

    handler->exec();
    m_handler = handler;
    emit fetchingChanged(true);
}

QHash<int, QByteArray> AddressListModel::roleNames() const
{
    return {
        { AddressRole, "address" },
        { PointerRole, "last_pointer" },
        { AddressStringRole, "address_string" },
        { CountRole, "tx_count" }
    };
}

bool AddressListModel::canFetchMore(const QModelIndex& parent) const
{
    Q_ASSERT(!parent.parent().isValid());
    // Prevent concurrent fetchMore
    if (m_handler) return false;
    return m_last_pointer != 1;
}

void AddressListModel::fetchMore(const QModelIndex& parent)
{
    Q_ASSERT(!parent.parent().isValid());
    if (!m_account) return;
    if (m_handler) return;
    fetch(false);
}

int AddressListModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_addresses.size();
}

int AddressListModel::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return 1;
}

QVariant AddressListModel::data(const QModelIndex& index, int role) const
{
    switch (role)
    {
        case AddressRole:
            return QVariant::fromValue(m_addresses.at(index.row()));
        case PointerRole:
            return QVariant::fromValue(m_addresses.at(index.row())->data()["last_pointer"].toVariant());
        case AddressStringRole:
            return QVariant::fromValue(m_addresses.at(index.row())->data()["address"].toVariant());
        case CountRole:
            return QVariant::fromValue(m_addresses.at(index.row())->data()["tx_count"].toVariant());
    }

    return QVariant();
}

void AddressListModel::reload()
{
    if (!m_account) return;
    m_reload_timer->start();
}
