#include "loginwithpincontroller.h"

#include "context.h"
#include "network.h"
#include "networkmanager.h"
#include "task.h"
#include "wallet.h"
#include "walletmanager.h"

LoginController::LoginController(QObject* parent)
    : Controller(parent)
{
    setContext(new Context(this));
}

void LoginController::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
    update();
}

void LoginController::update()
{
    if (!m_wallet) return;
    if (m_pin.isEmpty()) return;

    m_context->setWallet(m_wallet);

    login();
}

void LoginController::loginWithPin(const QString& pin)
{
    m_pin = pin;
    update();
}

void LoginController::login()
{
    clearErrors();
    auto network = m_wallet->network();

    auto group = new TaskGroup(this);

    login(group, network);

    m_dispatcher->add(group);

    connect(group, &TaskGroup::failed, this, &LoginController::loginFailed);
    connect(group, &TaskGroup::finished, this, &LoginController::loginFinished);
}

void LoginController::login(TaskGroup* group, Network* network)
{
    auto session = m_context->getOrCreateSession(network);
    auto connect_session = new ConnectTask(session);
    auto pin_login = new LoginTask(m_pin, m_wallet->pinData(), session);
    auto get_credentials = new GetCredentialsTask(session);

    connect_session->then(pin_login);
    pin_login->then(get_credentials);

    connect(connect_session, &Task::failed, this, [=](const QString& error) {
        if (error == "timeout error") {
            emit sessionError("id_connection_failed");
        }
    });

    connect(pin_login, &Task::failed, this, [=](const QString& error) {
        if (error == "id_invalid_pin") {
            m_wallet->decrementLoginAttempts();
            emit invalidPin();
        } else if (error == "id_connection_failed") {
            emit sessionError(error);
        }
        emit loginFailed();
    });

    connect(pin_login, &Task::finished, this, [=] {
        m_wallet->resetLoginAttempts();
    });

    group->add(connect_session);
    group->add(pin_login);
    group->add(get_credentials);
}

LoadController::LoadController(QObject* parent)
    : Controller(parent)
{
}

void LoadController::add(TaskGroup* group)
{
    m_task_groups.append(group);
    m_dispatcher->add(group);
    connect(group, &TaskGroup::finished, this, [=] {
        remove(group);
    });
    connect(group, &TaskGroup::failed, this, [=] {
        remove(group);
    });
}

void LoadController::remove(TaskGroup* group)
{
    m_task_groups.removeOne(group);
    if (m_task_groups.isEmpty()) {
        emit loadFinished();
    }
}

static bool compatibleToNetworks(Network* network, const QList<Network*> networks)
{
    for (auto net : networks) {
        if (net == network) return false;
        if (net->isMainnet() != network->isMainnet()) return false;
        if (net->isDevelopment() != network->isDevelopment()) return false;
    }
    return true;
}

void LoadController::load()
{
    const auto networks = m_context->getActiveNetworks();
    const auto sessions = m_context->getSessions();

    auto group = new TaskGroup(this);

    for (auto network : networks) {
        loadNetwork(group, network);
    }

    add(group);

    connect(group, &TaskGroup::finished, this, [=] {
        auto wallet = m_context->wallet();
        Q_ASSERT(wallet);
        WalletManager::instance()->addWallet(wallet);
        wallet->setContext(m_context);
    });

    if (m_context->credentials().contains("mnemonic")) {
        for (auto network : NetworkManager::instance()->networks()) {
            if (compatibleToNetworks(network, networks)) {
                qDebug() << Q_FUNC_INFO << "ATTEMPT LOGIN" << network->id() << network->name();
                loginNetwork(network);
            }
        }
    }
}

void LoadController::loadNetwork(TaskGroup* group, Network* network)
{
    auto session = m_context->getOrCreateSession(network);
    group->add(new GetWatchOnlyDetailsTask(session));
    group->add(new LoadTwoFactorConfigTask(session));
    group->add(new LoadCurrenciesTask(session));
    if (network->isLiquid()) group->add(new LoadAssetsTask(session));
    group->add(new LoadAccountsTask(false, session));
}

void LoadController::loginNetwork(Network* network)
{
    auto group = new TaskGroup(this);

    const auto mnemonic = m_context->credentials().value("mnemonic").toString().split(' ');

    auto session = m_context->getOrCreateSession(network);
    auto connect_session = new ConnectTask(session);
    auto login = new LoginTask(mnemonic, QString(), session);

    connect_session->then(login);

    connect(connect_session, &Task::failed, this, [=](const QString& error) {
        if (error == "timeout error") {
            setError("session", "id_connection_failed");
        }
    });

    connect(login, &Task::finished, this, [=] {
        qDebug() << "FINISHED LOGIN" << network->id();
        loadNetwork(group, network);
    });

    connect(login, &Task::failed, this, [=](const QString& error) {
        qDebug() << "ignoring login failed for network" << network->id() << "errr:" << error;
//        emit loginFailed();
    });

    group->add(connect_session);
    group->add(login);

    add(group);
}

