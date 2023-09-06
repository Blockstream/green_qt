#include "asset.h"
#include "config.h"
#include "context.h"
#include "devicemanager.h"
#include "ga.h"
#include "json.h"
#include "network.h"
#include "output.h"
#include "resolver.h"
#include "session.h"
#include "task.h"
#include "wallet.h"

#include <QTimer>
#include <QTimerEvent>
#include <QtConcurrentRun>

#include <gdk.h>
#include <ga.h>

#include <nlohmann/json.hpp>

Task::Task(QObject* parent)
    : QObject(parent)
{
}

Task::~Task()
{
    if (m_group) {
        m_group->remove(this);
    }
}

QString Task::type() const
{
    QString text = metaObject()->className();
    QRegularExpression regexp("[A-Z][^A-Z]*");
    QRegularExpressionMatchIterator match = regexp.globalMatch(text);
    QList<QString> parts;

    while (match.hasNext()) {
        parts.append(match.next().capturedTexts());
    }

    if (parts.last() == "Task") parts.removeLast();
    return parts.join(' ');
}

void Task::setError(const QString& error)
{
    if (m_error == error) return;
    m_error = error;
    emit errorChanged();
}

void Task::needs(Task* task)
{
    m_inputs.insert(task);
    task->m_outputs.insert(this);
}

Task* Task::then(Task* task)
{
    m_outputs.insert(task);
    task->m_inputs.insert(this);
    return task;
}

void Task::dispatch()
{
    if (m_group) m_group->dispatch();
}

void Task::setStatus(Status status)
{
    if (m_status == status) return;

    m_status = status;
    emit statusChanged();

    if (m_status == Status::Finished) {
        emit finished();
    } else if (m_status == Status::Failed) {
        emit failed(m_error);
        for (auto task : m_outputs) {
            task->setStatus(Status::Failed);
        }
    }

    dispatch();
}

TaskDispatcher::TaskDispatcher(QObject* parent)
    : QObject(parent)
{
    auto timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &TaskDispatcher::dispatch);
    timer->start(1000);
}

TaskDispatcher::~TaskDispatcher()
{
    for (auto task : m_groups) {
        task->m_dispatcher = nullptr;
    }
    m_groups.clear();
    emit groupsChanged();
}

void TaskDispatcher::setBusy(bool busy)
{
    if (m_busy == busy) return;
    m_busy = busy;
    emit busyChanged();
}

void TaskDispatcher::updateBusy()
{
    QList<TaskGroup*> groups(m_groups.begin(), m_groups.end());
    for (auto group : groups) {
        QList<Task*> tasks(group->m_tasks.begin(), group->m_tasks.end());
        for (auto task : tasks) {
            if (task->m_status == Task::Status::Active) {
                setBusy(true);
                return;
            }
        }
    }
    setBusy(false);
}

QQmlListProperty<TaskGroup> TaskDispatcher::groups()
{
    return { this, &m_groups };
}

void TaskDispatcher::add(Task* task)
{
    auto group = new TaskGroup(this);
    group->add(task);
    add(group);
}

void TaskDispatcher::add(TaskGroup* group)
{
    if (m_groups.contains(group)) return;
    m_groups.prepend(group);
    group->m_dispatcher = this;
    emit groupsChanged();
    dispatch();
}

void TaskDispatcher::remove(TaskGroup* group)
{
    if (!m_groups.contains(group)) return;
    m_groups.removeOne(group);
    group->m_dispatcher = nullptr;
    emit groupsChanged();
    dispatch();
}

void TaskDispatcher::dispatch()
{
    if (m_dispatch_timer == 0) {
        m_dispatch_timer = startTimer(0);
    }
}

void TaskDispatcher::update()
{
    QList<TaskGroup*> groups(m_groups.begin(), m_groups.end());
    for (auto group : groups) {
        group->update();
    }
}

void TaskGroup::update()
{
    if (m_status == Status::Failed) return;

    bool any_active = false;
    bool any_failed = false;
    bool all_finished = true;

    QList<Task*> tasks(m_tasks.begin(), m_tasks.end());

    for (auto task : tasks) {
        if (task->m_status == Task::Status::Failed) {
            any_failed = true;
        }
        if (task->m_status == Task::Status::Active) {
            any_active = true;
        }
        if (task->m_status != Task::Status::Finished) {
            all_finished = false;
        }
    }

    if (all_finished) {
        setStatus(Status::Finished);
        return;
    }

    if (any_failed) {
        for (auto task : tasks) {
            task->setStatus(Task::Status::Failed);
        }
        setStatus(Status::Failed);
        return;
    }

    if (any_active) {
        setStatus(Status::Active);
    }

    for (auto task : tasks) {
        bool update = task->m_status == Task::Status::Ready || task->m_status == Task::Status::Active;
        if (update) {
            for (auto dependency : task->m_inputs) {
                if (dependency->m_status != Task::Status::Finished) update = false;
            }
            if (update) task->update();
        }
    }
}

