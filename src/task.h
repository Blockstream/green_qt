#ifndef GREEN_TASK_H
#define GREEN_TASK_H

#include "green.h"

#include <QElapsedTimer>
#include <QFuture>
#include <QJsonObject>
#include <QList>
#include <QObject>
#include <QQmlEngine>
#include <QQmlListProperty>
#include <QSet>

class TaskDispatcher : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<TaskGroup> groups READ groups NOTIFY groupsChanged)
    Q_PROPERTY(bool busy READ isBusy NOTIFY busyChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    TaskDispatcher(QObject* parent);
    ~TaskDispatcher();

    void add(Task* task);
    void add(const QString& name, Task* task);
    void add(TaskGroup* group);
    void remove(TaskGroup* group);

    bool isBusy() const { return m_busy; }
    void setBusy(bool busy);
    void updateBusy();

    QQmlListProperty<TaskGroup> groups();

public slots:
    void dispatch();

signals:
    void busyChanged();
    void groupsChanged();

private:
    void remove(Task* task);
    void update();
protected:
    void timerEvent(QTimerEvent* event) override;

private:
    QList<TaskGroup*> m_groups;
    int m_dispatch_timer{0};
    bool m_busy{false};
    friend class Task;
};

class TaskGroup : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Q_PROPERTY(QQmlListProperty<Task> tasks READ tasks NOTIFY tasksChanged)
    QML_ELEMENT

public:
    enum class Status {
        Ready,
        Active,
        Finished,
        Failed,
    };
    Q_ENUM(Status)

    TaskGroup(QObject* parent = nullptr);
    ~TaskGroup();

    QString name() const { return m_name; }
    void setName(const QString& name);

    Status status() const { return m_status; }
    void setStatus(Status status);

    void add(Task* task);
    void remove(Task* task);

    QQmlListProperty<Task> tasks();

    void dispatch();
    void update();

signals:
    void nameChanged();
    void statusChanged();
    void tasksChanged();
    void finished();
    void failed();

private:
    TaskDispatcher* m_dispatcher{nullptr};
    QString m_name;
    Status m_status{Status::Ready};
    QList<Task*> m_tasks;

    friend class Task;
    friend class TaskDispatcher;
};

class TaskPrivate;

class Task : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString type READ type CONSTANT)
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged);
    Q_DECLARE_PRIVATE(Task)
    QML_ELEMENT
    QML_UNCREATABLE("")

public:
    enum class Status {
        Ready,
        Active,
        Finished,
        Failed,
    };
    Q_ENUM(Status)
    ~Task();
    TaskGroup* group() const { return m_group; }
    QString type() const;
    virtual QString description() const;
    virtual const void* profilingContext() const;
    Status status() const { return m_status; }
    QString error() const { return m_error; }
    void setError(const QString &error);
    void needs(Task* task);
    Task* then(Task* task);
    void dispatch();
signals:
    void statusChanged();
    void errorChanged();
    void finished();
    void failed(const QString& error);
protected:
    Task(QObject* parent);
    Task(TaskPrivate* d, QObject* parent);
    void setStatus(Status status);
    void waitForFuture(QFuture<void> future);
private:
    virtual void update() = 0;
protected:
    TaskPrivate* const d_ptr;
    TaskGroup* m_group{nullptr};
    QSet<Task*> m_inputs;
    QSet<Task*> m_outputs;
    Status m_status{Status::Ready};
    QString m_error;
    QElapsedTimer m_status_timer;
    friend class TaskGroup;
    friend class TaskDispatcher;
};

class TaskGroupMonitor : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool idle READ idle NOTIFY idleChanged)
    Q_PROPERTY(QQmlListProperty<TaskGroup> groups READ groups NOTIFY groupsChanged)
    QML_ELEMENT
public:
    TaskGroupMonitor(QObject* parent = nullptr);
    bool idle() const;
    QQmlListProperty<TaskGroup> groups();
    void add(TaskGroup* group);
    void remove(TaskGroup* group);
public slots:
    void clear();
signals:
    void idleChanged();
    void groupsChanged();
    void allFinishedOrFailed();
private:
    QList<TaskGroup*> m_groups;
};

