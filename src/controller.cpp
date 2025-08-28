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