void TaskDispatcher::timerEvent(QTimerEvent* event)
{
    if (event->timerId() == m_dispatch_timer) {
        killTimer(m_dispatch_timer);
        m_dispatch_timer = 0;
        update();
        updateBusy();
    }
}

SessionTask::SessionTask(Session* session)
    : Task(session)
    , m_session(session)
{
}

namespace {
    QJsonObject get_params(Session* session)
    {
        const auto network = session->network();
        const QString user_agent = QString("green_qt_%1").arg(GREEN_VERSION);
        QJsonObject params{
            { "name", network->id() },
            { "use_tor", session->useTor() },
            { "user_agent", user_agent },
            { "spv_enabled", session->enableSPV() }
        };
        if (!session->proxy().isEmpty()) {
            params.insert("proxy", session->proxy());
        }
        if (session->usePersonalNode()) {
            const auto url = session->electrumUrl();
            params.insert("electrum_url", url);
            params.insert("electrum_onion_url", url);
        }
        return params;
    }
} // namespace

AuthHandlerTask::AuthHandlerTask(Session* session)
    : SessionTask(session)
{
}

AuthHandlerTask::~AuthHandlerTask()
{
    if (m_auth_handler) {
        GA_destroy_auth_handler(m_auth_handler);
    }
}

void AuthHandlerTask::setResult(const QJsonObject& result)
{
    if (m_result == result) return;
    m_result = result;
    emit resultChanged();
}

void AuthHandlerTask::setResolver(Resolver* resolver)
{
    if (m_resolver == resolver) return;
    m_resolver = resolver;
    emit resolverChanged();
}

void AuthHandlerTask::update()
{
    if (m_status != Status::Ready) return;

    if (!m_session->isConnected()) return;

    if (!active()) return;

    setStatus(Status::Active);

    using Watcher = QFutureWatcher<QPair<bool, QJsonObject>>;
    const auto watcher = new Watcher(this);
    watcher->setFuture(QtConcurrent::run([=] {
        const auto ok = call(m_session->m_session, &m_auth_handler);
        const auto error = gdk::get_thread_error_details();
        return qMakePair(ok, error);
    }));

    connect(watcher, &Watcher::finished, this, [=] {
        if (watcher->result().first) {
            next();
        } else {
            setError(watcher->result().second.value("details").toString());
            setStatus(Status::Failed);
        }
    });
}

void AuthHandlerTask::requestCode(const QString &method)
{
    QtConcurrent::run([=] {
        const auto rc = GA_auth_handler_request_code(m_auth_handler, method.toUtf8().constData());
        return rc == GA_OK;
    }).then(this, [=](bool ok) {
        if (ok) {
            next();
        } else {
            setStatus(Status::Failed);
        }
    });
}

void AuthHandlerTask::resolveCode(const QByteArray& code)
{
    QtConcurrent::run([=] {
        const auto rc = GA_auth_handler_resolve_code(m_auth_handler, code.constData());
        return rc == GA_OK;
    }).then(this, [=](bool ok) {
        if (ok) {
            next();
        } else {
            setStatus(Status::Failed);
        }
    });
}

bool AuthHandlerTask::active() const
{
    return true;
}

void AuthHandlerTask::handleDone(const QJsonObject& result)
{
    Q_UNUSED(result);
    setResult(result);
    setStatus(Status::Finished);
}

void AuthHandlerTask::handleError(const QJsonObject& result)
{
    const auto error = result.value("error").toString();

    if (error == "Authentication required") {
        m_session->m_ready = false;
        auto login = new LoginTask(m_session);
        needs(login);
        group()->add(login);
        setStatus(Status::Ready);
        return;
    }

    if (error == "id_connection_failed") {
        m_session->setConnected(false);
    }

    setResult(result);
    setError(error);
    setStatus(Status::Failed);
}

void AuthHandlerTask::handleRequestCode(const QJsonObject& result)
{
    const auto methods = result.value("methods").toArray();
    if (methods.size() == 1) {
        const auto method = methods.first().toString();
        requestCode(method);
    } else {
        setResult(result);
    }
}


