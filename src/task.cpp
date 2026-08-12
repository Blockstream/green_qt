#include "account.h"
#include "address.h"
#include "asset.h"
#include "config.h"
#include "context.h"
#include "device.h"
#include "devicemanager.h"
#include "ga.h"
#include "json.h"
#include "network.h"
#include "output.h"
#include "payment.h"
#include "resolver.h"
#include "session.h"
#include "sessionmanager.h"
#include "profile.h"
#include "task.h"
#include "util.h"
#include "wallet.h"

#include <QDebug>
#include <QFutureSynchronizer>
#include <QMetaEnum>
#include <QFileInfo>
#include <QNetworkAccessManager>
#include <QPointer>
#include <QString>
#include <QTimer>
#include <QTimerEvent>
#include <QtConcurrentRun>

#include <gdk.h>
#include <ga.h>

#include <nlohmann/json.hpp>

namespace {
QString taskStatusLabel(Task::Status status)
{
    const auto meta = QMetaEnum::fromType<Task::Status>();
    const char* key = meta.valueToKey(static_cast<int>(status));
    return key ? QString::fromLatin1(key) : QStringLiteral("?");
}
} // namespace

class TaskPrivate
{
public:
    virtual ~TaskPrivate() = default;
    QFutureSynchronizer<void> future_synchronizer;
};

class SessionTaskPrivate : public TaskPrivate { public: Session* session{nullptr}; };
class ContextTaskPrivate : public TaskPrivate { public: Context* context{nullptr}; };

class AuthHandlerTaskPrivate : public SessionTaskPrivate
{
public:
    ~AuthHandlerTaskPrivate() override
    {
        if (auth_handler) {
            GA_destroy_auth_handler(auth_handler);
        }
    }
    GA_auth_handler* auth_handler{nullptr};
};

class RegisterUserTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject details; QJsonObject device_details; };
class LoginTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject details; QJsonObject hw_device; };
class LoadAccountTaskPrivate : public AuthHandlerTaskPrivate { public: uint32_t pointer{0}; Account* account{nullptr}; };
class LoadAccountsTaskPrivate : public AuthHandlerTaskPrivate { public: bool refresh{false}; QList<Account*> accounts; };
class LoadBalanceTaskPrivate : public AuthHandlerTaskPrivate { public: Account* account{nullptr}; };
class EncryptWithPinTaskPrivate : public AuthHandlerTaskPrivate { public: QString pin; QJsonValue plaintext; };
class CreateAccountTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject details; quint32 pointer{0}; };
class UpdateAccountTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject details; };
class ValidateTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject details; };
class ChangeTwoFactorTaskPrivate : public AuthHandlerTaskPrivate { public: QString method; QJsonObject details; };
class TwoFactorResetTaskPrivate : public AuthHandlerTaskPrivate { public: QString email; bool dispute{false}; };
class TwoFactorUndoResetTaskPrivate : public AuthHandlerTaskPrivate { public: QString email; };
class SetCsvTimeTaskPrivate : public AuthHandlerTaskPrivate { public: int value{0}; };
class ChangeSettingsTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject data; };
class TwoFactorChangeLimitsTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject details; };
class CreateTransactionTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject details; };
class CreateRedepositTransactionTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject details; };
class SignTransactionTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject details; };
class BlindTransactionTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject details; };
class SendTransactionTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject details; };
class GetUnspentOutputsTaskPrivate : public AuthHandlerTaskPrivate { public: qint64 subaccount{0}; int num_confs{0}; bool all_coins{false}; uint32_t expired_at{0}; };
class SetUnspentOutputsStatusTaskPrivate : public AuthHandlerTaskPrivate { public: QVariantList outputs; QString status; };
class GetTransactionsTaskPrivate : public AuthHandlerTaskPrivate { public: qint64 subaccount{0}; int first{0}; int count{0}; };
class GetReceiveAddressTaskPrivate : public AuthHandlerTaskPrivate { public: Account* account{nullptr}; };
class GetAddressesTaskPrivate : public AuthHandlerTaskPrivate { public: qint64 subaccount{0}; int last_pointer{0}; };
class SignMessageTaskPrivate : public AuthHandlerTaskPrivate { public: Address* address{nullptr}; QString message; };
class AckSystemMessageTaskPrivate : public AuthHandlerTaskPrivate { public: QString message; };
class DecodeBCURTaskPrivate : public AuthHandlerTaskPrivate { public: QString part; };
class EncodeBCURTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject details; };
class RSAVerifyTaskPrivate : public AuthHandlerTaskPrivate { public: QJsonObject details; };
class ConnectTaskPrivate : public SessionTaskPrivate { public: int timeout{0}; };
class LoadAssetsTaskPrivate : public SessionTaskPrivate { public: bool refresh{false}; };
class GetSystemMessageTaskPrivate : public SessionTaskPrivate { public: QString message; };
class HttpRequestTaskPrivate : public SessionTaskPrivate { public: QJsonObject params; QJsonObject response; };
class LoadPaymentsTaskPrivate : public ContextTaskPrivate { public: QNetworkAccessManager* net{nullptr}; };

Task::Task(QObject* parent)
    : Task(new TaskPrivate, parent)
{
}

Task::Task(TaskPrivate* d, QObject* parent)
    : QObject(parent)
    , d_ptr(d)
{
    m_status_timer.start();
}

