#include "outputlistmodel.h"

#include "account.h"
#include "output.h"
#include "resolver.h"
#include "session.h"
#include "task.h"
#include "wallet.h"

OutputListModel::OutputListModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_dispatcher(new TaskDispatcher(this))
{
}

OutputListModel::~OutputListModel()
{
}

void OutputListModel::setAccount(Account* account)
{
    if (m_account == account) return;

    if (m_account) {
        beginResetModel();
        for (auto output : m_outputs) {
            disconnect(output, &Output::expiredChanged, this, nullptr);
        }
        m_outputs.clear();
        endResetModel();
    }

    m_account = account;
    emit accountChanged(m_account);

    fetch();

    if (m_account) {
        auto session = m_account->session();
        connect(session, &Session::transactionEvent, this, [this](const QJsonObject& event) {
            for (auto pointer : event.value("subaccounts").toArray()) {
                if (m_account->pointer() == pointer.toInt()) {
                    fetch();
                    return;
                }
            }
        });
        connect(session, &Session::blockEvent, this, [this](const QJsonObject& event) {
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
        });
    }
}

void OutputListModel::setAllCoins(bool all_coins)
{
    if (m_all_coins == all_coins) return;
    m_all_coins = all_coins;
    emit allCoinsChanged();
    fetch();
}

void OutputListModel::fetch()
{
    if (!m_account) return;
    if (m_fetching) return;

    auto get_unspent_outputs = new GetUnspentOutputsTask(0, m_all_coins, m_account);

    if (!m_error.isEmpty()) {
        m_error.clear();
        emit errorChanged();
    }

    connect(get_unspent_outputs, &Task::finished, this, [=, this] {
        beginResetModel();
        for (auto output : m_outputs) {
            disconnect(output, &Output::expiredChanged, this, nullptr);
        }
        m_outputs.clear();
        for (const QJsonValue& assets_values : get_unspent_outputs->unspentOutputs()) {
            for (const QJsonValue& asset_value : assets_values.toArray()) {
                auto output = account()->getOrCreateOutput(asset_value.toObject());
                m_outputs.append(output);
                connect(output, &Output::expiredChanged, this, [this, output] {
                    const auto row = m_outputs.indexOf(output);
                    if (row < 0) return;
                    const auto model_index = index(row, 0);
                    emit dataChanged(model_index, model_index);
                });
            }
        }
        endResetModel();
        m_fetching = false;
        get_unspent_outputs->deleteLater();
        emit fetchingChanged();
    });

    connect(get_unspent_outputs, &Task::failed, this, [=, this](const QString& error) {
        m_error = error;
        m_fetching = false;
        get_unspent_outputs->deleteLater();
        emit errorChanged();
        emit fetchingChanged();
    });

    m_fetching = true;
    emit fetchingChanged();
    m_dispatcher->add(get_unspent_outputs);
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
