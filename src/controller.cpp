#include "controller.h"
#include <gdk.h>

#include "account.h"
#include "address.h"
#include "context.h"
#include "networkmanager.h"
#include "notification.h"
#include "task.h"
#include "session.h"
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
{
}

void Controller::setContext(Context* context)
{
    if (m_context == context) return;
    m_context = context;
    emit contextChanged();
    if (m_context) {
        auto wallet = m_context->wallet();
        if (!wallet || !wallet->context()) {
            m_context->setParent(this);
        }
    }
}

TaskDispatcher *Controller::dispatcher() const
{
    Q_ASSERT(m_context);
    return m_context->dispatcher();
}

void Controller::setMonitor(TaskGroupMonitor* monitor)
{
    if (m_monitor == monitor) return;
    if (m_monitor) m_monitor->deleteLater();
    m_monitor = monitor;
    emit monitorChanged();
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

    // // Check if wallet is undergoing reset
    // if (m_context->isLocked()) {
    //     qDebug() << Q_FUNC_INFO << "wallet is locked";
    //     return;
    // }

    for (auto session : m_context->getSessions()) {
        changeSessionSettings(session, data);
    }
}

void Controller::changeSessionSettings(Session* session, const QJsonObject& data)
{
    if (session->config().value("twofactor_reset").toObject().value("is_active").toBool()) {
        return;
    }
    if (!DeepContains(session->settings(), data)) {
        auto change_settings = new ChangeSettingsTask(data, session);
        dispatcher()->add(change_settings);
    }
}

void Controller::sendRecoveryTransactions()
{
    if (!m_context) return;

    auto session = m_context->primarySession();

    auto send_nlocktimes = new SendNLocktimesTask(session);

    dispatcher()->add(send_nlocktimes);
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

    auto session = m_context->primarySession();

    const auto change_twofactor = new ChangeTwoFactorTask(method, twofactor_details, session);
    const auto update_config = new LoadTwoFactorConfigTask(session);
    const auto change_settings = new ChangeSettingsTask(settings_details, session);

    change_twofactor->then(update_config);
    update_config->then(change_settings);

    auto group = new TaskGroup(this);

    group->add(change_twofactor);
    group->add(update_config);
    group->add(change_settings);

    dispatcher()->add(group);
}

void Controller::deleteWallet()
{
    auto session = m_context->primarySession();

    auto delete_wallet = new DeleteWalletTask(session);
    connect(delete_wallet, &Task::finished, this, [=] {
        WalletManager::instance()->removeWallet(m_context->wallet());
        QTimer::singleShot(500, m_context->wallet(), &Wallet::disconnect);
    });
    dispatcher()->add(delete_wallet);
}

void Controller::disableAllPins()
{
    auto group = new TaskGroup(this);
    for (auto session : m_context->getSessions()) {
        auto task = new DisableAllPinLoginsTask(session);
        group->add(task);
    }
    dispatcher()->add(group);
    connect(group, &TaskGroup::finished, this, [=] {
        m_context->wallet()->setLogin(nullptr);
        emit finished();
    });
}

void Controller::changePin(const QString& pin)
{
    if (!m_context) return;

    auto session = m_context->primarySession();
    auto encrypt_with_pin = new EncryptWithPinTask(m_context->credentials(), pin, session);
    auto group = new TaskGroup(this);
    group->add(encrypt_with_pin);
    dispatcher()->add(group);

    connect(group, &TaskGroup::finished, this, [=] {
        auto wallet = m_context->wallet();
        auto pin = new PinData(wallet);
        pin->setNetwork(session->network());
        pin->setData(encrypt_with_pin->result().value("result").toObject().value("pin_data").toObject());
        wallet->setLogin(pin);
        wallet->save();
        emit finished();
    });
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

    auto network = account->network();
    auto session = m_context->getOrCreateSession(network);

    const auto task = new UpdateAccountTask(QJsonObject{
        { "subaccount", static_cast<qint64>(account->pointer()) },
        { "name", name }
    }, session);

    connect(task, &Task::finished, this, [=] {
        account->setName(name);
    });

    m_context->dispatcher()->add(task);

    return true;
}

void Controller::setAccountHidden(Account* account, bool hidden)
{
    if (!m_context) return;
    auto network = account->network();
    auto session = m_context->getOrCreateSession(network);

    const auto task = new UpdateAccountTask(QJsonObject{
        { "subaccount", static_cast<qint64>(account->pointer()) },
        { "hidden", hidden }
    }, session);
    connect(task, &UpdateAccountTask::finished, this, [=] {
        account->setHidden(hidden);
    });
    dispatcher()->add(task);
}

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

