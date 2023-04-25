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

public:
    TaskDispatcher(QObject* parent);
    ~TaskDispatcher();

    void add(Task* task);
    void add(TaskGroup* group);
    void remove(TaskGroup* group);

    bool isBusy() const;

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
    friend class Task;
};

class TaskGroup : public QObject
{
    Q_OBJECT
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

    Status status() const { return m_status; }
    void setStatus(Status status);

    void add(Task* task);
    void remove(Task* task);

    QQmlListProperty<Task> tasks();

    void dispatch();
    void update();

signals:
    void statusChanged();
    void tasksChanged();
    void finished();
    void failed();

private:
    TaskDispatcher* m_dispatcher{nullptr};
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

struct GA_auth_handler;
struct GA_session;
class Session;
class Context;

class SessionTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
public:
    SessionTask(Session* session);
    Session* session() const { return m_session; }
protected:
    Session* const m_session;
};

class SessionConnectTask : public SessionTask
{
    Q_OBJECT
public:
    SessionConnectTask(Session* session);
    void update() override;
};

class ContextTask : public SessionTask
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context CONSTANT)
    QML_ELEMENT
public:
    ContextTask(Context* context);
    Context* context() const { return m_context; }
protected:
    Context* const m_context;
};

class AuthHandlerTask : public ContextTask
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject result READ result NOTIFY resultChanged)
    QML_ELEMENT
public:
    AuthHandlerTask(Context* context);
    ~AuthHandlerTask();
    QJsonObject result() const { return m_result; }
    void setResult(const QJsonObject& result);
    void update() override;
public slots:
    void requestCode(const QString& method);
    void resolveCode(const QByteArray& code);
signals:
    void updated();
    void resultChanged();
protected:
    virtual bool active() const;
    virtual void handleDone(const QJsonObject& result);
    virtual void handleError(const QJsonObject& result);
    virtual void handleRequestCode(const QJsonObject& result);
    virtual void handleResolveCode(const QJsonObject& result);
    virtual void handleCall(const QJsonObject& result);
private:
    virtual bool call(GA_session* session, GA_auth_handler** auth_handler) = 0;
    void next();
protected:
    GA_auth_handler* m_auth_handler{nullptr};
    QJsonObject m_result;
};

class RegisterUserTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    RegisterUserTask(const QStringList& mnemonic, Context* context);
    RegisterUserTask(const QJsonObject &device_details, Context *context);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    const QJsonObject m_details;
    const QJsonObject m_device_details;
};

class SessionLoginTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    SessionLoginTask(Context* context);
    SessionLoginTask(const QString& pin, const QJsonObject& pin_data, Context* context);
    SessionLoginTask(const QStringList& mnemonic, const QString& password, Context* context);
    SessionLoginTask(const QJsonObject& hw_device, Context* context);
    SessionLoginTask(const QString& username, const QString& password, Context* context);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    const QJsonObject m_details;
    const QJsonObject m_hw_device;
};

class LoadTwoFactorConfigTask : public ContextTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    LoadTwoFactorConfigTask(Context* context);
    LoadTwoFactorConfigTask(bool lock, Context* context);
private:
    void update() override;
private:
    const bool m_lock{false};
};

class LoadCurrenciesTask : public ContextTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    LoadCurrenciesTask(Context* context);
private:
    void update() override;
};

class GetWatchOnlyDetailsTask : public ContextTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    GetWatchOnlyDetailsTask(Context* context);
private:
    void update() override;
};

class EncryptWithPinTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    EncryptWithPinTask(const QString& pin, Context* context);
    EncryptWithPinTask(const QJsonValue& plaintext, const QString& pin, Context* context);
    void setPlaintext(const QJsonValue& plaintext);
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    QString m_pin;
    QJsonValue m_plaintext;
};

class ChangeSettingsTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    ChangeSettingsTask(const QJsonObject& data, Context* context);
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    const QJsonObject m_data;
    QJsonObject m_settings;
};

class LoadAccountsTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    LoadAccountsTask(Context* context);
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
};

class LoadBalanceTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    LoadBalanceTask(Account* account);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    Account* const m_account;
};

class LoadAssetsTask : public ContextTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    LoadAssetsTask(Context* context);
private:
    void update() override;
};

class CreateAccountTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    CreateAccountTask(const QJsonObject& details, Context* context);
    int pointer() const { return m_pointer; }
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    const QJsonObject m_details;
    int m_pointer{-1};
};

class UpdateAccountTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    UpdateAccountTask(const QJsonObject& details, Context* context);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QJsonObject m_details;
};

class SetWatchOnlyTask : public ContextTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    SetWatchOnlyTask(const QString& username, const QString& password, Context* context);
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
public:
    ChangeTwoFactorTask(const QString& method, const QJsonObject& details, Context* context);
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
public:
    TwoFactorResetTask(const QString& email, Context* context);
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
public:
    SetCsvTimeTask(const int value, Context* context);
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
public:
    GetCredentialsTask(Context* context);
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
};

class DisableAllPinLoginsTask: public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    DisableAllPinLoginsTask(Context* context);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject &result) override;
};

class TwoFactorChangeLimitsTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    TwoFactorChangeLimitsTask(const QJsonObject& details, Context* context);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QJsonObject m_details;
};

class CreateTransactionTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    CreateTransactionTask(const QJsonObject& details, Context* context);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
signals:
    void transaction(const QJsonObject& data);
private:
    const QJsonObject m_details;
    QJsonObject m_transaction;
};

class SignTransactionTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    SignTransactionTask(const QJsonObject& details, Context* context);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    const QJsonObject m_details;
};

class SendTransactionTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    SendTransactionTask(Context* context);
    void setDetails(const QJsonObject& details);
private:
    bool active() const override;
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
private:
    QJsonObject m_details;
};

class SendNLocktimesTask : public ContextTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    SendNLocktimesTask(Context* context);
private:
    void update() override;
};

class TwoFactorCancelResetTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    TwoFactorCancelResetTask(Context* context);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

class GetUnspentOutputsTask: public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    GetUnspentOutputsTask(int num_confs, bool all_coins, qint64 subaccount, Context* context);
    QJsonObject unspentOutputs() const;
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    qint64 m_subaccount;
    int m_num_confs;
    bool m_all_coins;
};

class SetUnspentOutputsStatusTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
public:
    SetUnspentOutputsStatusTask(const QVariantList& outputs, const QString& status, Context* context);
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

class GetAddressesTask : public AuthHandlerTask
{
    Q_OBJECT
    QML_ELEMENT
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
public:
    DeleteWalletTask(Context* context);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
};

#endif // GREEN_TASK_H