Task::~Task()
{
    Q_D(Task);
    // Drain any in-flight workers before destroying the private (and any
    // resources it owns, e.g. AuthHandlerTaskPrivate::auth_handler).
    d->future_synchronizer.waitForFinished();
    // Tasks reference each other through raw pointers and are not necessarily
    // destroyed together, so drop the edges pointing back at this task. Left
    // behind, they are walked by setStatus() and TaskGroup::update().
    for (auto task : m_inputs) {
        task->m_outputs.remove(this);
    }
    for (auto task : m_outputs) {
        task->m_inputs.remove(this);
    }
    if (m_group) {
        m_group->remove(this);
    }
    delete d_ptr;
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

QString Task::description() const
{
    return type();
}

const void* Task::profilingContext() const
{
    return parent() ? static_cast<const void*>(parent()) : static_cast<const void*>(this);
}

void Task::setError(const QString& error)
{
    if (m_error == error) return;
    qDebug() << Q_FUNC_INFO << type() << error;
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

    const qint64 duration_ms = m_status_timer.elapsed();
    const Status from = m_status;
    m_status_timer.restart();

    qCInfo(profile).nospace() << description() << " status change "
                              << taskStatusLabel(from) << " -> " << taskStatusLabel(status)
                              << " duration_ms=" << duration_ms << " context=0x"
                              << Qt::hex << reinterpret_cast<quintptr>(profilingContext()) << Qt::dec;

    m_status = status;
    emit statusChanged();

    if (m_status == Status::Finished) {
        emit finished();
    } else if (m_status == Status::Failed) {
        qDebug() << Q_FUNC_INFO << type() << m_error;
        emit failed(m_error);
        // Failing an output can run code that alters the graph, and can destroy
        // sibling outputs, so iterate a snapshot of guarded pointers and skip
        // whatever went away, as TaskGroup::update() does.
        QList<QPointer<Task>> outputs;
        outputs.reserve(m_outputs.size());
        for (auto task : m_outputs) outputs.append(task);
        for (auto task : outputs) {
            if (task) task->setStatus(Status::Failed);
        }
    }

    dispatch();
}

void Task::waitForFuture(QFuture<void> future)
{
    Q_D(Task);
    d->future_synchronizer.addFuture(std::move(future));
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
    add({}, task);
}

void TaskDispatcher::add(const QString& name, Task* task)
{
    auto group = new TaskGroup(this);
    group->setName(name);
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

    // Failing or updating a task can run code that destroys other tasks in this
    // group, so hold guarded pointers and skip whatever went away.
    QList<QPointer<Task>> tasks;
    tasks.reserve(m_tasks.size());
    for (auto task : m_tasks) tasks.append(task);

    for (auto task : tasks) {
        if (!task) continue;
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
            if (task) task->setStatus(Task::Status::Failed);
        }
        setStatus(Status::Failed);
        return;
    }

    if (any_active) {
        setStatus(Status::Active);
    }

    for (auto task : tasks) {
        if (!task) continue;
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

TaskGroupMonitor::TaskGroupMonitor(QObject* parent)
    : QObject(parent)
{
}

bool TaskGroupMonitor::idle() const
{
    for (auto group : m_groups) {
        if (group->status() == TaskGroup::Status::Active) {
            return false;
        }
    }
    return true;
}

QQmlListProperty<TaskGroup> TaskGroupMonitor::groups()
{
    return { this, &m_groups };
}

void TaskGroupMonitor::add(TaskGroup* group)
{
    Q_ASSERT(!m_groups.contains(group));
    m_groups.append(group);
    emit groupsChanged();
    connect(group, &TaskGroup::statusChanged, this, &TaskGroupMonitor::idleChanged);
    connect(group, &TaskGroup::finished, this, [=, this] { remove(group); });
    connect(group, &TaskGroup::failed, this, [=, this] { remove(group); });
}

void TaskGroupMonitor::remove(TaskGroup* group)
{
    if (m_groups.removeOne(group)) {
        emit groupsChanged();
        emit idleChanged();
        if (m_groups.isEmpty()) {
            emit allFinishedOrFailed();
        }
    }
}

void TaskGroupMonitor::clear()
{
    m_groups.clear();
    emit groupsChanged();
    emit idleChanged();
    emit allFinishedOrFailed();
}

SessionTask::SessionTask(Session* session)
    : SessionTask(new SessionTaskPrivate, session)
{
}

SessionTask::SessionTask(SessionTaskPrivate* d, Session* session)
    : Task(d, session)
{
    d->session = session;
}

Session* SessionTask::session() const
{
    Q_D(const SessionTask);
    return d->session;
}

QString SessionTask::description() const
{
    if (!session()) {
        return Task::description();
    }
    const auto network = session()->network();
    const QString network_id = network ? network->id() : QStringLiteral("?");
    return QStringLiteral("%1 network=%2").arg(Task::description(), network_id);
}

namespace {
    QJsonObject get_params(Session* session)
    {
        const auto network = session->network();
        const QString user_agent = QString("green_qt_%1").arg(GREEN_VERSION);
        QJsonObject params{
            { "name", network->id() },
            { "use_tor", session->useTor() },
            { "user_agent", user_agent }
        };
        if (!session->proxy().isEmpty()) {
            params.insert("proxy", session->proxy());
        }
        if (session->usePersonalNode()) {
            const auto url = session->electrumUrl().trimmed();
            if (!url.isEmpty()) {
                params.insert("electrum_url", url);
                params.insert("electrum_onion_url", url);
                params.insert("electrum_tls", session->enableElectrumTls());
            }
        }
        if (session->network()->isLiquid()) {
            params.insert("discount_fees", true);
        }
        return params;
    }
} // namespace

AuthHandlerTask::AuthHandlerTask(Session* session)
    : SessionTask(new AuthHandlerTaskPrivate, session)
{
}

AuthHandlerTask::AuthHandlerTask(AuthHandlerTaskPrivate* d, Session* session)
    : SessionTask(d, session)
{
}

void AuthHandlerTask::setResult(const QJsonObject& result)
{
    if (m_result == result) return;
    m_result = result;
    emit resultChanged();
}

void AuthHandlerTask::setPrompt(Prompt *prompt)
{
    if (m_prompt == prompt) return;
    m_prompt = prompt;
    emit promptChanged();
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

    if (!active()) return;

    setStatus(Status::Active);

    Q_D(AuthHandlerTask);
    auto future = QtConcurrent::run([=, this] {
        const auto ok = call(session()->m_session, &d->auth_handler);
        const auto error = gdk::get_thread_error_details();
        return qMakePair(ok, error);
    });

    future.then(this, [=, this](std::pair<bool, QJsonObject> result) {
        if (result.first) {
            next();
        } else {
            const auto error = result.second.value("details").toString();
            if (error == "id_you_are_not_connected") {
                setStatus(Status::Ready);
            } else {
                setError(error);
                setStatus(Status::Failed);
            }
        }
    });

    waitForFuture(future);
}

void AuthHandlerTask::requestCode(const QString &method)
{
    Q_D(AuthHandlerTask);
    auto future = QtConcurrent::run([=, this] {
        const auto rc = GA_auth_handler_request_code(d->auth_handler, method.toUtf8().constData());
        return rc == GA_OK;
    });

    future.then(this, [=, this](bool ok) {
        if (ok) {
            next();
        } else {
            setError("The action can't be completed");
            setStatus(Status::Failed);
        }
    });

    waitForFuture(future);
}

void AuthHandlerTask::resolveCode(const QByteArray& code)
{
    Q_D(AuthHandlerTask);
    auto future = QtConcurrent::run([=, this] {
        const auto rc = GA_auth_handler_resolve_code(d->auth_handler, code.constData());
        return rc == GA_OK;
    });

    future.then(this, [=, this](bool ok) {
        if (ok) {
            next();
        } else {
            setError("The action can't be completed");
            setStatus(Status::Failed);
        }
    });

    waitForFuture(future);
}

bool AuthHandlerTask::active() const
{
    return session() && session()->isConnected();
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

    if (error == "id_connection_failed") {
        session()->setConnected(false);
    }

    setResult(result);
    setError(error);
    setStatus(Status::Failed);
}

void AuthHandlerTask::handleRequestCode(const QJsonObject& result)
{
    setResult(result);
    const auto methods = result.value("methods").toArray();
    if (methods.size() == 1) {
        const auto method = methods.first().toString();
        requestCode(method);
    } else {
        setPrompt(new CodePrompt(result, this));
    }
}

void AuthHandlerTask::promptDevice(const QJsonObject& result)
{
    m_prompt = new DevicePrompt(result, this);
    emit promptChanged();
}

void AuthHandlerTask::handleResolveCode(const QJsonObject& result)
{
    if (result.contains("method")) {
        setResult(result);
        const auto method = result.value("method").toString();
        auto prompt = qobject_cast<CodePrompt*>(m_prompt);
        if (prompt) {
            if (prompt->method().isEmpty() || prompt->method() == method) {
                prompt->setResult(result);
            } else {
                setPrompt(new CodePrompt(result, this));
            }
        } else {
            setPrompt(new CodePrompt(result, this));
        }
        return;
    }

    if (result.contains("required_data")) {
        Resolver* resolver{nullptr};
        const auto device = session()->context()->device();
        const auto xpub_hash_id = session()->context()->xpubHashId();
        if (!device) return promptDevice(result);
        if (device->session() && !xpub_hash_id.isEmpty()) {
            if (device->session()->xpubHashId() != xpub_hash_id) {
                return promptDevice(result);
            }
        }
        auto network = session()->network();
        const auto required_data = result.value("required_data").toObject();
        const auto action = required_data.value("action").toString();
        if (action == "get_xpubs") {
            resolver = new GetXPubsResolver(device, result, this);
        } else if (action == "sign_message") {
            resolver = new SignMessageResolver(device, result, this);
        } else if (action == "get_blinding_public_keys") {
            resolver = new BlindingKeysResolver(device, result, this);
        } else if (action == "get_blinding_nonces") {
            resolver = new BlindingNoncesResolver(device, result, this);
        } else if (action =="sign_tx") {
            if (network->isLiquid()) {
                resolver = new SignLiquidTransactionResolver(device, result, this);
            } else {
                resolver = new SignTransactionResolver(device, result, this);
            }
        } else if (action == "get_master_blinding_key") {
            resolver = new GetMasterBlindingKeyResolver(device, result, this);
        } else if (action == "get_blinding_factors") {
            resolver = new GetBlindingFactorsResolver(device, result, this);
        } else {
            Q_UNREACHABLE();
        }
        Q_ASSERT(resolver);
        connect(resolver, &Resolver::resolved, this, [this](const QJsonObject& data) {
            setResolver(nullptr);
            resolveCode(QJsonDocument(data).toJson(QJsonDocument::Compact));
        });
        connect(resolver, &Resolver::failed, this, [this](const QString& error) {
            setResolver(nullptr);
            setError(error);
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
    Q_D(AuthHandlerTask);
    setResult(result);
    auto future = QtConcurrent::run([=, this] {
        const auto rc = GA_auth_handler_call(d->auth_handler);
        return rc == GA_OK;
    });

    future.then(this, [=, this](bool ok) {
        if (ok) {
            next();
        } else {
            setError("The action can't be completed");
            setStatus(Status::Failed);
        }
    });

    waitForFuture(future);
}

void AuthHandlerTask::next()
{
    Q_D(AuthHandlerTask);
    if (!d->auth_handler) {
        setStatus(Status::Finished);
        return;
    }

    GA_json* output;
    const auto rc = GA_auth_handler_get_status(d->auth_handler, &output);
    if (rc != GA_OK) {
        setError("The action can't be completed");
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

RegisterUserTask::RegisterUserTask(const QJsonObject& details, const QJsonObject& hw_device, Session* session)
    : AuthHandlerTask(new RegisterUserTaskPrivate, session)
{
    Q_D(RegisterUserTask);
    d->details = details;
    d->device_details = hw_device;
}

bool RegisterUserTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(RegisterUserTask);
    const auto details = Json::fromObject(d->details);
    auto device_details = Json::fromObject(d->device_details);
    const auto rc = GA_register_user(session, device_details.get(), details.get(), auth_handler);
    return rc == GA_OK;
}

void RegisterUserTask::handleDone(const QJsonObject& result)
{
    const auto xpub_hash_id = result.value("result").toObject().value("xpub_hash_id").toString();
    const auto wallet_hash_id = result.value("result").toObject().value("wallet_hash_id").toString();

    session()->setWalletHashId(wallet_hash_id);

    auto context = session()->context();
    context->setXPubHashId(xpub_hash_id);

    AuthHandlerTask::handleDone(result);
}

namespace {
QString loginTaskModeLabel(const QJsonObject& details, const QJsonObject& hw_device, Session* session)
{
    if (session && session->m_ready && details.isEmpty() && hw_device.isEmpty()) {
        return QStringLiteral("already_ready");
    }
    if (details.contains(QStringLiteral("pin"))) {
        return QStringLiteral("pin");
    }
    if (details.contains(QStringLiteral("mnemonic"))) {
        return QStringLiteral("mnemonic");
    }
    if (details.contains(QStringLiteral("username"))) {
        return QStringLiteral("username_password");
    }
    if (details.contains(QStringLiteral("slip132_extended_pubkeys"))) {
        return QStringLiteral("extended_pubkeys");
    }
    if (details.contains(QStringLiteral("core_descriptors"))) {
        return QStringLiteral("core_descriptors");
    }
    if (!hw_device.isEmpty() && details.isEmpty()) {
        return QStringLiteral("hw_device");
    }
    if (!details.isEmpty() && !hw_device.isEmpty()) {
        return QStringLiteral("details+hw_device");
    }
    if (!details.isEmpty()) {
        return QStringLiteral("details");
    }
    return QStringLiteral("default");
}
} // namespace

LoginTask::LoginTask(Session* session)
    : AuthHandlerTask(new LoginTaskPrivate, session)
{
}

LoginTask::LoginTask(const QString& pin, const QJsonObject& pin_data, Session* session)
    : AuthHandlerTask(new LoginTaskPrivate, session)
{
    Q_D(LoginTask);
    d->details = {
        { "pin", pin },
        { "pin_data", pin_data }
    };
}

LoginTask::LoginTask(const QStringList& mnemonic, const QString& password, Session* session)
    : AuthHandlerTask(new LoginTaskPrivate, session)
{
    Q_D(LoginTask);
    d->details = {
        { "mnemonic", mnemonic.join(' ') },
        { "password", password }
    };
}

LoginTask::LoginTask(const QJsonObject& hw_device, Session* session)
    : AuthHandlerTask(new LoginTaskPrivate, session)
{
    Q_D(LoginTask);
    d->hw_device = hw_device;
}

LoginTask::LoginTask(const QString& username, const QString& password, Session* session)
    : AuthHandlerTask(new LoginTaskPrivate, session)
{
    Q_D(LoginTask);
    d->details = {
        { "username", username },
        { "password", password }
    };
}

LoginTask::LoginTask(const QJsonObject& details, const QJsonObject& hw_device, Session* session)
    : AuthHandlerTask(new LoginTaskPrivate, session)
{
    Q_D(LoginTask);
    d->details = details;
    d->hw_device = hw_device;
}

QString LoginTask::description() const
{
    Q_D(const LoginTask);
    const auto mode = loginTaskModeLabel(d->details, d->hw_device, session());
    return QStringLiteral("%1 mode=%2").arg(SessionTask::description(), mode);
}

void LoginTask::update()
{
    if (session()->m_ready) {
        setStatus(Status::Finished);
    } else {
        AuthHandlerTask::update();
    }
}

bool LoginTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(LoginTask);
    auto hw_device = Json::fromObject(d->hw_device);
    auto details = Json::fromObject(d->details);
    const auto rc = GA_login_user(session, hw_device.get(), details.get(), auth_handler);
    return rc == GA_OK;
}

void LoginTask::handleDone(const QJsonObject& result)
{
    const auto xpub_hash_id = result.value("result").toObject().value("xpub_hash_id").toString();
    const auto wallet_hash_id = result.value("result").toObject().value("wallet_hash_id").toString();

    session()->m_ready = true;
    session()->setWalletHashId(wallet_hash_id);
    auto context = session()->context();
    context->setXPubHashId(xpub_hash_id);

    AuthHandlerTask::handleDone(result);
}


LoadTwoFactorConfigTask::LoadTwoFactorConfigTask(Session* session)
    : SessionTask(session)
{
}

void LoadTwoFactorConfigTask::update()
{
    if (m_status != Status::Ready) return;

    auto context = session()->context();
    const auto wallet = context->wallet();
    if (!wallet) return;

    if (qobject_cast<WatchonlyData*>(wallet->login())) {
        setStatus(Status::Finished);
        return;
    }

    if (!session()->m_ready) return;

    setStatus(Status::Active);

    auto future = QtConcurrent::run([=, this] {
        return gdk::get_twofactor_config(session()->m_session);
    });

    future.then(this, [=, this](const QJsonObject& config) {
        session()->setConfig(config);
        setStatus(Status::Finished);
    });

    waitForFuture(future);
}

LoadCurrenciesTask::LoadCurrenciesTask(Session* session)
    : SessionTask(session)
{
}

void LoadCurrenciesTask::update()
{
    if (m_status != Status::Ready) return;

    if (!session()->m_ready) return;

    setStatus(Status::Active);

    auto future = QtConcurrent::run([=, this] {
        return gdk::get_available_currencies(session()->m_session);
    });

    future.then(this, [=, this](const QJsonObject& currencies) {
        session()->setCurrencies(currencies);
        setStatus(Status::Finished);
    });

    waitForFuture(future);
}

LoadAccountTask::LoadAccountTask(uint32_t pointer, Session* session)
    : AuthHandlerTask(new LoadAccountTaskPrivate, session)
{
    Q_D(LoadAccountTask);
    d->pointer = pointer;
}

Account* LoadAccountTask::account() const
{
    Q_D(const LoadAccountTask);
    return d->account;
}

QString LoadAccountTask::description() const
{
    Q_D(const LoadAccountTask);
    return QStringLiteral("%1 pointer=%2").arg(SessionTask::description()).arg(d->pointer);
}

bool LoadAccountTask::active() const
{
    return AuthHandlerTask::active() && session()->m_ready;
}

bool LoadAccountTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(LoadAccountTask);
    int res = GA_get_subaccount(session, d->pointer, auth_handler);
    return res == GA_OK;
}

void LoadAccountTask::handleDone(const QJsonObject& result)
{
    Q_D(LoadAccountTask);
    const auto data = result.value("result").toObject();
    auto context = session()->context();
    auto network = session()->network();
    d->account = context->getOrCreateAccount(network, data);
    setStatus(Status::Finished);
}

bool ShouldRefresh(Session* session)
{
    // skip non electrum sessions
    if (!session->network()->isElectrum()) return false;
    if (session->context()->isWatchonly()) return false;
    // check if state directory exists
    QDir dir(GetDataDir("gdk"));
    if (!dir.cd("state")) return true;
    if (!dir.cd(session->m_wallet_hash_id)) return true;
    // check directory timestamp, force refresh if its recent
    QFileInfo info(dir.absolutePath());
    if (info.birthTime().isValid() && info.birthTime().secsTo(QDateTime::currentDateTime()) < 30) return true;
    return false;
}

LoadAccountsTask::LoadAccountsTask(bool refresh, Session* session)
    : AuthHandlerTask(new LoadAccountsTaskPrivate, session)
{
    Q_D(LoadAccountsTask);
    d->refresh = refresh || ShouldRefresh(session);
}

QList<Account*> LoadAccountsTask::accounts() const
{
    Q_D(const LoadAccountsTask);
    return d->accounts;
}

QString LoadAccountsTask::description() const
{
    Q_D(const LoadAccountsTask);
    return QStringLiteral("%1 refresh=%2").arg(SessionTask::description(), d->refresh ? QStringLiteral("true") : QStringLiteral("false"));
}

bool LoadAccountsTask::active() const
{
    return AuthHandlerTask::active() && session()->m_ready;
}

bool LoadAccountsTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(LoadAccountsTask);
    auto details = Json::fromObject({{ "refresh", d->refresh }});
    int res = GA_get_subaccounts(session, details.get(), auth_handler);
    return res == GA_OK;
}

void LoadAccountsTask::handleDone(const QJsonObject& result)
{
    Q_D(LoadAccountsTask);
    const auto subaccounts = result.value("result").toObject().value("subaccounts").toArray();
    auto context = session()->context();
    auto network = session()->network();
    for (auto value : subaccounts) {
        d->accounts.append(context->getOrCreateAccount(network, value.toObject()));
    }
    setStatus(Status::Finished);
}

SyncAccountsTask::SyncAccountsTask(Session* session)
    : SessionTask(session)
{
}

QString SyncAccountsTask::description() const
{
    return QStringLiteral("%1 phase=account_sync").arg(SessionTask::description());
}

void SyncAccountsTask::update()
{
    if (m_status == Status::Ready) {
        setStatus(Status::Active);
    }

    if (m_status == Status::Active) {
        for (auto account : session()->context()->getAccounts()) {
            if (account->session() != session()) continue;
            // AMP2 accounts are lwk-backed and never receive a gdk sync event.
            if (account->isAmp2()) continue;
            if (!account->synced()) return;
        }
        setStatus(Status::Finished);
    }
}

LoadBalanceTask::LoadBalanceTask(Account* account)
    : AuthHandlerTask(new LoadBalanceTaskPrivate, account->session())
{
    Q_D(LoadBalanceTask);
    d->account = account;
}

QString LoadBalanceTask::description() const
{
    Q_D(const LoadBalanceTask);
    return QStringLiteral("%1 subaccount=%2")
        .arg(SessionTask::description())
        .arg(d->account ? static_cast<int>(d->account->pointer()) : -1);
}

bool LoadBalanceTask::active() const
{
    return AuthHandlerTask::active() && session()->m_ready;
}

bool LoadBalanceTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(LoadBalanceTask);
    auto details = Json::fromObject({
        { "subaccount", static_cast<qint64>(d->account->pointer()) },
        { "num_confs", 0 }
    });

    int err = GA_get_balance(session, details.get(), auth_handler);
    return err == GA_OK;
}

void LoadBalanceTask::handleDone(const QJsonObject& result)
{
    Q_D(LoadBalanceTask);
    const auto data = result.value("result").toObject();
    d->account->setBalanceData(data);
    setStatus(Status::Finished);
}

GetWatchOnlyDetailsTask::GetWatchOnlyDetailsTask(Session* session)
    : SessionTask(session)
{
}

void GetWatchOnlyDetailsTask::update()
{
    if (m_status != Status::Ready) return;

    const auto wallet = session()->context()->wallet();
    if (!wallet) return;
    if (qobject_cast<WatchonlyData*>(wallet->login())) {
        setStatus(Status::Finished);
        return;
    }

    if (!session()->m_ready) return;

    setStatus(Status::Active);

    auto future = QtConcurrent::run([=, this] {
        char* data;
        const auto rc = GA_get_watch_only_username(session()->m_session, &data);
        if (rc != GA_OK) return QString();
        const auto username = QString::fromUtf8(data);
        GA_destroy_string(data);
        return username;
    });

    future.then(this, [=, this](QString username) {
        if (username.isNull()) {
            setStatus(Status::Failed);
        } else {
            session()->setUsername(username);
            setStatus(Status::Finished);
        }
    });

    waitForFuture(future);
}

LoadAssetsTask::LoadAssetsTask(bool refresh, Session* session)
    : SessionTask(new LoadAssetsTaskPrivate, session)
{
    Q_D(LoadAssetsTask);
    d->refresh = refresh;
}

QString LoadAssetsTask::description() const
{
    Q_D(const LoadAssetsTask);
    return QStringLiteral("%1 refresh=%2").arg(SessionTask::description(), d->refresh ? QStringLiteral("true") : QStringLiteral("false"));
}

void LoadAssetsTask::update()
{
    Q_D(LoadAssetsTask);
    if (m_status != Status::Ready) return;

    if (!session()->network()->isLiquid()) {
        setStatus(Status::Finished);
        return;
    }

    setStatus(Status::Active);

    auto future = QtConcurrent::run([=, this] {
        if (d->refresh) {
            const auto params = Json::fromObject({{ "assets", true }, { "icons", true }});
            const auto rc = GA_refresh_assets(session()->m_session, params.get());
            qDebug() << Q_FUNC_INFO << "REFRESH" << rc;
            if (rc != GA_OK) return false;
        }

        GA_json* output;

        {
            const auto params = Json::fromObject({{ "category", "all" }});
            const auto err = GA_get_assets(session()->m_session, params.get(), &output);
            qDebug() << Q_FUNC_INFO << "GET" << err;
            if (err != GA_OK) return false;
        }

        const auto result = Json::toObject(output);
        const auto assets = result.value("assets").toObject();
        const auto icons = result.value("icons").toObject();
        for (auto i = assets.begin(); i != assets.end(); i++) {
            const auto asset_id = i.key();
            const auto data = i.value().toObject();
            const auto icon = icons.value(asset_id);
            QMetaObject::invokeMethod(session(), [=, this] {
                auto context = session()->context();
                if (!context) return;
                auto asset = context->getOrCreateAsset(asset_id);
                asset->setData(data);
                if (!icon.isNull() && !icon.toString().isEmpty()) {
                    asset->setIcon(QString("data:image/png;base64,") + icon.toString());
                }
            }, Qt::QueuedConnection);
        }
        GA_destroy_json((GA_json*) output);

        return true;
    });

    future.then(this, [=, this](bool ok) {
        setStatus(ok ? Status::Finished : Status::Failed);
    });

    waitForFuture(future);
}

EncryptWithPinTask::EncryptWithPinTask(const QString& pin, Session* session)
    : AuthHandlerTask(new EncryptWithPinTaskPrivate, session)
{
    Q_D(EncryptWithPinTask);
    d->pin = pin;
}

EncryptWithPinTask::EncryptWithPinTask(const QJsonValue& plaintext, const QString& pin, Session* session)
    : AuthHandlerTask(new EncryptWithPinTaskPrivate, session)
{
    Q_D(EncryptWithPinTask);
    d->plaintext = plaintext;
    d->pin = pin;
}

void EncryptWithPinTask::setPlaintext(const QJsonValue& plaintext)
{
    Q_D(EncryptWithPinTask);
    if (d->plaintext == plaintext) return;
    d->plaintext = plaintext;
    dispatch();
}

bool EncryptWithPinTask::active() const
{
    Q_D(const EncryptWithPinTask);
    if (!AuthHandlerTask::active()) return false;
    if (d->plaintext.isNull() || d->plaintext.isUndefined()) return false;
    return true;
}

bool EncryptWithPinTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(EncryptWithPinTask);
    const QJsonObject details({
        { "pin", d->pin },
        { "plaintext", d->plaintext }
    });
    const auto rc = GA_encrypt_with_pin(session, Json::fromObject(details).get(), auth_handler);
    return rc == GA_OK;
}

CreateAccountTask::CreateAccountTask(const QJsonObject& details, Session* session)
    : AuthHandlerTask(new CreateAccountTaskPrivate, session)
{
    Q_D(CreateAccountTask);
    d->details = details;
}

quint32 CreateAccountTask::pointer() const
{
    Q_D(const CreateAccountTask);
    return d->pointer;
}

bool CreateAccountTask::active() const
{
    return AuthHandlerTask::active() && session()->m_ready;
}

bool CreateAccountTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    Q_D(CreateAccountTask);
    const auto rc = GA_create_subaccount(session, Json::fromObject(d->details).get(), auth_handler);
    return rc == GA_OK;
}

