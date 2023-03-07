#include "loginwithpincontroller.h"

#include "context.h"
#include "network.h"
#include "task.h"
#include "wallet.h"
#include "walletmanager.h"

PinLoginController::PinLoginController(QObject* parent)
    : Controller(parent)
{
    setContext(new Context(this));
}

void PinLoginController::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
    update();
}

void PinLoginController::setPin(const QString& pin)
{
    if (m_pin == pin) return;
    m_pin = pin;
    emit pinChanged();
    update();
}

void PinLoginController::update()
{
    if (!m_wallet) return;
    if (m_pin.isEmpty()) return;

    m_context->setWallet(m_wallet);

    login();
}

void PinLoginController::login()
{
    clearErrors();

    auto connect_session = new SessionConnectTask(m_context->session());
    auto pin_login = new SessionLoginTask(m_pin, m_wallet->pinData(), m_context);
    auto get_credentials = new GetCredentialsTask(m_context);

    connect_session->then(pin_login);
    pin_login->then(get_credentials);

    connect(connect_session, &Task::failed, this, [=](const QString& error) {
        if (error == "timeout error") {
            setError("session", "id_connection_failed");
        }
    });

    connect(pin_login, &Task::failed, this, [=](const QString& error) {
        if (error == "id_invalid_pin") {
            m_wallet->decrementLoginAttempts();
        } else if (error == "id_connection_failed") {
            setError("session", error);
//            Q_UNREACHABLE();
//            m_setup->deleteLater();
//            m_setup = nullptr;
        }
        emit loginFailed();
    });

    connect(pin_login, &Task::finished, this, [=] {
        m_wallet->resetLoginAttempts();
    });

    auto group = new TaskGroup(this);

    group->add(connect_session);
    group->add(pin_login);
    group->add(get_credentials);

    m_dispatcher->add(group);

    connect(group, &TaskGroup::failed, this, &PinLoginController::loginFailed);
    connect(group, &TaskGroup::finished, this, &PinLoginController::load);
}

void PinLoginController::load()
{
    auto group = new TaskGroup(this);
    group->add(new GetWatchOnlyDetailsTask(m_context));
    group->add(new LoadTwoFactorConfigTask(m_context));
    group->add(new LoadCurrenciesTask(m_context));
    if (m_wallet->network()->isLiquid()) group->add(new LoadAssetsTask(m_context));
    group->add(new LoadAccountsTask(m_context));
    m_dispatcher->add(group);

    connect(group, &TaskGroup::finished, this, [=] {
        WalletManager::instance()->addWallet(m_wallet);
        m_wallet->setContext(m_context);
        emit loginFinished(m_wallet);
    });

    connect(group, &TaskGroup::failed, this, [=] {
        emit loginFailed();
    });
}