void SessionController::setUnspentOutputsStatus(Account* account, const QVariantList& outputs, const QString& status)
{
    auto set_status = new SetUnspentOutputsStatusTask(outputs, status, m_session);
    auto load_balance = new LoadBalanceTask(account);

    set_status->then(load_balance);

    auto group = new TaskGroup(this);
    group->add(set_status);
    group->add(load_balance);
    dispatcher()->add(group);
    m_monitor->add(group);

    connect(group, &TaskGroup::finished, this, &Controller::finished);
}

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

SignMessageController::SignMessageController(QObject* parent)
    : Controller(parent)
{
}

void SignMessageController::setAddress(Address* address)
{
    if (m_address == address) return;
    m_address = address;
    emit addressChanged();
    clearSignature();
    updateValid();
}

void SignMessageController::setMessage(const QString& message)
{
    if (m_message == message) return;
    m_message = message;
    emit messageChanged();
    clearSignature();
    updateValid();
}

void SignMessageController::updateValid()
{
    const bool valid = m_address && !m_message.isEmpty();
    if (m_valid == valid) return;
    m_valid = valid;
    emit validChanged();
}

void SignMessageController::setSignature(const QString& signature)
{
    if (m_signature == signature) return;
    m_signature = signature;
    emit signatureChanged();
}

void SignMessageController::clearSignature()
{
    setSignature({});
    emit cleared();
}

void SignMessageController::sign()
{
    Q_ASSERT(m_valid);

    auto monitor = new TaskGroupMonitor(this);
    setMonitor(monitor);

    auto task = new SignMessageTask(m_message, m_address);

    connect(task, &Task::finished, this, [=] {
        setSignature(task->signature());
        emit accepted(task->signature());
    });

    connect(task, &Task::failed, this, [=] {
        emit rejected();
    });

    auto group = new TaskGroup(this);
    group->add(task);
    monitor->add(group);
    dispatcher()->add(group);
}

WatchOnlyController::WatchOnlyController(QObject* parent)
    : SessionController(parent)
{
    setMonitor(new TaskGroupMonitor(this));
}

void WatchOnlyController::update(const QString& username, const QString& password)
{
    if (!m_session) return;

    auto watchonly_data = qobject_cast<WatchonlyData*>(m_context->wallet()->login());
    if (watchonly_data) return;

    auto task = new SetWatchOnlyTask(username, password, m_session);

    connect(task, &Task::finished, this, [=] {
        m_session->setUsername(username);
        emit finished();
    });

    connect(task, &Task::failed, this, [=] {
        emit failed(task->error());
    });

    auto group = new TaskGroup(this);
    group->add(task);
    dispatcher()->add(group);
    monitor()->add(group);
}

void WatchOnlyController::clear()
{
    update("", "");
}

BCURController::BCURController(QObject* parent)
    : Controller(parent)
{
}

void BCURController::setProgress(int progress)
{
    if (m_progress == progress) return;
    m_progress = progress;
    emit progressChanged();
}

void BCURController::process(const QString& data)
{
    if (!m_result.isEmpty()) return;

    if (m_seen.contains(data)) return;
    m_seen.insert(data);

    if (!data.startsWith("ur:", Qt::CaseInsensitive)) {
        emit dataDiscarded(data);
        if (m_task) {
            m_task->deleteLater();
            m_task = nullptr;
        }
        return;
    }

    if (!m_context) {
        setContext(new Context("mainnet", false, this));
    }

    if (!m_task) {
        auto session = m_context->primarySession();
        dispatcher()->add(new ConnectTask(session));

        m_task = new DecodeBCURTask(data, session);
        connect(m_task, &DecodeBCURTask::promptChanged, this, [=] {
            auto prompt = qobject_cast<CodePrompt*>(m_task->prompt());
            if (!prompt) return;

            connect(prompt, &CodePrompt::resultChanged, this, [=] {
                setProgress(prompt->result().value("auth_data").toObject().value("estimated_progress").toInt());
                next();
            });
            next();
        });
        connect(m_task, &DecodeBCURTask::resultChanged, this, [=] {
            next();
        });
        connect(m_task, &DecodeBCURTask::finished, this, [=] {
            m_result = m_task->decodedResult();
            emit resultDecoded(m_result);
            m_task->deleteLater();
            m_task = nullptr;
        });
        connect(m_task, &DecodeBCURTask::failed, this, [=] {
            emit dataDiscarded(data);
            m_task->deleteLater();
            m_task = nullptr;
        });
        dispatcher()->add(m_task);
    } else {
        m_pending.enqueue(data);
        next();
    }
}

void BCURController::next()
{
    if (!m_task) return;

    auto prompt = qobject_cast<CodePrompt*>(m_task->prompt());
    if (!prompt) return;

    if (m_pending.isEmpty()) return;

    const auto part = m_pending.dequeue();
    prompt->resolve(part);
}
