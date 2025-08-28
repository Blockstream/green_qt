#include "sessioncontroller.h"

#include "task.h"
#include "session.h"
#include "account.h"
#include "notification.h"
#include "context.h"

SessionController::SessionController(QObject* parent)
    : Controller(parent)
{
    setMonitor(new TaskGroupMonitor(this));
}

void SessionController::setSession(Session* session)
{
    if (m_session == session) return;
    m_session = session;
    emit sessionChanged();
    if (m_session) setContext(m_session->context());
}

void SessionController::requestTwoFactorReset(const QString& email)
{
    auto group = new TaskGroup(this);
    auto request = new TwoFactorResetTask(email, m_session);
    auto load = new LoadTwoFactorConfigTask(m_session);
    connect(group, &TaskGroup::finished, this, [=] {
        emit finished();
        auto notification = new TwoFactorResetNotification(m_session->network(), m_context);
        m_context->addNotification(notification);
    });
    connect(request, &Task::failed, this, [=](const QString& error) {
        emit failed(error);
    });
    request->then(load);
    group->add(request);
    group->add(load);
    monitor()->add(group);
    dispatcher()->add(group);
}

void SessionController::cancelTwoFactorReset()
{
    auto group = new TaskGroup(this);
    auto cancel = new TwoFactorCancelResetTask(m_session);
    auto load = new LoadTwoFactorConfigTask(m_session);
    connect(group, &TaskGroup::finished, this, [=] {
        emit finished();
    });
    connect(cancel, &Task::failed, this, [=](const QString& error) {
        emit failed(error);
    });
    cancel->then(load);
    group->add(cancel);
    group->add(load);
    monitor()->add(group);
    dispatcher()->add(group);
}

void SessionController::setUnspentOutputsStatus(Account* account, const QVariantList& outputs, const QString& status)
{
    auto set_status = new SetUnspentOutputsStatusTask(outputs, status, m_session);
    auto load_balance = new LoadBalanceTask(account);
    auto get_unspent_outputs = new GetUnspentOutputsTask(0, true, account);

    set_status->then(load_balance);
    load_balance->then(get_unspent_outputs);

    auto group = new TaskGroup(this);
    group->add(set_status);
    group->add(load_balance);
    group->add(get_unspent_outputs);

    dispatcher()->add(group);
    m_monitor->add(group);

    connect(get_unspent_outputs, &Task::finished, this, [=] {
        for (const QJsonValue& assets_values : get_unspent_outputs->unspentOutputs()) {
            for (const QJsonValue& asset_value : assets_values.toArray()) {
                auto output = account->getOrCreateOutput(asset_value.toObject());
            }
        }
    });

    connect(group, &TaskGroup::finished, this, &Controller::finished);
}

void SessionController::sendRecoveryTransactions()
{
    if (!m_session) return;
    auto group = new TaskGroup(this);
    auto send_nlocktimes = new SendNLocktimesTask(m_session);
    connect(send_nlocktimes, &Task::failed, this, [=](const QString& error) {
        emit failed(error);
    });
    connect(send_nlocktimes, &Task::finished, this, [=]() {
        emit finished();
    });
    group->add(send_nlocktimes);
    monitor()->add(group);
    dispatcher()->add(group);
}