struct GA_auth_handler;
struct GA_session;
class Session;
class Context;

class SessionTaskPrivate;

class SessionTask : public Task
{
    Q_OBJECT
    Q_PROPERTY(Session* session READ session CONSTANT)
    Q_DECLARE_PRIVATE(SessionTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SessionTask(Session* session);
    Session* session() const;
    QString description() const override;
protected:
    SessionTask(SessionTaskPrivate* d, Session* session);
};

class ContextTaskPrivate;

class ContextTask : public Task
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context CONSTANT)
    Q_DECLARE_PRIVATE(ContextTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ContextTask(Context* context);
    Context* context() const;
    QString description() const override;
protected:
    ContextTask(ContextTaskPrivate* d, Context* context);
};

class ConnectTaskPrivate;

class ConnectTask : public SessionTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(ConnectTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ConnectTask(Session* session);
    ConnectTask(int timeout, Session* session);
    QString description() const override;
    void update() override;
};

class Prompt : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    Prompt(Task* task);
};

class AuthHandlerTaskPrivate;

class AuthHandlerTask : public SessionTask
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject result READ result NOTIFY resultChanged)
    Q_PROPERTY(Prompt* prompt READ prompt NOTIFY promptChanged)
    Q_PROPERTY(Resolver* resolver READ resolver NOTIFY resolverChanged)
    Q_DECLARE_PRIVATE(AuthHandlerTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    AuthHandlerTask(Session* session);
    QJsonObject result() const { return m_result; }
    void setResult(const QJsonObject& result);
    Prompt* prompt() const { return m_prompt; }
    void setPrompt(Prompt* prompt);
    Resolver* resolver() const { return m_resolver; }
    void setResolver(Resolver* resolver);
    void update() override;
public slots:
    void requestCode(const QString& method);
    void resolveCode(const QByteArray& code);
signals:
    void updated();
    void resultChanged();
    void promptChanged();
    void resolverChanged();
public:
    virtual bool active() const;
    virtual void handleDone(const QJsonObject& result);
    virtual void handleError(const QJsonObject& result);
    virtual void handleRequestCode(const QJsonObject& result);
    virtual void handleResolveCode(const QJsonObject& result);
    virtual void handleCall(const QJsonObject& result);
private:
    virtual bool call(GA_session* session, GA_auth_handler** auth_handler) = 0;
    void promptDevice(const QJsonObject& result);
    void next();
protected:
    AuthHandlerTask(AuthHandlerTaskPrivate* d, Session* session);
    QJsonObject m_result;
    Prompt* m_prompt{nullptr};
    Resolver* m_resolver{nullptr};
};

class CodePrompt : public Prompt
{
    Q_OBJECT
    Q_PROPERTY(AuthHandlerTask* task READ task CONSTANT)
    Q_PROPERTY(QJsonObject result READ result NOTIFY resultChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    CodePrompt(const QJsonObject& result, AuthHandlerTask* task);
    QJsonObject result() const { return m_result; }
    void setResult(const QJsonObject& result);
    QString method() const { return m_result.value("method").toString(); }
    AuthHandlerTask* task() const { return m_task; }
signals:
    void resultChanged();
    void invalidCode();
public slots:
    void select(const QString& method);
    void resolve(const QString& code);
private:
    AuthHandlerTask* const m_task;
    QJsonObject m_result;
    int m_attempts{0};
};

class DevicePrompt : public Prompt
{
    Q_OBJECT
    Q_PROPERTY(AuthHandlerTask* task READ task CONSTANT)
    Q_PROPERTY(QJsonObject result READ result CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    DevicePrompt(const QJsonObject& required_data, AuthHandlerTask* task);
    AuthHandlerTask* task() const { return m_task; }
    QJsonObject result() const { return m_result; }
public slots:
    void select(Device* device);
private:
    AuthHandlerTask* const m_task;
    QJsonObject m_result;
};

class RegisterUserTaskPrivate;

class RegisterUserTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(RegisterUserTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    RegisterUserTask(const QJsonObject& details, const QJsonObject& hw_device, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
};

class LoginTaskPrivate;

class LoginTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(LoginTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoginTask(Session* session);
    LoginTask(const QString& pin, const QJsonObject& pin_data, Session* session);
    LoginTask(const QStringList& mnemonic, const QString& password, Session* session);
    LoginTask(const QJsonObject& hw_device, Session* session);
    LoginTask(const QString& username, const QString& password, Session* session);
    LoginTask(const QJsonObject& details, const QJsonObject& hw_device, Session* session);
    QString description() const override;
private:
    void update() override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
};

class LoadTwoFactorConfigTask : public SessionTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoadTwoFactorConfigTask(Session* session);
private:
    void update() override;
};

class LoadCurrenciesTask : public SessionTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoadCurrenciesTask(Session* session);
private:
    void update() override;
};

class GetWatchOnlyDetailsTask : public SessionTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetWatchOnlyDetailsTask(Session* session);
private:
    void update() override;
};

