#include "account.h"
#include "resolver.h"
#include "output.h"
#include "outputlistmodel.h"

#include <QDebug>

OutputListModel::OutputListModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_reload_timer(new QTimer(this))
{
    m_reload_timer->setSingleShot(true);
    m_reload_timer->setInterval(200);
    connect(m_reload_timer, &QTimer::timeout, [this] {
        fetch();
    });
}

OutputListModel::~OutputListModel()
{

}

void OutputListModel::setAccount(Account *account)
{
    if (m_account) {
        beginResetModel();
        m_get_outputs_activity.update(nullptr);
        m_outputs.clear();
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

void OutputListModel::fetch()
{
    m_get_outputs_activity.update(new AccountGetUnspentOutputsActivity(m_account, 0, true, this));
    m_account->wallet()->pushActivity(m_get_outputs_activity);

    m_get_outputs_activity.track(QObject::connect(m_get_outputs_activity, &Activity::finished, this, [this] {
        beginResetModel();
        m_outputs = m_get_outputs_activity->outputs();
        endResetModel();
        m_get_outputs_activity->deleteLater();
        m_get_outputs_activity.update(0);
        emit fetchingChanged();
    }));

    m_get_outputs_activity->exec();
    emit fetchingChanged();
}

QHash<int, QByteArray> OutputListModel::roleNames() const
{
    return {
        { Qt::UserRole, "output" }
    };
}

bool OutputListModel::canFetchMore(const QModelIndex &parent) const
{
    return false;
}

void OutputListModel::fetchMore(const QModelIndex &parent)
{
    Q_ASSERT(!parent.parent().isValid());
    if (!m_account) return;
    if (m_get_outputs_activity) return;
    fetch();
}

int OutputListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_outputs.size();
}

int OutputListModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return 1;
}

QVariant OutputListModel::data(const QModelIndex &index, int role) const
{
    if (role == Qt::UserRole) return QVariant::fromValue(m_outputs.at(index.row()));
    return QVariant();
}

void OutputListModel::reload()
{
    if (!m_account) return;
    m_reload_timer->start();
}