static Device* GetDeviceFromRequiredData(const QJsonObject& required_data)
{
    const auto device = required_data.value("device").toObject();
    const auto device_type = device.value("device_type").toString();
    Q_ASSERT(device_type == "hardware");
    const auto id = device.value("name").toString();
    return DeviceManager::instance()->deviceWithId(id);
}

void AuthHandlerTask::handleResolveCode(const QJsonObject& result)
{
    if (result.contains("method")) {
        setResult(result);
        return;
    }

    if (result.contains("required_data")) {
        Resolver* resolver{nullptr};
        const auto required_data = result.value("required_data").toObject();
        const auto device = GetDeviceFromRequiredData(required_data);
        Q_ASSERT(device);
// TODO request device
//            if (!device) {
//                emit deviceRequested();
//                return;
//            }
        auto network = m_session->network();
        const auto action = required_data.value("action").toString();
        if (action == "get_xpubs") {
            resolver = new GetXPubsResolver(device, result, m_session);
        } else if (action == "sign_message") {
            resolver = new SignMessageResolver(device, result, m_session);
        } else if (action == "get_blinding_public_keys") {
            resolver = new BlindingKeysResolver(device, result, m_session);
        } else if (action == "get_blinding_nonces") {
            resolver = new BlindingNoncesResolver(device, result, m_session);
        } else if (action =="sign_tx") {
            if (network->isLiquid()) {
                resolver = new SignLiquidTransactionResolver(device, result, m_session);
            } else {
                resolver = new SignTransactionResolver(device, result, m_session);
            }
        } else if (action == "get_master_blinding_key") {
            resolver = new GetMasterBlindingKeyResolver(device, result, m_session);
        } else {
            Q_UNREACHABLE();
        }
        Q_ASSERT(resolver);
        connect(resolver, &Resolver::resolved, this, [this](const QJsonObject& data) {
            setResolver(nullptr);
            resolveCode(QJsonDocument(data).toJson(QJsonDocument::Compact));
        });
        connect(resolver, &Resolver::failed, this, [this] {
            setResolver(nullptr);
            setStatus(Status::Failed);
        });
        resolver->resolve();
        setResolver(resolver);
        return;
    }

    Q_UNREACHABLE();
}

void AuthHandlerTask::handleCall(const QJsonObject& result)
{
    QtConcurrent::run([=] {
        const auto rc = GA_auth_handler_call(m_auth_handler);
        return rc == GA_OK;
    }).then(this, [=](bool ok) {
        if (ok) {
            next();
        } else {
            setStatus(Status::Failed);
        }
    });
}

void AuthHandlerTask::next()
{
    GA_json* output;
    const auto rc = GA_auth_handler_get_status(m_auth_handler, &output);
    if (rc != GA_OK) {
        setStatus(Status::Failed);
        return;
    }

    emit updated();

    const auto result = Json::toObject(output);
    GA_destroy_json(output);

    const auto status = result.value("status").toString();

    if (status == "done") {
        handleDone(result);
        return;
    }
    if (status == "error") {
        handleError(result);
        return;
    }
    if (status == "request_code") {
        handleRequestCode(result);
        return;
    }
    if (status == "resolve_code") {
        handleResolveCode(result);
        return;
    }
    if (status == "call") {
        handleCall(result);
        return;
    }

    Q_UNREACHABLE();
}

RegisterUserTask::RegisterUserTask(const QStringList& mnemonic, Session* session)
    : AuthHandlerTask(session)
    , m_details({{ "mnemonic", mnemonic.join(' ') }})
{
}

// TODO: assert device_details or use Device instance to infer them
RegisterUserTask::RegisterUserTask(const QJsonObject& device_details, Session* session)
    : AuthHandlerTask(session)
    , m_device_details(device_details)
{
}

bool RegisterUserTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    const auto details = Json::fromObject(m_details);
    auto device_details = Json::fromObject(m_device_details);
    const auto rc = GA_register_user(session, device_details.get(), details.get(), auth_handler);
    return rc == GA_OK;
}

void RegisterUserTask::handleDone(const QJsonObject& result)
{
    const auto wallet_hash_id = result.value("result").toObject().value("wallet_hash_id").toString();

    auto context = m_session->context();
    context->m_wallet_hash_id = wallet_hash_id;
    setStatus(Status::Finished);
}


LoginTask::LoginTask(Session* session)
    : AuthHandlerTask(session)
{
}

