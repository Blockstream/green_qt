#include "outputlistmodel.h"

#include <QDebug>

#include "account.h"
#include "handlers/getunspentoutputshandler.h"
#include "output.h"
#include "resolver.h"

OutputListModel::OutputListModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

OutputListModel::~OutputListModel()
{
}

void OutputListModel::setAccount(Account *account)
{
    if (!m_account.update(account)) return;
    beginResetModel();
    m_get_outputs_activity.update(nullptr);
    m_outputs.clear();
    endResetModel();
    emit accountChanged(m_account);
    fetch();
    if (m_account) {
        m_account.track(QObject::connect(m_account, &Account::notificationHandled, this, [this](const QJsonObject& notification) {
            const auto event = notification.value("event").toString();
            if (event == "transaction") {
                // In Wallet::handleNotification transaction notifications are only
                // forward to relevant accounts meaning that it's fine to always
                // update there.
                fetch();
            } else if (event == "block") {
                bool has_unconfirmed = false;
                for (auto& output : m_outputs) {
                    if (output->unconfirmed()) {
                        has_unconfirmed = true;
                        break;
                    }
                }
                if (has_unconfirmed) {
                    // Need to fetch coins since unconfirmed coins can now be included in the block.
                    fetch();
                } else {
                    // Just update existing coins.
                    update();
                }
            }
        }));
    }
}

void OutputListModel::fetch()
{
    if (!m_account) return;
    if (m_fetching) return;

    auto handler = new GetUnspentOutputsHandler(0, true, m_account);

    QObject::connect(handler, &Handler::done, this, [=] {
        handler->deleteLater();
        beginResetModel();
        m_outputs.clear();
        for (const QJsonValue& assets_values : handler->unspentOutputs()) {
            for (const QJsonValue& asset_value : assets_values.toArray()) {
                auto output = account()->getOrCreateOutput(asset_value.toObject());
                m_outputs.append(output);
            }
        }
        endResetModel();
        m_fetching = false;
        emit fetchingChanged();
    });

    connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });

    handler->exec();

    m_fetching = true;
    emit fetchingChanged();
}

void OutputListModel::update()
{
    for (auto& output : m_outputs) {
        output->update();
    }
}

QHash<int, QByteArray> OutputListModel::roleNames() const
{
    return {
        { Qt::UserRole, "output" }
    };
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

int OutputListModel::indexOf(Output *output) const
{
    return m_outputs.indexOf(output);
}
