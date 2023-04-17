#include "controller.h"

#include <gdk.h>

#include "account.h"
#include "context.h"
#include "task.h"
#include "wallet.h"
#include "walletmanager.h"

AbstractController::AbstractController(QObject* parent)
    : Entity(parent)
{
}

bool AbstractController::updateError(const QString &key, const QVariant &value, bool when)
{
    if (when) {
        setError(key, value);
        return true;
    } else {
        clearError(key);
        return false;
    }
}

void AbstractController::setError(const QString &key, const QVariant &value)
{
    Q_ASSERT(!value.isNull());
    if (m_errors.contains(key) && m_errors.value(key) == value) return;
    m_errors[key] = value;
    emit errorsChanged();
}

void AbstractController::clearError(const QString &key)
{
    if (!m_errors.contains(key)) return;
    m_errors.remove(key);
    emit errorsChanged();
}

void AbstractController::clearErrors()
{
    if (m_errors.empty()) return;
    m_errors.clear();
    emit errorsChanged();
}

Controller::Controller(QObject* parent)
    : AbstractController(parent)
    , m_dispatcher(new TaskDispatcher(this))
{
}

void Controller::setContext(Context* context)
{
    if (m_context == context) return;
    m_context = context;
    emit contextChanged();
}

static bool DeepContains(const QJsonObject& a, const QJsonObject& b)
{
    for (auto i = b.begin(); i != b.end(); ++i) {
        const auto j = a.value(i.key());
        if (j.type() != i->type()) return false;
        if (j.isObject()) {
            if (!DeepContains(j.toObject(), i.value().toObject())) return false;
        } else {
            if (j != i.value()) return false;
        }
    }
    return true;
}

void Controller::changeSettings(const QJsonObject& data)
{
    if (!m_context) return;

    // Check if wallet is undergoing reset
    if (m_context->isLocked()) {
        qDebug() << Q_FUNC_INFO << "wallet is locked";
        return;
    }

    // Avoid unnecessary calls to GA_change_settings
    if (DeepContains(m_context->settings(), data)) return;

//    bool updated = true;
//    auto settings = m_context->settings();
//    for (auto i = data.begin(); i != data.end(); ++i) {
//        if (settings.value(i.key()) != i.value()) {
//            updated = false;
//            settings[i.key()] = i.value();
//        }
//    }
//    if (updated) return;

    auto change_settings = new ChangeSettingsTask(data, m_context);

    m_dispatcher->add(change_settings);
}

void Controller::sendRecoveryTransactions()
{
    if (!m_context) return;

    auto send_nlocktimes = new SendNLocktimesTask(m_context);

    m_dispatcher->add(send_nlocktimes);
}

#include "task.h"

void Controller::changeTwoFactorLimit(bool is_fiat, const QString& limit)
{
    if (!m_context) return;
    auto unit = is_fiat ? "fiat" : m_context->unit().toLower();
    if (!is_fiat && unit == "\u00B5btc") unit = "ubtc";
    auto details = QJsonObject{
        { "is_fiat", is_fiat },
        { unit, limit }
    };

    auto group = new TaskGroup(this);

    auto change_twofactor_limits = new TwoFactorChangeLimitsTask(details, m_context);
    auto load_twofactor_config = new LoadTwoFactorConfigTask(m_context);

    change_twofactor_limits->then(load_twofactor_config);

    group->add(change_twofactor_limits);
    group->add(load_twofactor_config);

    m_dispatcher->add(group);
}

void Controller::requestTwoFactorReset(const QString& email)
{
    if (!m_context) return;

    auto twofactor_reset = new TwoFactorResetTask(email, m_context);
    // TODO: update config doesn't update 2f reset data,
    // it's only updated after authentication in GDK,
    // so force wallet lock for now
    auto load_config = new LoadTwoFactorConfigTask(true, m_context);

    twofactor_reset->then(load_config);

    auto group = new TaskGroup(this);

    group->add(twofactor_reset);
    group->add(load_config);

    m_dispatcher->add(group);
}

void Controller::cancelTwoFactorReset()
{
    if (!m_context) return;
    auto task = new TwoFactorCancelResetTask(m_context);
    connect(task, &Task::finished, this, [=] {
        // TODO
        // m_context->updateConfig();

        // TODO: updateConfig doesn't update 2f reset data,
        // it's only updated after authentication in GDK,
        // so force wallet unlock for now.
        m_context->setLocked(false);
        emit finished();
    });
    m_dispatcher->add(task);
}