LoginTask::LoginTask(const QString& pin, const QJsonObject& pin_data, Session* session)
    : AuthHandlerTask(session)
    , m_details({
          { "pin", pin },
          { "pin_data", pin_data }
      })
{
}

LoginTask::LoginTask(const QStringList& mnemonic, const QString& password, Session* session)
    : AuthHandlerTask(session)
    , m_details({
          { "mnemonic", mnemonic.join(' ') },
          { "password", password }
      })
{
}

LoginTask::LoginTask(const QJsonObject& hw_device, Session* session)
    : AuthHandlerTask(session)
    , m_hw_device(hw_device)
{
}

LoginTask::LoginTask(const QString& username, const QString& password, Session* session)
    : AuthHandlerTask(session)
    , m_details({
          { "username", username },
          { "password", password }
      })
{
}

bool LoginTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    auto hw_device = Json::fromObject(m_hw_device);
    auto details = Json::fromObject(m_details);
    const auto rc = GA_login_user(session, hw_device.get(), details.get(), auth_handler);
    return rc == GA_OK;
}

void LoginTask::handleDone(const QJsonObject& result)
{
    const auto res = result.value("result").toObject();
    m_session->m_ready = true;
    auto context = m_session->context();
    context->m_wallet_hash_id = res.value("wallet_hash_id").toString();
    context->m_xpub_hash_id = res.value("xpub_hash_id").toString();

    AuthHandlerTask::handleDone(result);
}


LoadTwoFactorConfigTask::LoadTwoFactorConfigTask(Session* session)
    : SessionTask(session)
    , m_lock(false)
{
}

LoadTwoFactorConfigTask::LoadTwoFactorConfigTask(bool lock, Session* session)
    : SessionTask(session)
    , m_lock(lock)
{
}

void LoadTwoFactorConfigTask::update()
{
    if (m_status != Status::Ready) return;

    auto context = m_session->context();
    const auto wallet = context->wallet();
    if (!wallet) return;

    if (wallet->isWatchOnly()) {
        setStatus(Status::Finished);
        return;
    }

    if (!m_session->m_ready) return;

    setStatus(Status::Active);

    QtConcurrent::run([=] {
        return gdk::get_twofactor_config(m_session->m_session);
    }).then(this, [=](const QJsonObject& config) {
        m_session->setConfig(config);
        if (m_lock) context->setLocked(true);
        setStatus(Status::Finished);
    });
}

LoadCurrenciesTask::LoadCurrenciesTask(Session* session)
    : SessionTask(session)
{
}

void LoadCurrenciesTask::update()
{
    if (m_status != Status::Ready) return;

    if (!m_session->m_ready) return;

    setStatus(Status::Active);

    QtConcurrent::run([=] {
        return gdk::get_available_currencies(m_session->m_session);
    }).then(this, [=](const QJsonObject& currencies) {
        m_session->setCurrencies(currencies);
        setStatus(Status::Finished);
    });
}

LoadAccountsTask::LoadAccountsTask(bool refresh, Session* session)
    : AuthHandlerTask(session)
    , m_refresh(refresh)
{
}

bool LoadAccountsTask::active() const
{
    return m_session->m_ready;
}

bool LoadAccountsTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    auto details = Json::fromObject({{ "refresh", m_refresh }});
    int res = GA_get_subaccounts(session, details.get(), auth_handler);
    return res == GA_OK;
}

void LoadAccountsTask::handleDone(const QJsonObject& result)
{
    const auto subaccounts = result.value("result").toObject().value("subaccounts").toArray();
    auto context = m_session->context();
    auto network = m_session->network();
    for (auto value : subaccounts) {
        Account* account = context->getOrCreateAccount(network, value.toObject());
        context->m_accounts.append(account);
        // TODO should be added by the caller
        auto load_balance = new LoadBalanceTask(account);

        m_group->add(load_balance);
    }
    emit context->accountsChanged();
    setStatus(Status::Finished);
}

#include "account.h"

LoadBalanceTask::LoadBalanceTask(Account* account)
    : AuthHandlerTask(account->session())
    , m_account(account)
{
}

bool LoadBalanceTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    auto details = Json::fromObject({
        { "subaccount", static_cast<qint64>(m_account->pointer()) },
        { "num_confs", 0 }
    });

    int err = GA_get_balance(session, details.get(), auth_handler);
    return err == GA_OK;
}

void LoadBalanceTask::handleDone(const QJsonObject& result)
{
    const auto data = result.value("result").toObject();
    m_account->setBalanceData(data);
    setStatus(Status::Finished);
}