class EncryptWithPinTaskPrivate;

class EncryptWithPinTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(EncryptWithPinTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    EncryptWithPinTask(const QString& pin, Session* session);
    EncryptWithPinTask(const QJsonValue& plaintext, const QString& pin, Session* session);
    void setPlaintext(const QJsonValue& plaintext);
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class ChangeSettingsTaskPrivate;

class ChangeSettingsTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(ChangeSettingsTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ChangeSettingsTask(const QJsonObject& data, Session* session);
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
};

class LoadAccountTaskPrivate;

class LoadAccountTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(LoadAccountTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoadAccountTask(uint32_t pointer, Session* session);
    QString description() const override;
    Account* account() const;
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
};

class LoadAccountsTaskPrivate;

class LoadAccountsTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(LoadAccountsTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoadAccountsTask(bool refresh, Session* session);
    QString description() const override;
    QList<Account*> accounts() const;
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
};

class SyncAccountsTask : public SessionTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SyncAccountsTask(Session* session);
    QString description() const override;
private:
    void update() override;
};

class LoadBalanceTaskPrivate;

class LoadBalanceTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(LoadBalanceTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoadBalanceTask(Account* account);
    QString description() const override;
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
};

class LoadAssetsTaskPrivate;

class LoadAssetsTask : public SessionTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(LoadAssetsTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoadAssetsTask(bool refresh, Session* session);
    QString description() const override;
private:
    void update() override;
};

class CreateAccountTaskPrivate;

class CreateAccountTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(CreateAccountTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    CreateAccountTask(const QJsonObject& details, Session* session);
    quint32 pointer() const;
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
};

class UpdateAccountTaskPrivate;

class UpdateAccountTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(UpdateAccountTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    UpdateAccountTask(const QJsonObject& details, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class ValidateTaskPrivate;

class ValidateTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(ValidateTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
     ValidateTask(const QJsonObject& details, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class ChangeTwoFactorTaskPrivate;

class ChangeTwoFactorTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(ChangeTwoFactorTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ChangeTwoFactorTask(const QString& method, const QJsonObject& details, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class TwoFactorResetTaskPrivate;

class TwoFactorResetTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_PROPERTY(QString email READ email CONSTANT)
    Q_DECLARE_PRIVATE(TwoFactorResetTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    TwoFactorResetTask(const QString& email, bool dispute, Session* session);
    QString email() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class TwoFactorUndoResetTaskPrivate;

class TwoFactorUndoResetTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_PROPERTY(QString email READ email CONSTANT)
    Q_DECLARE_PRIVATE(TwoFactorUndoResetTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    TwoFactorUndoResetTask(const QString& email, Session* session);
    QString email() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class SetCsvTimeTaskPrivate;

class SetCsvTimeTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(SetCsvTimeTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SetCsvTimeTask(const int value, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
};

class GetCredentialsTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetCredentialsTask(Session* session);
    QString description() const override;
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
};

class DisableAllPinLoginsTask: public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    DisableAllPinLoginsTask(Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class TwoFactorChangeLimitsTaskPrivate;

class TwoFactorChangeLimitsTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(TwoFactorChangeLimitsTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    TwoFactorChangeLimitsTask(const QJsonObject& details, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class CreateTransactionTaskPrivate;

class CreateTransactionTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(CreateTransactionTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    CreateTransactionTask(const QJsonObject& details, Session* session);
    QJsonObject transaction() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class CreateRedepositTransactionTaskPrivate;

class CreateRedepositTransactionTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(CreateRedepositTransactionTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    CreateRedepositTransactionTask(const QJsonObject& details, Session* session);
    QJsonObject transaction() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class SignTransactionTaskPrivate;

class SignTransactionTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject details READ details NOTIFY detailsChanged)
    Q_DECLARE_PRIVATE(SignTransactionTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SignTransactionTask(Session* session);
    QJsonObject details() const;
    void setDetails(const QJsonObject& details);
signals:
    void detailsChanged();
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class BlindTransactionTaskPrivate;

class BlindTransactionTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(BlindTransactionTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    BlindTransactionTask(const QJsonObject& details, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class SendTransactionTaskPrivate;

class SendTransactionTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(SendTransactionTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SendTransactionTask(Session* session);
    void update() override;
    void setDetails(const QJsonObject& details);
    QJsonObject transaction() const;
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class SendNLocktimesTask : public SessionTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SendNLocktimesTask(Session* session);
private:
    void update() override;
};

class TwoFactorCancelResetTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    TwoFactorCancelResetTask(Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class GetUnspentOutputsTaskPrivate;

class GetUnspentOutputsTask: public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(GetUnspentOutputsTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetUnspentOutputsTask(int num_confs, bool all_coins, Account* account);
    void setExpiredAt(uint32_t expired_at);
    QJsonObject unspentOutputs() const;
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class SetUnspentOutputsStatusTaskPrivate;

class SetUnspentOutputsStatusTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(SetUnspentOutputsStatusTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SetUnspentOutputsStatusTask(const QVariantList& outputs, const QString& status, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class GetTransactionsTaskPrivate;

class GetTransactionsTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(GetTransactionsTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetTransactionsTask(int first, int count, Account* account);
    QJsonArray transactions() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class GetReceiveAddressTaskPrivate;

class GetReceiveAddressTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(GetReceiveAddressTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetReceiveAddressTask(Account* account);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class GetAddressesTaskPrivate;

class GetAddressesTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(GetAddressesTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetAddressesTask(int last_pointer, Account* account);
    QJsonArray addresses() const;
    int lastPointer() const;
    bool hasMore() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class SignMessageTaskPrivate;

class SignMessageTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(SignMessageTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SignMessageTask(const QString& message, Address* address);
    QString signature() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class GetSystemMessageTaskPrivate;

class GetSystemMessageTask : public SessionTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(GetSystemMessageTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetSystemMessageTask(Session* session);
    QString message() const;
private:
    void update() override;
};

class AckSystemMessageTaskPrivate;

class AckSystemMessageTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(AckSystemMessageTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    AckSystemMessageTask(const QString& message, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class HttpRequestTaskPrivate;

class HttpRequestTask : public SessionTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(HttpRequestTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    HttpRequestTask(const QJsonObject& params, Session* session);
    QJsonObject response() const;
private:
    void update() override;
};

class DecodeBCURTaskPrivate;

class DecodeBCURTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(DecodeBCURTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    DecodeBCURTask(const QString& part, Session* session);
    QJsonObject decodedResult() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class EncodeBCURTaskPrivate;

class EncodeBCURTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(EncodeBCURTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    EncodeBCURTask(const QJsonObject& details, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class RSAVerifyTaskPrivate;

class PsbtFromJsonTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    PsbtFromJsonTask(const QJsonObject& details, Session* session);
    QString psbt() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QJsonObject m_details;
};

class BroadcastTransactionTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    BroadcastTransactionTask(const QJsonObject& details, Session* session);
    QJsonObject transaction() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QJsonObject m_details;
};

class RSAVerifyTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(RSAVerifyTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    RSAVerifyTask(const QString& pem, const QByteArray& challenge, const QByteArray& signature, Session* session);
    RSAVerifyTask(const QJsonObject& details, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class LoadPaymentsTaskPrivate;

class LoadPaymentsTask : public ContextTask
{
    Q_OBJECT
    Q_DECLARE_PRIVATE(LoadPaymentsTask)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoadPaymentsTask(QNetworkAccessManager* net, Context* context);
    void update() override;
    void fetch(const QString& key);
};

#endif // GREEN_TASK_H
