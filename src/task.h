#ifndef GREEN_TASK_H
#define GREEN_TASK_H

#include "green.h"

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

class Task : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString type READ type CONSTANT)
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged);
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
    void setStatus(Status status);
private:
    virtual void update() = 0;
protected:
    TaskGroup* m_group{nullptr};
    QSet<Task*> m_inputs;
    QSet<Task*> m_outputs;
    Status m_status{Status::Ready};
    QString m_error;
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

class SessionTask : public Task
{
    Q_OBJECT
    Q_PROPERTY(Session* session READ session CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SessionTask(Session* session);
    Session* session() const { return m_session; }
protected:
    Session* const m_session;
};

class ContextTask : public Task
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ContextTask(Context* context);
    Context* context() const { return m_context; }
protected:
    Context* const m_context;
};

class ConnectTask : public SessionTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ConnectTask(Session* session);
    ConnectTask(int timeout, Session* session);
    void update() override;
private:
    int m_timeout{0};
};

class Prompt : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    Prompt(Task* task);
};

class AuthHandlerTask : public SessionTask
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject result READ result NOTIFY resultChanged)
    Q_PROPERTY(Prompt* prompt READ prompt NOTIFY promptChanged)
    Q_PROPERTY(Resolver* resolver READ resolver NOTIFY resolverChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    AuthHandlerTask(Session* session);
    ~AuthHandlerTask();
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
    GA_auth_handler* m_auth_handler{nullptr};
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

class RegisterUserTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    RegisterUserTask(const QJsonObject& details, const QJsonObject& hw_device, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    const QJsonObject m_details;
    const QJsonObject m_device_details;
};

class LoginTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoginTask(Session* session);
    LoginTask(const QString& pin, const QJsonObject& pin_data, Session* session);
    LoginTask(const QStringList& mnemonic, const QString& password, Session* session);
    LoginTask(const QJsonObject& hw_device, Session* session);
    LoginTask(const QString& username, const QString& password, Session* session);
    LoginTask(const QJsonObject& details, const QJsonObject& hw_device, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    const QJsonObject m_details;
    const QJsonObject m_hw_device;
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

class EncryptWithPinTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    EncryptWithPinTask(const QString& pin, Session* session);
    EncryptWithPinTask(const QJsonValue& plaintext, const QString& pin, Session* session);
    void setPlaintext(const QJsonValue& plaintext);
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    QString m_pin;
    QJsonValue m_plaintext;
};

class ChangeSettingsTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ChangeSettingsTask(const QJsonObject& data, Session* session);
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    const QJsonObject m_data;
};

class LoadAccountTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoadAccountTask(uint32_t pointer, Session* session);
    Account* account() const { return m_account; }
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    const uint32_t m_pointer;
    Account* m_account{nullptr};
};

class LoadAccountsTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoadAccountsTask(bool refresh, Session* session);
    QList<Account*> accounts() const { return m_accounts; }
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    const bool m_refresh;
    QList<Account*> m_accounts;
};

class LoadBalanceTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoadBalanceTask(Account* account);
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    Account* const m_account;
};

class LoadAssetsTask : public SessionTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LoadAssetsTask(bool refresh, Session* session);
private:
    void update() override;
private:
    const bool m_refresh;
};

class CreateAccountTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    CreateAccountTask(const QJsonObject& details, Session* session);
    quint32 pointer() const { return m_pointer; }
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    const QJsonObject m_details;
    quint32 m_pointer{0};
};

class UpdateAccountTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    UpdateAccountTask(const QJsonObject& details, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QJsonObject m_details;
};

class ValidateTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
     ValidateTask(const QJsonObject& details, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QJsonObject m_details;
};

class SetWatchOnlyTask : public SessionTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SetWatchOnlyTask(const QString& username, const QString& password, Session* session);
private:
    void update() override;
private:
    const QString m_username;
    const QString m_password;
};

class ChangeTwoFactorTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    ChangeTwoFactorTask(const QString& method, const QJsonObject& details, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    QString m_method;
    QJsonObject m_details;
};

class TwoFactorResetTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_PROPERTY(QString email READ email CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    TwoFactorResetTask(const QString& email, Session* session);
    QString email() const { return m_email; }
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QString m_email;
};

class SetCsvTimeTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SetCsvTimeTask(const int value, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    const int m_value;
};

class GetCredentialsTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetCredentialsTask(Session* session);
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

class TwoFactorChangeLimitsTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    TwoFactorChangeLimitsTask(const QJsonObject& details, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QJsonObject m_details;
};

class CreateTransactionTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    CreateTransactionTask(const QJsonObject& details, Session* session);
    QJsonObject transaction() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QJsonObject m_details;
    QJsonObject m_transaction;
};

class SignTransactionTask : public AuthHandlerTask
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject details READ details NOTIFY detailsChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SignTransactionTask(Session* session);
    QJsonObject details() const { return m_details; }
    void setDetails(const QJsonObject& details);
signals:
    void detailsChanged();
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    QJsonObject m_details;
};

class BlindTransactionTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    BlindTransactionTask(const QJsonObject& details, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QJsonObject m_details;
};

class SendTransactionTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SendTransactionTask(Session* session);
    void setDetails(const QJsonObject& details);
    QJsonObject transaction() const;
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    QJsonObject m_details;
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

class GetUnspentOutputsTask: public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetUnspentOutputsTask(int num_confs, bool all_coins, Account* account);
    void setExpiredAt(uint32_t expired_at) { m_expired_at = expired_at; }
    QJsonObject unspentOutputs() const;
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    qint64 m_subaccount;
    int m_num_confs;
    bool m_all_coins;
    uint32_t m_expired_at{0};
};

class SetUnspentOutputsStatusTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SetUnspentOutputsStatusTask(const QVariantList& outputs, const QString& status, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    QVariantList m_outputs;
    QString m_status;
};

class GetTransactionsTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetTransactionsTask(int first, int count, Account* account);
    QJsonArray transactions() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const qint64 m_subaccount;
    int m_first;
    int m_count;
};

class GetReceiveAddressTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    Account* const m_account;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    GetReceiveAddressTask(Account* account);
};

class GetAddressesTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetAddressesTask(int last_pointer, Account* account);
    QJsonArray addresses() const;
    int lastPointer() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const qint64 m_subaccount;
    const int m_last_pointer = 0;
};

class DeleteWalletTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    DeleteWalletTask(Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class SignMessageTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SignMessageTask(const QString& message, Address* address);
    QString signature() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    Address* const m_address;
    const QString m_message;
};

class GetSystemMessageTask : public SessionTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GetSystemMessageTask(Session* session);
    QString message() const { return m_message; }
private:
    void update() override;
private:
    QString m_message;
};

class AckSystemMessageTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    AckSystemMessageTask(const QString& message, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QString m_message;
};

class HttpRequestTask : public SessionTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    HttpRequestTask(const QJsonObject& params, Session* session);
    QJsonObject response() const { return m_response; }
private:
    void update() override;
private:
    const QJsonObject m_params;
    QJsonObject m_response;
};

class DecodeBCURTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    DecodeBCURTask(const QString& part, Session* session);
    QJsonObject decodedResult() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QString m_part;
};

class EncodeBCURTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    EncodeBCURTask(const QJsonObject& details, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QJsonObject m_details;
};

#endif // GREEN_TASK_H