GetWatchOnlyDetailsTask::GetWatchOnlyDetailsTask(Session* session)
    : SessionTask(session)
{
}

void GetWatchOnlyDetailsTask::update()
{
    if (m_status != Status::Ready) return;

    const auto wallet = m_session->context()->wallet();
    if (!wallet) return;
    if (wallet->isWatchOnly()) {
        setStatus(Status::Finished);
        return;
    }

    if (!m_session->m_ready) return;

    setStatus(Status::Active);

    QtConcurrent::run([=] {
        char* data;
        const auto rc = GA_get_watch_only_username(m_session->m_session, &data);
        if (rc != GA_OK) return QString();
        const auto username = QString::fromUtf8(data);
        GA_destroy_string(data);
        return username;
    }).then(this, [=](const QString& username) {
        if (username.isNull()) {
            setStatus(Status::Failed);
        } else {
            m_session->context()->setUsername(username);
            setStatus(Status::Finished);
        }
    });
}

LoadAssetsTask::LoadAssetsTask(Session* session)
    : SessionTask(session)
{
}

void LoadAssetsTask::update()
{
    if (m_status != Status::Ready) return;

    if (!m_session->network()->isLiquid()) {
        setStatus(Status::Finished);
        return;
    }

    if (!m_session->m_ready) return;

    setStatus(Status::Active);

    QtConcurrent::run([=] {
        auto params = Json::fromObject({
            { "assets", true },
            { "icons", true },
        });
        const auto rc = GA_refresh_assets(m_session->m_session, params.get());
        return rc == GA_OK;
    }).then(this, [=](bool ok) {
        if (ok) {
            // TODO: move to bg thread?
            const nlohmann::json params = {{ "category", "all" }};
            nlohmann::json* output;

            const auto err = GA_get_assets(m_session->m_session, (const GA_json*) &params, (GA_json**) &output);
            Q_ASSERT(err == GA_OK);

            auto context = m_session->context();

            for (const auto& item : output->at("assets").items()) {
                const auto id = item.key();
                const auto data = item.value();
                auto asset = context->getOrCreateAsset(QString::fromStdString(id));
                asset->setData(Json::toObject((GA_json*) &data));
                if (output->at("icons").contains(id)) {
                    const auto icon = output->at("icons").at(id).get<std::string>();
                    asset->setIcon(QString("data:image/png;base64,") + QString::fromStdString(icon));
                }
            }
            GA_destroy_json((GA_json*) output);
        }
        setStatus(ok ? Status::Finished : Status::Failed);
    });
}

EncryptWithPinTask::EncryptWithPinTask(const QString& pin, Session* session)
    : AuthHandlerTask(session)
    , m_pin(pin)
{
}

EncryptWithPinTask::EncryptWithPinTask(const QJsonValue& plaintext, const QString& pin, Session* session)
    : AuthHandlerTask(session)
    , m_plaintext(plaintext)
    , m_pin(pin)
{
}

void EncryptWithPinTask::setPlaintext(const QJsonValue& plaintext)
{
    if (m_plaintext == plaintext) return;
    m_plaintext = plaintext;
    dispatch();
}

bool EncryptWithPinTask::active() const
{
    if (!AuthHandlerTask::active()) return false;
    if (m_plaintext.isNull() || m_plaintext.isUndefined()) return false;
    return true;
}

bool EncryptWithPinTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    const QJsonObject details({
        { "pin", m_pin },
        { "plaintext", m_plaintext }
    });
    const auto rc = GA_encrypt_with_pin(session, Json::fromObject(details).get(), auth_handler);
    return rc == GA_OK;
}

void EncryptWithPinTask::handleDone(const QJsonObject& result)
{
    const auto pin_data = result.value("result").toObject().value("pin_data").toObject();
    auto context = m_session->context();
    auto wallet = context->wallet();
    context->m_pin_data = pin_data;
    if (wallet) wallet->setPinData(QJsonDocument(pin_data).toJson());
    AuthHandlerTask::handleDone(result);
}

CreateAccountTask::CreateAccountTask(const QJsonObject& details, Session* session)
    : AuthHandlerTask(session)
    , m_details(details)
{
}

bool CreateAccountTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    const auto rc = GA_create_subaccount(session, Json::fromObject(m_details).get(), auth_handler);
    return rc == GA_OK;
}

void CreateAccountTask::handleDone(const QJsonObject &result)
{
    const auto pointer = result.value("result").toObject().value("pointer").toInt();
    m_pointer = pointer;
    setStatus(Status::Finished);
}

