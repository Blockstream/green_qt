#include "twofactorcontroller.h"

#include "task.h"

TwoFactorController::TwoFactorController(QObject* parent)
    : SessionController(parent)
{
}

void TwoFactorController::setMethod(const QString& method)
{
    if (m_method == method) return;
    m_method = method;
    emit methodChanged();
}

void TwoFactorController::enable(const QString &data)
{
    change({ { "enabled", true }, { "data", data } });
}

void TwoFactorController::disable()
{
    change({ { "enabled", false } });
}

void TwoFactorController::change(const QJsonObject& details)
{
    if (!m_context) return;
    if (!m_session) return;
    if (m_method.isEmpty()) return;

    clearErrors();

    auto change_twofactor = new ChangeTwoFactorTask(m_method, details, m_session);
    auto update_config = new LoadTwoFactorConfigTask(m_session);

    connect(change_twofactor, &Task::failed, this, [=](const QString& error) {
        if (error.contains("invalid phone number", Qt::CaseInsensitive)) {
            emit failed("id_invalid_phone_number_format");
        } else {
            emit failed(error);
        }
        emit failed(error);
    });

    update_config->needs(change_twofactor);

    auto group = new TaskGroup(this);

    group->add(change_twofactor);
    group->add(update_config);

    dispatcher()->add(group);
    m_monitor->add(group);

    connect(group, &TaskGroup::finished, this, [=] {
        emit finished();
    });
}

void TwoFactorController::changeLimits(const QString& satoshi)
{
    if (!m_context) return;
    if (!m_session) return;

    auto details = QJsonObject{
        { "is_fiat", false },
        { "satoshi", satoshi.toLongLong() }
    };

    auto group = new TaskGroup(this);

    auto change_twofactor_limits = new TwoFactorChangeLimitsTask(details, m_session);
    auto load_twofactor_config = new LoadTwoFactorConfigTask(m_session);

    change_twofactor_limits->then(load_twofactor_config);

    group->add(change_twofactor_limits);
    group->add(load_twofactor_config);

    dispatcher()->add(group);
    m_monitor->add(group);

    connect(change_twofactor_limits, &Task::failed, this, [=](const QString& error) {
        emit failed(error);
    });
    connect(group, &TaskGroup::finished, this, [=] {
        emit finished();
    });
}

void TwoFactorController::setCsvTime(int value)
{
    if (!m_context) return;
    if (!m_session) return;

    auto set_csv_time = new SetCsvTimeTask(value, m_session);

    auto group = new TaskGroup(this);

    group->add(set_csv_time);

    dispatcher()->add(group);
    m_monitor->add(group);

    connect(set_csv_time, &Task::failed, this, [=](const QString& error) {
        emit failed(error);
    });
    connect(group, &TaskGroup::finished, this, [=] {
        emit finished();
    });
}