void CreateAccountTask::handleDone(const QJsonObject &result)
{
    Q_D(CreateAccountTask);
    d->pointer = result.value("result").toObject().value("pointer").toInteger();
    setStatus(Status::Finished);
}

UpdateAccountTask::UpdateAccountTask(const QJsonObject &details, Session* session)
    : AuthHandlerTask(new UpdateAccountTaskPrivate, session)
{
    Q_D(UpdateAccountTask);
    d->details = details;
}

bool UpdateAccountTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(UpdateAccountTask);
    const auto rc = GA_update_subaccount(session, Json::fromObject(d->details).get(), auth_handler);
    return rc == GA_OK;
}

ValidateTask::ValidateTask(const QJsonObject &details, Session* session)
    : AuthHandlerTask(new ValidateTaskPrivate, session)
{
    Q_D(ValidateTask);
    d->details = details;
}

bool ValidateTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    Q_D(ValidateTask);
    const auto rc = GA_validate(session, Json::fromObject(d->details).get(), auth_handler);
    return rc == GA_OK;
}

ChangeTwoFactorTask::ChangeTwoFactorTask(const QString& method, const QJsonObject& details, Session* session)
    : AuthHandlerTask(new ChangeTwoFactorTaskPrivate, session)
{
    Q_D(ChangeTwoFactorTask);
    d->method = method;
    d->details = details;
}