UpdateAccountTask::UpdateAccountTask(const QJsonObject &details, Session* session)
    : AuthHandlerTask(session)
    , m_details(details)
{
}

bool UpdateAccountTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    const auto rc = GA_update_subaccount(session, Json::fromObject(m_details).get(), auth_handler);
    return rc == GA_OK;
}

ChangeTwoFactorTask::ChangeTwoFactorTask(const QString& method, const QJsonObject& details, Session* session)
    : AuthHandlerTask(session)
    , m_method(method)
    , m_details(details)
{
}

bool ChangeTwoFactorTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    const auto details = Json::fromObject(m_details);
    const auto rc = GA_change_settings_twofactor(session, m_method.toUtf8().constData(), details.get(), auth_handler);
    return rc == GA_OK;
}

ContextTask::ContextTask(Context* context)
    : Task(context)
    , m_context(context)
{
    Q_ASSERT(context);
}

TwoFactorResetTask::TwoFactorResetTask(const QString& email, Session* session)
    : AuthHandlerTask(session)
    , m_email(email)
{
}

bool TwoFactorResetTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    const uint32_t is_dispute = GA_FALSE;
    const auto rc = GA_twofactor_reset(session, m_email.toUtf8().constData(), is_dispute, auth_handler);
    return rc == GA_OK;
}


SetCsvTimeTask::SetCsvTimeTask(const int value, Session* session)
    : AuthHandlerTask(session)
    , m_value(value)
{
}

bool SetCsvTimeTask::call(GA_session* session, GA_auth_handler** auth_handler) {
    auto details = Json::fromObject({{ "value", m_value }});
    const auto rc = GA_set_csvtime(session, details.get(), auth_handler);
    return rc == GA_OK;
}

void SetCsvTimeTask::handleDone(const QJsonObject &result)
{
    Q_ASSERT(m_session->isConnected());
    auto settings = gdk::get_settings(m_session->m_session);
    m_session->setSettings(settings);
    AuthHandlerTask::handleDone(result);
}

GetCredentialsTask::GetCredentialsTask(Session* session)
    : AuthHandlerTask(session)
{
}

bool GetCredentialsTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    const auto details = Json::fromObject({{ "password", "" }});
    const auto rc = GA_get_credentials(session, details.get(), auth_handler);
    return rc == GA_OK;
}

bool GetCredentialsTask::active() const
{
    if (!m_session->m_ready) return false;
    return AuthHandlerTask::active();
}

void GetCredentialsTask::handleDone(const QJsonObject& result)
{
    const auto credentials = result.value("result").toObject();
    m_session->context()->setCredentials(credentials);
    AuthHandlerTask::handleDone(result);
}

ChangeSettingsTask::ChangeSettingsTask(const QJsonObject& data, Session* session)
    : AuthHandlerTask(session)
    , m_data(data)
{
}

bool ChangeSettingsTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    const auto rc = GA_change_settings(session, Json::fromObject(m_data).get(), auth_handler);
    if (rc != GA_OK) return false;
    m_settings = gdk::get_settings(session);
    return true;
}

void ChangeSettingsTask::handleDone(const QJsonObject& result)
{
    if (!m_settings.isEmpty()) {
        m_session->setSettings(m_settings);
    }

    AuthHandlerTask::handleDone(result);
}

DisableAllPinLoginsTask::DisableAllPinLoginsTask(Session* session)
    : AuthHandlerTask(session)
{
}

bool DisableAllPinLoginsTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    const auto rc = GA_disable_all_pin_logins(session);
    return rc == GA_OK;
}

void DisableAllPinLoginsTask::handleDone(const QJsonObject& result)
{
    const auto wallet = m_session->context()->wallet();
    if (wallet) wallet->clearPinData();
    return AuthHandlerTask::handleDone(result);
}

TwoFactorChangeLimitsTask::TwoFactorChangeLimitsTask(const QJsonObject& details, Session* session)
    : AuthHandlerTask(session)
    , m_details(details)
{
}

bool TwoFactorChangeLimitsTask::call(GA_session *session, GA_auth_handler **auth_handler) {
    const auto details = Json::fromObject(m_details);
    const auto rc = GA_twofactor_change_limits(session, details.get(), auth_handler);
    return rc == GA_OK;
}

CreateTransactionTask::CreateTransactionTask(const QJsonObject &details, Session* session)
    : AuthHandlerTask(session)
    , m_details(details)
{
}

bool CreateTransactionTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    const auto rc = GA_create_transaction(session, Json::fromObject(m_details).get(), auth_handler);
    return rc == GA_OK;
}

