#include "controller.h"
#include <gdk.h>

#include "account.h"
#include "address.h"
#include "context.h"
#include "network.h"
#include "networkmanager.h"
#include "notification.h"
#include "session.h"
#include "task.h"
#include "wallet.h"

Controller::Controller(QObject* parent)
    : Controller(new ControllerPrivate, parent)
{
    setMonitor(new TaskGroupMonitor(this));
}

Controller::Controller(ControllerPrivate* d, QObject* parent)
    : QObject(parent)
    , d_ptr(d)
{
}

bool Controller::updateError(const QString& key, const QVariant& value, bool when)
{
    if (when) {
        setError(key, value);
        return true;
    } else {
        clearError(key);
        return false;
    }
}

void Controller::setError(const QString& key, const QVariant& value)
{
    Q_ASSERT(!value.isNull());
    if (m_errors.contains(key) && m_errors.value(key) == value) return;
    m_errors[key] = value;
    emit errorsChanged();
}

void Controller::clearError(const QString& key)
{
    if (!m_errors.contains(key)) return;
    m_errors.remove(key);
    emit errorsChanged();
}

void Controller::clearErrors()
{
    if (m_errors.empty()) return;
    m_errors.clear();
    emit errorsChanged();
}

Controller::~Controller()
{
    Q_D(Controller);
    d->future_synchronizer.waitForFinished();
    delete d;
}

Context* Controller::context() const
{
    Q_D(const Controller);
    return d->context;
}

void Controller::setContext(Context* context)
{
    Q_D(Controller);
    if (d->context == context) return;
    d->context = context;
    emit contextChanged();
}

TaskDispatcher *Controller::dispatcher() const
{
    Q_D(const Controller);
    Q_ASSERT(d->context);
    return d->context->dispatcher();
}

TaskGroupMonitor *Controller::monitor() const
{
    Q_D(const Controller);
    return d->monitor;
}

void Controller::setMonitor(TaskGroupMonitor* monitor)
{
    Q_D(Controller);
    if (d->monitor == monitor) return;
    if (d->monitor) d->monitor->deleteLater();
    d->monitor = monitor;
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
    Q_D(Controller);
    if (!d->context) return;

    // // Check if wallet is undergoing reset
    // if (d->context->isLocked()) {
    //     qDebug() << Q_FUNC_INFO << "wallet is locked";
    //     return;
    // }

    for (auto session : d->context->getSessions()) {
        changeSessionSettings(session, data);
    }
}

void Controller::changeSessionSettings(Session* session, const QJsonObject& data)
{
    if (!session) return;
    if (session->isTwoFactorResetActive()) {
        emit failed("The action can't be completed");
        return;
    }
    if (DeepContains(session->settings(), data)) {
        emit finished();
        return;
    }
    auto group = new TaskGroup(this);
    auto task = new ChangeSettingsTask(data, session);
    connect(task, &Task::failed, this, [this](const QString& error) {
        emit failed(error);
    });
    group->add(task);
    connect(group, &TaskGroup::finished, this, [this] {
        emit finished();
    });
    monitor()->add(group);
    dispatcher()->add(group);
}

void Controller::setSessionRecoveryEmail(Session* session, const QString& email)
{
    if (!session) return;

    const auto method = QByteArray{"email"};
    const auto twofactor_details = QJsonObject{
        { "data", email.toUtf8().data() },
        { "confirmed", true },
        { "enabled", false }
    };

    const auto settings_details = QJsonObject{
        { "notifications" , QJsonValue({
            { "email_incoming", true },
            { "email_outgoing", true }})
        }
    };

    const auto change_twofactor = new ChangeTwoFactorTask(method, twofactor_details, session);
    const auto update_config = new LoadTwoFactorConfigTask(session);
    const auto change_settings = new ChangeSettingsTask(settings_details, session);
    connect(change_twofactor, &Task::failed, this, [this](const QString& error) {
        emit failed(error);
    });
    connect(update_config, &Task::failed, this, [this](const QString& error) {
        emit failed(error);
    });
    connect(change_settings, &Task::failed, this, [this](const QString& error) {
        emit failed(error);
    });

    change_twofactor->then(update_config);
    update_config->then(change_settings);

    auto group = new TaskGroup(this);

    group->add(change_twofactor);
    group->add(update_config);
    group->add(change_settings);

    connect(group, &TaskGroup::finished, this, [this] {
        emit finished();
    });
    monitor()->add(group);
    dispatcher()->add(group);
}

void Controller::disableAllPins()
{
    Q_D(Controller);
    auto group = new TaskGroup(this);
    for (auto session : d->context->getSessions()) {
        auto task = new DisableAllPinLoginsTask(session);
        group->add(task);
    }
    dispatcher()->add(group);
    connect(group, &TaskGroup::finished, this, [=, this] {
        d->context->wallet()->setLogin(nullptr);
        emit finished();
    });
}

void Controller::changePin(const QString& pin)
{
    Q_D(Controller);
    if (!d->context) return;

    auto session = d->context->primarySession();
    auto encrypt_with_pin = new EncryptWithPinTask(d->context->credentials(), pin, session);
    auto group = new TaskGroup(this);
    group->add(encrypt_with_pin);
    dispatcher()->add(group);

    connect(group, &TaskGroup::finished, this, [=, this] {
        auto wallet = d->context->wallet();
        auto pin = new PinData(wallet);
        pin->setNetwork(session->network());
        pin->setData(encrypt_with_pin->result().value("result").toObject().value("pin_data").toObject());
        wallet->setLogin(pin);
        wallet->save();
        emit finished();
    });
}

bool Controller::setAccountName(Account* account, QString name)
{
    Q_D(Controller);
    if (!d->context) return false;

    name = name.trimmed();
    if (name.isEmpty()) {
        return false;
    }
    if (account->name() == name) return false;

    auto network = account->network();
    auto session = d->context->getOrCreateSession(network);

    const auto task = new UpdateAccountTask(QJsonObject{
        { "subaccount", static_cast<qint64>(account->pointer()) },
        { "name", name }
    }, session);

    connect(task, &Task::finished, this, [=, this] {
        account->setName(name);
    });

    d->context->dispatcher()->add(task);

    return true;
}

void Controller::setAccountHidden(Account* account, bool hidden)
{
    Q_D(Controller);
    if (!d->context) return;
    auto network = account->network();
    auto session = d->context->getOrCreateSession(network);

    const auto task = new UpdateAccountTask(QJsonObject{
        { "subaccount", static_cast<qint64>(account->pointer()) },
        { "hidden", hidden }
    }, session);
    connect(task, &UpdateAccountTask::finished, this, [=, this] {
        account->setHidden(hidden);
    });
    dispatcher()->add(task);
}

void Controller::waitForFuture(QFuture<void> future)
{
    Q_D(Controller);
    d->future_synchronizer.addFuture(future);
}