bool ChangeTwoFactorTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(ChangeTwoFactorTask);
    const auto details = Json::fromObject(d->details);
    const auto rc = GA_change_settings_twofactor(session, d->method.toUtf8().constData(), details.get(), auth_handler);
    return rc == GA_OK;
}

ContextTask::ContextTask(Context* context)
    : ContextTask(new ContextTaskPrivate, context)
{
}

ContextTask::ContextTask(ContextTaskPrivate* d, Context* context)
    : Task(d, context)
{
    Q_ASSERT(context);
    d->context = context;
}

Context* ContextTask::context() const
{
    Q_D(const ContextTask);
    return d->context;
}

QString ContextTask::description() const
{
    if (!context()) {
        return Task::description();
    }
    const QString base = Task::description();
    const QString xpub = context()->xpubHashId();
    if (xpub.size() >= 8) {
        return QStringLiteral("%1 xpub_prefix=%2").arg(base, xpub.left(8));
    }
    return QStringLiteral("%1 (no xpub yet)").arg(base);
}

TwoFactorResetTask::TwoFactorResetTask(const QString& email, bool dispute, Session* session)
    : AuthHandlerTask(new TwoFactorResetTaskPrivate, session)
{
    Q_D(TwoFactorResetTask);
    d->email = email;
    d->dispute = dispute;
}