void CreateTransactionTask::handleDone(const QJsonObject& result)
{
    auto data = result.value("result").toObject();
    emit transaction(data);

    AuthHandlerTask::handleDone(result);
}


SendNLocktimesTask::SendNLocktimesTask(Session* session)
    : SessionTask(session)
{
}

void SendNLocktimesTask::update()
{
    if (m_status != Status::Ready) return;

    if (!m_session->m_ready) return;

    setStatus(Status::Active);

    QtConcurrent::run([=] {
        const auto rc = GA_send_nlocktimes(m_session->m_session);
        if (rc != GA_OK) return false;
        const auto settings = gdk::get_settings(m_session->m_session);
        m_session->setSettings(settings);
        return true;
    }).then(this, [=](bool ok) {
        setStatus(ok ? Status::Finished : Status::Failed);
    });
}

TaskGroup::TaskGroup(QObject* parent)
    : QObject(parent)
{
}

TaskGroup::~TaskGroup()
{
    if (m_dispatcher) m_dispatcher->remove(this);
    for (auto task : m_tasks) {
        task->m_group = nullptr;
    }
}

void TaskGroup::setStatus(Status status)
{
    if (m_status == status) return;
    m_status = status;
    emit statusChanged();
    if (m_status == Status::Finished) emit finished();
    if (m_status == Status::Failed) emit failed();
}

void TaskGroup::add(Task* task)
{
    if (m_tasks.contains(task)) return;
    m_tasks.append(task);
    task->m_group = this;
    emit tasksChanged();
    dispatch();
}

void TaskGroup::remove(Task* task)
{
    if (!m_tasks.contains(task)) return;
    m_tasks.removeOne(task);
    task->m_group = nullptr;
    emit tasksChanged();
    dispatch();
}

QQmlListProperty<Task> TaskGroup::tasks()
{
    return { this, &m_tasks };
}

void TaskGroup::dispatch()
{
    if (m_dispatcher) m_dispatcher->dispatch();
}

SignTransactionTask::SignTransactionTask(Session* session)
    : AuthHandlerTask(session)
{
}

void SignTransactionTask::setDetails(const QJsonObject& details)
{
    m_details = details;
}

bool SignTransactionTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    auto details = Json::fromObject(m_details);
    const auto rc = GA_sign_transaction(session, details.get(), auth_handler);
    return rc == GA_OK;
}

SendTransactionTask::SendTransactionTask(Session* session)
    : AuthHandlerTask(session)
{
}

void SendTransactionTask::setDetails(const QJsonObject &details)
{
    m_details = details;
}

bool SendTransactionTask::active() const
{
    if (m_details.isEmpty()) return false;
    return AuthHandlerTask::active();
}

bool SendTransactionTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    auto details = Json::fromObject(m_details);
    const auto rc = GA_send_transaction(session, details.get(), auth_handler);
    return rc == GA_OK;
}

GetUnspentOutputsTask::GetUnspentOutputsTask(int num_confs, bool all_coins, Account* account)
    : AuthHandlerTask(account->session())
    , m_subaccount(account->pointer())
    , m_num_confs(num_confs)
    , m_all_coins(all_coins)
{
}

QJsonObject GetUnspentOutputsTask::unspentOutputs() const
{
    return result().value("result").toObject().value("unspent_outputs").toObject();
}

bool GetUnspentOutputsTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    auto details = Json::fromObject({
        { "subaccount", m_subaccount },
        { "num_confs", m_num_confs },
        { "all_coins", m_all_coins }
    });

    const auto rc = GA_get_unspent_outputs(session, details.get(), auth_handler);
    return rc == GA_OK;
}

GetTransactionsTask::GetTransactionsTask(int first, int count, Account* account)
    : AuthHandlerTask(account->session())
    , m_subaccount(account->pointer())
    , m_first(first)
    , m_count(count)
{
}

bool GetTransactionsTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    auto details = Json::fromObject({
        { "subaccount", m_subaccount },
        { "first", m_first },
        { "count", m_count }
    });

    const auto rc = GA_get_transactions(session, details.get(), auth_handler);
    return rc == GA_OK;
}

QJsonArray GetTransactionsTask::transactions() const
{
    return result().value("result").toObject().value("transactions").toArray();
}

GetAddressesTask::GetAddressesTask(int last_pointer, Account* account)
    : AuthHandlerTask(account->session())
    , m_subaccount(account->pointer())
    , m_last_pointer(last_pointer)
{
}