void Controller::setRecoveryEmail(const QString& email)
{
    if (!m_context) return;
    const auto method = QByteArray{"email"};
    const auto twofactor_details = QJsonObject{
        { "data", email.toLatin1().data() },
        { "confirmed", true },
        { "enabled", false }
    };

    const auto settings_details = QJsonObject{
        { "notifications" , QJsonValue({
            { "email_incoming", true },
            { "email_outgoing", true }})
        }
    };

    const auto change_twofactor = new ChangeTwoFactorTask(method, twofactor_details, m_context);
    const auto update_config = new LoadTwoFactorConfigTask(m_context);
    const auto change_settings = new ChangeSettingsTask(settings_details, m_context);

    change_twofactor->then(update_config);
    update_config->then(change_settings);

    auto group = new TaskGroup(this);

    group->add(change_twofactor);
    group->add(update_config);
    group->add(change_settings);

    m_dispatcher->add(group);
}

void Controller::setCsvTime(int value)
{
    if (!m_context) return;

    auto set_csv_time = new SetCsvTimeTask(value, m_context);

    m_dispatcher->add(set_csv_time);
}

void Controller::deleteWallet()
{
    auto delete_wallet = new DeleteWalletTask(m_context);
    connect(delete_wallet, &Task::finished, this, [=] {
        WalletManager::instance()->removeWallet(m_context->wallet());
        QTimer::singleShot(500, m_context->wallet(), &Wallet::disconnect);
    });
    m_dispatcher->add(delete_wallet);
}

void Controller::disableAllPins()
{
    auto disable_all_pins = new DisableAllPinLoginsTask(m_context);

    m_dispatcher->add(disable_all_pins);
}

void Controller::setUnspentOutputsStatus(const QVariantList& outputs, const QString& status)
{
    auto task = new SetUnspentOutputsStatusTask(outputs, status, m_context);
    connect(task, &Task::finished, this, [=] {
        emit finished();
    });
    m_dispatcher->add(task);
}

void Controller::changePin(const QString& pin)
{
    if (!m_context) return;

    auto encrypt_with_pin = new EncryptWithPinTask(m_context->credentials(), pin, m_context);
    auto group = new TaskGroup(this);
    group->add(encrypt_with_pin);
    m_dispatcher->add(group);

    connect(group, &TaskGroup::finished, this, [=] {
        emit finished();
    });
}

void Controller::setWatchOnly(const QString& username, const QString& password)
{
    if (m_context->wallet()->isWatchOnly()) return;

    auto task = new SetWatchOnlyTask(username, password, m_context);

    connect(task, &Task::finished, this, [=] {
        m_context->setUsername(username);
        emit watchOnlyUpdateSuccess();
    });

    connect(task, &Task::failed, this, [=] {
        emit watchOnlyUpdateFailure();
    });

    m_dispatcher->add(task);
}

void Controller::clearWatchOnly()
{
    setWatchOnly("", "");
}

bool Controller::setAccountName(Account* account, QString name, bool active_focus)
{
    if (!m_context) return false;

    if (!active_focus) name = name.trimmed();
    if (name.isEmpty() && !active_focus) {
        return false;
    }
    if (account->name() == name) return false;
    if (active_focus) return false;

    const auto task = new UpdateAccountTask(QJsonObject{
        { "subaccount", static_cast<qint64>(account->pointer()) },
        { "name", name }
    }, m_context);

    connect(task, &Task::finished, this, [=] {
        account->setName(name);
    });

    m_dispatcher->add(task);

    return true;
}

void Controller::setAccountHidden(Account* account, bool hidden)
{
    if (!m_context) return;
    const auto task = new UpdateAccountTask(QJsonObject{
        { "subaccount", static_cast<qint64>(account->pointer()) },
        { "hidden", hidden }
    }, m_context);
    connect(task, &UpdateAccountTask::finished, this, [=] {
        account->setHidden(hidden);
    });
    m_dispatcher->add(task);
}

TwoFactorController::TwoFactorController(QObject* parent)
    : Controller(parent)
{
}

void TwoFactorController::enable(const QString &method, const QString &data)
{
    change(method, { { "enabled", true }, { "data", data } });
}

void TwoFactorController::disable(const QString &method)
{
    change(method, { { "enabled", false } });
}

void TwoFactorController::change(const QString& method, const QJsonObject& details)
{
    if (!m_context) return;
    if (m_done) return;
    if (m_dispatcher->isBusy()) return;

    clearErrors();

    auto change_twofactor = new ChangeTwoFactorTask(method, details, m_context);
    auto update_config = new LoadTwoFactorConfigTask(m_context);

    connect(change_twofactor, &Task::failed, this, [=](const QString& error) {
        if (error.contains("invalid phone number", Qt::CaseInsensitive)) {
            setError("data", "id_invalid_phone_number_format");
        } else {
            setError("code", "id_invalid_twofactor_code");
        }
    });

    update_config->needs(change_twofactor);

    auto group = new TaskGroup(this);

    group->add(change_twofactor);
    group->add(update_config);

    m_dispatcher->add(group);

    connect(group, &TaskGroup::finished, this, [=] {
        emit finished();
        m_done = true;
        emit doneChanged();
    });
}