QString TwoFactorResetTask::email() const
{
    Q_D(const TwoFactorResetTask);
    return d->email;
}

bool TwoFactorResetTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(TwoFactorResetTask);
    const auto rc = GA_twofactor_reset(session, d->email.toUtf8().constData(), d->dispute, auth_handler);
    return rc == GA_OK;
}

TwoFactorUndoResetTask::TwoFactorUndoResetTask(const QString& email, Session* session)
    : AuthHandlerTask(new TwoFactorUndoResetTaskPrivate, session)
{
    Q_D(TwoFactorUndoResetTask);
    d->email = email;
}

QString TwoFactorUndoResetTask::email() const
{
    Q_D(const TwoFactorUndoResetTask);
    return d->email;
}

bool TwoFactorUndoResetTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(TwoFactorUndoResetTask);
    const auto rc = GA_twofactor_undo_reset(session, d->email.toUtf8().constData(), auth_handler);
    return rc == GA_OK;
}

SetCsvTimeTask::SetCsvTimeTask(const int value, Session* session)
    : AuthHandlerTask(new SetCsvTimeTaskPrivate, session)
{
    Q_D(SetCsvTimeTask);
    d->value = value;
}

bool SetCsvTimeTask::call(GA_session* session, GA_auth_handler** auth_handler) {
    Q_D(SetCsvTimeTask);
    auto details = Json::fromObject({{ "value", d->value }});
    const auto rc = GA_set_csvtime(session, details.get(), auth_handler);
    return rc == GA_OK;
}

void SetCsvTimeTask::handleDone(const QJsonObject &result)
{
    auto settings = gdk::get_settings(session()->m_session);
    session()->setSettings(settings);
    AuthHandlerTask::handleDone(result);
}