bool GetAddressesTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    QJsonObject _details({{ "subaccount", m_subaccount }});
    if (m_last_pointer != 0) _details["last_pointer"] = m_last_pointer;
    auto details = Json::fromObject(_details);

    const auto rc = GA_get_previous_addresses(session, details.get(), auth_handler);
    return rc == GA_OK;
}

QJsonArray GetAddressesTask::addresses() const
{
    return result().value("result").toObject().value("list").toArray();
}

int GetAddressesTask::lastPointer() const
{
    return result().value("result").toObject().value("last_pointer").toInt(1);
}


DeleteWalletTask::DeleteWalletTask(Session* session)
    : AuthHandlerTask(session)
{
}

bool DeleteWalletTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    const auto rc = GA_remove_account(session, auth_handler);
    return rc == GA_OK;
}

TwoFactorCancelResetTask::TwoFactorCancelResetTask(Session* session)
    : AuthHandlerTask(session)
{
}

bool TwoFactorCancelResetTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    const auto rc = GA_twofactor_cancel_reset(session, auth_handler);
    return rc == GA_OK;
}

SetUnspentOutputsStatusTask::SetUnspentOutputsStatusTask(const QVariantList &outputs, const QString &status, Session* session)
    : AuthHandlerTask(session)
    , m_outputs(outputs)
    , m_status(status)
{
}

bool SetUnspentOutputsStatusTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    QJsonArray list;
    for (const auto& variant : m_outputs)
    {
        auto output = variant.value<Output*>();
        QJsonObject o;
        o["txhash"] = output->data()["txhash"].toString();
        o["pt_idx"] = output->data()["pt_idx"].toInt();
        o["user_status"] = m_status;
        list.append(o);
    }
    auto details = Json::fromObject({
        { "list", list }
    });

    const auto rc = GA_set_unspent_outputs_status(session, details.get(), auth_handler);
    return rc == GA_OK;
}

SetWatchOnlyTask::SetWatchOnlyTask(const QString& username, const QString& password, Session* session)
    : SessionTask(session)
    , m_username(username)
    , m_password(password)
{
}

void SetWatchOnlyTask::update()
{
    if (m_status != Status::Ready) return;

    setStatus(Status::Active);

    if (!m_session->isConnected()) return;

    using Watcher = QFutureWatcher<QString>;
    const auto watcher = new Watcher(this);
    watcher->setFuture(QtConcurrent::run([=] {
        const auto rc = GA_set_watch_only(m_session->m_session, m_username.toUtf8().constData(), m_password.toUtf8().constData());
        if (rc == GA_OK) return QString();
        const auto error = gdk::get_thread_error_details();
        return error.value("details").toString();
    }));

    connect(watcher, &Watcher::finished, this, [=] {
        const auto error = watcher->result();
        setError(error);
        if (error.isEmpty()) {
            setStatus(Status::Finished);
        } else {
            setStatus(Status::Failed);
        }
    });
}

ConnectTask::ConnectTask(Session* session)
    : SessionTask(session)
{
}

void ConnectTask::update()
{
    if (m_status == Status::Ready) {
        setStatus(Status::Active);

        m_session->setConnecting(true);

        using Watcher = QFutureWatcher<QString>;
        const auto watcher = new Watcher(this);
        watcher->setFuture(QtConcurrent::run([=] {
            const auto params = get_params(m_session);
            const auto rc = GA_connect(m_session->m_session, Json::fromObject(params).get());
            if (rc == GA_OK) return QString();
            const auto error = gdk::get_thread_error_details();
            return error.value("details").toString();
        }));

        connect(watcher, &Watcher::finished, this, [=] {
            const auto error = watcher->result();
            if (error.contains("session already connected")) {
                m_session->setConnecting(false);
                m_session->setConnected(true);
                setStatus(Status::Finished);
                return;
            }
            setError(error);
            m_session->setConnecting(false);
            if (error.isEmpty()) {
                m_session->setConnected(true);
                setStatus(Status::Finished);
            } else {
                setStatus(Status::Failed);
            }
        });
    } else if (m_status == Status::Active) {
        if (m_session->isConnected()) {
            setStatus(Status::Finished);
        }
    }
}

BlindTransactionTask::BlindTransactionTask(const QJsonObject& details, Session* session)
    : AuthHandlerTask(session)
    , m_details(details)
{
}

bool BlindTransactionTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    const auto rc = GA_blind_transaction(session, Json::fromObject(m_details).get(), auth_handler);
    return rc == GA_OK;
}