GetCredentialsTask::GetCredentialsTask(Session* session)
    : AuthHandlerTask(session)
{
}

QString GetCredentialsTask::description() const
{
    return QStringLiteral("%1 phase=post_login_credentials").arg(SessionTask::description());
}

bool GetCredentialsTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    const auto details = Json::fromObject({{ "password", "" }});
    const auto rc = GA_get_credentials(session, details.get(), auth_handler);
    return rc == GA_OK;
}

bool GetCredentialsTask::active() const
{
    return AuthHandlerTask::active() && session()->m_ready;
}

void GetCredentialsTask::handleDone(const QJsonObject& result)
{
    const auto credentials = result.value("result").toObject();
    session()->context()->setCredentials(credentials);
    AuthHandlerTask::handleDone(result);
}

ChangeSettingsTask::ChangeSettingsTask(const QJsonObject& data, Session* session)
    : AuthHandlerTask(new ChangeSettingsTaskPrivate, session)
{
    Q_D(ChangeSettingsTask);
    d->data = data;
}

bool ChangeSettingsTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(ChangeSettingsTask);
    const auto rc = GA_change_settings(session, Json::fromObject(d->data).get(), auth_handler);
    return rc == GA_OK;
}

void ChangeSettingsTask::handleDone(const QJsonObject& result)
{
    auto settings = gdk::get_settings(session()->m_session);
    if (!settings.isEmpty()) session()->setSettings(settings);
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

TwoFactorChangeLimitsTask::TwoFactorChangeLimitsTask(const QJsonObject& details, Session* session)
    : AuthHandlerTask(new TwoFactorChangeLimitsTaskPrivate, session)
{
    Q_D(TwoFactorChangeLimitsTask);
    d->details = details;
}

bool TwoFactorChangeLimitsTask::call(GA_session *session, GA_auth_handler **auth_handler) {
    Q_D(TwoFactorChangeLimitsTask);
    const auto details = Json::fromObject(d->details);
    const auto rc = GA_twofactor_change_limits(session, details.get(), auth_handler);
    return rc == GA_OK;
}

CreateTransactionTask::CreateTransactionTask(const QJsonObject &details, Session* session)
    : AuthHandlerTask(new CreateTransactionTaskPrivate, session)
{
    Q_D(CreateTransactionTask);
    d->details = details;
}

bool CreateTransactionTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    Q_D(CreateTransactionTask);
    const auto rc = GA_create_transaction(session, Json::fromObject(d->details).get(), auth_handler);
    return rc == GA_OK;
}

QJsonObject CreateTransactionTask::transaction() const
{
    return m_result.value("result").toObject();
}

CreateRedepositTransactionTask::CreateRedepositTransactionTask(const QJsonObject &details, Session* session)
    : AuthHandlerTask(new CreateRedepositTransactionTaskPrivate, session)
{
    Q_D(CreateRedepositTransactionTask);
    d->details = details;
}

bool CreateRedepositTransactionTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    Q_D(CreateRedepositTransactionTask);
    const auto rc = GA_create_redeposit_transaction(session, Json::fromObject(d->details).get(), auth_handler);
    return rc == GA_OK;
}

QJsonObject CreateRedepositTransactionTask::transaction() const
{
    return m_result.value("result").toObject();
}

SendNLocktimesTask::SendNLocktimesTask(Session* session)
    : SessionTask(session)
{
}

void SendNLocktimesTask::update()
{
    if (m_status != Status::Ready) return;

    if (!session()->m_ready) return;

    setStatus(Status::Active);

    auto future = QtConcurrent::run([=, this] {
        const auto rc = GA_send_nlocktimes(session()->m_session);
        if (rc == GA_OK) {
            return qMakePair(true, gdk::get_settings(session()->m_session));
        } else {
            return qMakePair(false, gdk::get_thread_error_details());
        }
    });

    future.then(this, [=, this](QPair<bool, QJsonObject> result) {
        if (result.first) {
            session()->setSettings(result.second);
            setStatus(Status::Finished);
        } else {
            setError(result.second.value("details").toString());
            setStatus(Status::Failed);
        }
    });

    waitForFuture(future);
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

void TaskGroup::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged();
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
    : AuthHandlerTask(new SignTransactionTaskPrivate, session)
{
}

QJsonObject SignTransactionTask::details() const
{
    Q_D(const SignTransactionTask);
    return d->details;
}

void SignTransactionTask::setDetails(const QJsonObject& details)
{
    Q_D(SignTransactionTask);
    if (d->details == details) return;
    d->details = details;
    emit detailsChanged();
}

bool SignTransactionTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(SignTransactionTask);
    auto details = Json::fromObject(d->details);
    const auto rc = GA_sign_transaction(session, details.get(), auth_handler);
    return rc == GA_OK;
}

SendTransactionTask::SendTransactionTask(Session* session)
    : AuthHandlerTask(new SendTransactionTaskPrivate, session)
{
}

void SendTransactionTask::update()
{
    Q_D(SendTransactionTask);
    const bool mock_send = qApp->arguments().contains("--mock-send");
    if (mock_send) {
        qDebug() << Q_FUNC_INFO << "inputs";
        const auto inputs = d->details.value("transaction_inputs").toArray();
        for (const auto value : inputs) {
            const auto input = value.toObject();
            qDebug()
                << input.value("txhash").toString()
                << input.value("pt_idx").toInt()
                << input.value("asset_id").toString()
                << input.value("satoshi").toInteger();
        }
        qDebug() << Q_FUNC_INFO << "outputs";
        const auto outputs = d->details.value("transaction_outputs").toArray();
        for (const auto value : outputs) {
            const auto output = value.toObject();
            qDebug()
                << output.value("address").toString()
                << output.value("asset_id").toString()
                << output.value("satoshi").toInteger();
        }
        setStatus(Status::Active);
        setStatus(Status::Finished);
    } else {
        AuthHandlerTask::update();
    }
}

void SendTransactionTask::setDetails(const QJsonObject &details)
{
    Q_D(SendTransactionTask);
    d->details = details;
}

QJsonObject SendTransactionTask::transaction() const
{
    Q_D(const SendTransactionTask);
    QJsonObject transaction;

    const bool mock_send = qApp->arguments().contains("--mock-send");
    if (mock_send) {
        transaction = d->details;
    } else {
        Q_ASSERT(m_result.value("status") == "done");
        transaction = m_result.value("result").toObject();
    }
    transaction.insert("inputs", d->details.value("transaction_inputs"));

    return transaction;
}

bool SendTransactionTask::active() const
{
    Q_D(const SendTransactionTask);
    if (d->details.isEmpty()) return false;
    return AuthHandlerTask::active();
}

bool SendTransactionTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(SendTransactionTask);
    auto details = Json::fromObject(d->details);
    const auto rc = GA_send_transaction(session, details.get(), auth_handler);
    return rc == GA_OK;
}

GetUnspentOutputsTask::GetUnspentOutputsTask(int num_confs, bool all_coins, Account* account)
    : AuthHandlerTask(new GetUnspentOutputsTaskPrivate, account->session())
{
    Q_D(GetUnspentOutputsTask);
    d->subaccount = account->pointer();
    d->num_confs = num_confs;
    d->all_coins = all_coins;
}

void GetUnspentOutputsTask::setExpiredAt(uint32_t expired_at)
{
    Q_D(GetUnspentOutputsTask);
    d->expired_at = expired_at;
}

QJsonObject GetUnspentOutputsTask::unspentOutputs() const
{
    return result().value("result").toObject().value("unspent_outputs").toObject();
}

bool GetUnspentOutputsTask::active() const
{
    return AuthHandlerTask::active() && session()->m_ready;
}

bool GetUnspentOutputsTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    Q_D(GetUnspentOutputsTask);
    auto details = QJsonObject{
        { "subaccount", d->subaccount },
        { "num_confs", d->num_confs },
        { "all_coins", d->all_coins }
    };
    if (d->expired_at > 0) {
        details["expired_at"] = qint64(d->expired_at);
    }

    const auto rc = GA_get_unspent_outputs(session, Json::fromObject(details).get(), auth_handler);
    return rc == GA_OK;
}

GetTransactionsTask::GetTransactionsTask(int first, int count, Account* account)
    : AuthHandlerTask(new GetTransactionsTaskPrivate, account->session())
{
    Q_D(GetTransactionsTask);
    d->subaccount = account->pointer();
    d->first = first;
    d->count = count;
}

bool GetTransactionsTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(GetTransactionsTask);
    auto details = Json::fromObject({
        { "subaccount", d->subaccount },
        { "first", d->first },
        { "count", d->count }
    });

    const auto rc = GA_get_transactions(session, details.get(), auth_handler);
    return rc == GA_OK;
}

QJsonArray GetTransactionsTask::transactions() const
{
    return result().value("result").toObject().value("transactions").toArray();
}

GetReceiveAddressTask::GetReceiveAddressTask(Account *account)
    : AuthHandlerTask(new GetReceiveAddressTaskPrivate, account->session())
{
    Q_D(GetReceiveAddressTask);
    d->account = account;
}

bool GetReceiveAddressTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    Q_D(GetReceiveAddressTask);
    const auto address_details = Json::fromObject({
        { "subaccount", static_cast<qint64>(d->account->pointer()) },
    });

    const auto rc = GA_get_receive_address(session, address_details.get(), auth_handler);
    return rc == GA_OK;
}

GetAddressesTask::GetAddressesTask(int last_pointer, Account* account)
    : AuthHandlerTask(new GetAddressesTaskPrivate, account->session())
{
    Q_D(GetAddressesTask);
    d->subaccount = account->pointer();
    d->last_pointer = last_pointer;
}

bool GetAddressesTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    Q_D(GetAddressesTask);
    QJsonObject _details({{ "subaccount", d->subaccount }});
    if (d->last_pointer != 0) _details["last_pointer"] = d->last_pointer;
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
    return result().value("result").toObject().value("last_pointer").toInt(-1);
}

bool GetAddressesTask::hasMore() const
{
    return result().value("result").toObject().contains("last_pointer");
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
    : AuthHandlerTask(new SetUnspentOutputsStatusTaskPrivate, session)
{
    Q_D(SetUnspentOutputsStatusTask);
    d->outputs = outputs;
    d->status = status;
}

bool SetUnspentOutputsStatusTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    Q_D(SetUnspentOutputsStatusTask);
    QJsonArray list;
    for (const auto& variant : d->outputs)
    {
        auto output = variant.value<Output*>();
        QJsonObject o;
        o["txhash"] = output->data()["txhash"].toString();
        o["pt_idx"] = output->data()["pt_idx"].toInt();
        o["user_status"] = d->status;
        list.append(o);
    }
    auto details = Json::fromObject({
        { "list", list }
    });

    const auto rc = GA_set_unspent_outputs_status(session, details.get(), auth_handler);
    return rc == GA_OK;
}

ConnectTask::ConnectTask(Session* session)
    : SessionTask(new ConnectTaskPrivate, session)
{
    Q_D(ConnectTask);
    d->timeout = 60000;
}

ConnectTask::ConnectTask(int timeout, Session *session)
    : SessionTask(new ConnectTaskPrivate, session)
{
    Q_D(ConnectTask);
    d->timeout = timeout;
}

QString ConnectTask::description() const
{
    Q_D(const ConnectTask);
    return QStringLiteral("%1 timeout_ms=%2").arg(SessionTask::description()).arg(d->timeout);
}

void ConnectTask::update()
{
    Q_D(ConnectTask);
    if (m_status == Status::Ready) {
        if (session()->useTor() && !session()->useProxy()) {
            auto tor_session = SessionManager::instance()->torSession();
            if (tor_session != session()) {
                const auto tag = tor_session->events().value("tor").toObject().value("tag").toString();
                if (tag != "done") {
                    qDebug() << Q_FUNC_INFO << session()->network()->id() << "wait for tor session";
                    return;
                }
            }
        }

        setStatus(Status::Active);

        if (session()->isConnected()) {
            setStatus(Status::Finished);
            return;
        }

        if (d->timeout > 0) {
            QTimer::singleShot(d->timeout, this, [=, this] {
                if (m_status == Status::Active && !session()->isConnected()) {
                    qDebug() << Q_FUNC_INFO << session()->network()->id() << "timeout after" << d->timeout;
                    setError("timeout error");
                    setStatus(Status::Failed);
                }
            });
        }

        auto future = QtConcurrent::run([=, this] {
            const auto params = get_params(session());
            const auto rc = GA_connect(session()->m_session, Json::fromObject(params).get());
            if (rc == GA_OK) return QString();
            const auto error = gdk::get_thread_error_details();
            return error.value("details").toString();
        });

        future.then(this, [=, this](QString error) {
            if (m_status != Status::Active) return;
            if (error.contains("session already connected")) {
                setStatus(Status::Finished);
                return;
            }
            setError(error);
            if (!error.isEmpty()) {
                setStatus(Status::Failed);
            }
        });

        waitForFuture(future);
    } else if (m_status == Status::Active) {
        if (session()->isConnected()) {
            setStatus(Status::Finished);
        }
    }
}

BlindTransactionTask::BlindTransactionTask(const QJsonObject& details, Session* session)
    : AuthHandlerTask(new BlindTransactionTaskPrivate, session)
{
    Q_D(BlindTransactionTask);
    d->details = details;
}

bool BlindTransactionTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(BlindTransactionTask);
    const auto rc = GA_blind_transaction(session, Json::fromObject(d->details).get(), auth_handler);
    return rc == GA_OK;
}

SignMessageTask::SignMessageTask(const QString &message, Address* address)
    : AuthHandlerTask(new SignMessageTaskPrivate, address->account()->session())
{
    Q_D(SignMessageTask);
    d->address = address;
    d->message = message;
}

QString SignMessageTask::signature() const
{
    return m_result.value("result").toObject().value("signature").toString();
}

bool SignMessageTask::call(GA_session* session, GA_auth_handler** call)
{
    Q_D(SignMessageTask);
    const auto address = d->address->data().value("address").toString();
    QJsonObject details{
        { "address", address },
        { "message", d->message }
    };
    const auto rc = GA_sign_message(session, Json::fromObject(details).get(), call);
    return rc == GA_OK;
}

Prompt::Prompt(Task* task)
    : QObject(task)
{
}

CodePrompt::CodePrompt(const QJsonObject& result, AuthHandlerTask* task)
    : Prompt(task)
    , m_task(task)
    , m_result(result)
{
}

void CodePrompt::setResult(const QJsonObject& result)
{
    m_result = result;
    emit resultChanged();
    if (m_attempts > 0) {
        emit invalidCode();
    }
}

void CodePrompt::select(const QString& method)
{
    m_task->requestCode(method);
}

void CodePrompt::resolve(const QString& code)
{
    m_attempts ++;
    m_task->resolveCode(code.toUtf8());
}

DevicePrompt::DevicePrompt(const QJsonObject& result, AuthHandlerTask* task)
    : Prompt(task)
    , m_task(task)
    , m_result(result)
{
}

void DevicePrompt::select(Device* device)
{
    if (device->session() && device->session()->xpubHashId() == m_task->session()->context()->xpubHashId()) {
        m_task->session()->context()->setDevice(device);
        m_task->handleResolveCode(m_result);
    }
}


GetSystemMessageTask::GetSystemMessageTask(Session* session)
    : SessionTask(new GetSystemMessageTaskPrivate, session)
{
}

QString GetSystemMessageTask::message() const
{
    Q_D(const GetSystemMessageTask);
    return d->message;
}

void GetSystemMessageTask::update()
{
    Q_D(GetSystemMessageTask);
    if (status() != Status::Ready) return;

    if (!session()->m_ready) return;

    setStatus(Status::Active);

    auto future = QtConcurrent::run([=, this] {
        char* message_text;
        const auto rc = GA_get_system_message(session()->m_session, &message_text);
        if (rc != GA_OK) {
            const auto error = gdk::get_thread_error_details();
            return qMakePair(false, QString());
        }

        const auto message = QString::fromUtf8(message_text);
        GA_destroy_string(message_text);

        return qMakePair(true, message);
    });

    future.then(this, [=, this](QPair<bool, QString> result) {
        if (result.first) {
            d->message = result.second;
            setStatus(Status::Finished);
        } else {
            setStatus(Status::Failed);
        }
    });

    waitForFuture(future);
}

AckSystemMessageTask::AckSystemMessageTask(const QString& message, Session* session)
    : AuthHandlerTask(new AckSystemMessageTaskPrivate, session)
{
    Q_D(AckSystemMessageTask);
    d->message = message;
}

bool AckSystemMessageTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(AckSystemMessageTask);
    const auto rc = GA_ack_system_message(session, d->message.toUtf8().constData(), auth_handler);
    return rc == GA_OK;
}

HttpRequestTask::HttpRequestTask(const QJsonObject& params, Session* session)
    : SessionTask(new HttpRequestTaskPrivate, session)
{
    Q_D(HttpRequestTask);
    d->params = params;
}

QJsonObject HttpRequestTask::response() const
{
    Q_D(const HttpRequestTask);
    return d->response;
}

void HttpRequestTask::update()
{
    Q_D(HttpRequestTask);
    if (status() != Status::Ready) return;

    if (!session()->isConnected()) return;

    setStatus(Status::Active);

    auto future = QtConcurrent::run([=, this] {
        GA_json* output;
        const auto params = Json::fromObject(d->params);
        const auto rc = GA_http_request(session()->m_session, params.get(), &output);
        if (rc == GA_OK) {
            auto res = Json::toObject(output);
            GA_destroy_json(output);
            return qMakePair(true, res);
        } else {
            return qMakePair(false, QJsonObject{});
        }
    });

    future.then(this, [=, this](QPair<bool, QJsonObject> result) {
        if (result.first) {
            d->response = result.second;
            setStatus(Status::Finished);
        } else {
            setStatus(Status::Failed);
        }
    });

    waitForFuture(future);
}

DecodeBCURTask::DecodeBCURTask(const QString& part, Session* session)
    : AuthHandlerTask(new DecodeBCURTaskPrivate, session)
{
    Q_D(DecodeBCURTask);
    d->part = part;
}

QJsonObject DecodeBCURTask::decodedResult() const
{
    return m_result.value("result").toObject();
}

bool DecodeBCURTask::call(GA_session *session, GA_auth_handler **auth_handler)
{
    Q_D(DecodeBCURTask);
    const QJsonObject details{
        { "part", d->part },
        { "return_raw_data", false }
    };
    const auto rc = GA_bcur_decode(session, Json::fromObject(details).get(), auth_handler);
    return rc == GA_OK;
}

EncodeBCURTask::EncodeBCURTask(const QJsonObject& details, Session* session)
    : AuthHandlerTask(new EncodeBCURTaskPrivate, session)
{
    Q_D(EncodeBCURTask);
    d->details = details;
}

bool EncodeBCURTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(EncodeBCURTask);
    const auto rc = GA_bcur_encode(session, Json::fromObject(d->details).get(), auth_handler);
    return rc == GA_OK;
}

PsbtFromJsonTask::PsbtFromJsonTask(const QJsonObject& details, Session* session)
    : AuthHandlerTask(session)
    , m_details(details)
{
}

QString PsbtFromJsonTask::psbt() const
{
    return m_result.value("result").toObject().value("psbt").toString();
}

bool PsbtFromJsonTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    const auto rc = GA_psbt_from_json(session, Json::fromObject(m_details).get(), auth_handler);
    return rc == GA_OK;
}

BroadcastTransactionTask::BroadcastTransactionTask(const QJsonObject& details, Session* session)
    : AuthHandlerTask(session)
    , m_details(details)
{
}

QJsonObject BroadcastTransactionTask::transaction() const
{
    return m_result.value("result").toObject();
}

bool BroadcastTransactionTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    const auto rc = GA_broadcast_transaction(session, Json::fromObject(m_details).get(), auth_handler);
    return rc == GA_OK;
}

RSAVerifyTask::RSAVerifyTask(const QString& pem, const QByteArray& challenge, const QByteArray& signature, Session* session)
    : RSAVerifyTask({
        { "pem", pem },
        { "challenge", QString::fromLatin1(challenge.toHex()) },
        { "signature", QString::fromLatin1(signature.toHex()) }
    }, session)
{
}

RSAVerifyTask::RSAVerifyTask(const QJsonObject& details, Session* session)
    : AuthHandlerTask(new RSAVerifyTaskPrivate, session)
{
    Q_D(RSAVerifyTask);
    d->details = details;
}

bool RSAVerifyTask::call(GA_session* session, GA_auth_handler** auth_handler)
{
    Q_D(RSAVerifyTask);
    const auto rc = GA_rsa_verify(session, Json::fromObject(d->details).get(), auth_handler);
    return rc == GA_OK;
}

LoadPaymentsTask::LoadPaymentsTask(QNetworkAccessManager *net, Context *context)
    : ContextTask(new LoadPaymentsTaskPrivate, context)
{
    Q_D(LoadPaymentsTask);
    d->net = net;
}

void LoadPaymentsTask::update()
{
    if (m_status != Status::Ready) return;
    setStatus(Status::Active);
    fetch({});
}

void LoadPaymentsTask::fetch(const QString &key) {
    Q_D(LoadPaymentsTask);
    QUrl url("https://ramps.blockstream.com/payments/transactions");
    QUrlQuery query;
    query.addQueryItem("externalCustomerIds", context()->xpubHashId());
    if (!key.isEmpty()) query.addQueryItem("after", key);
    url.setQuery(query);

    QNetworkRequest req(url);
    auto reply = d->net->get(req);
    connect(reply, &QNetworkReply::finished, this, [=, this] {
        reply->deleteLater();

        if (reply->error() == QNetworkReply::NoError) {
            const auto doc = QJsonDocument::fromJson(reply->readAll());

            if (doc.isObject()) {
                const auto response = doc.object();

                const auto count = response.value("count").toInt();
                const auto remaining = response.value("remaining").toInt();
                const auto total_count = response.value("totalCount").toInt();
                QString after = key;

                const auto transactions = response.value("transactions").toArray();

                for (const auto value : transactions) {
                    auto data = value.toObject();
                    after = data.take("key").toString();

                    const auto id = data.value("id").toString();
                    auto payment = context()->getOrCreatePayment(id);
                    payment->update(data);
                }

                if (remaining > 0) {
                    fetch(after);
                    return;
                }
            }
        }

        setStatus(Status::Finished);
    });
}
