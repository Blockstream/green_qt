#include "loginwithpincontroller.h"

#include "context.h"
#include "network.h"
#include "networkmanager.h"
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
    auto network = m_wallet->network();

    auto group = new TaskGroup(this);

    login(group, network);

    m_dispatcher->add(group);

    connect(group, &TaskGroup::failed, this, &PinLoginController::loginFailed);
    connect(group, &TaskGroup::finished, this, &PinLoginController::load);
}

void PinLoginController::login(TaskGroup* group, Network* network)
{
    auto session = m_context->getOrCreateSession(network);
    auto connect_session = new ConnectTask(session);
    auto pin_login = new LoginTask(m_pin, m_wallet->pinData(), session);
    auto get_credentials = new GetCredentialsTask(session);

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

    group->add(connect_session);
    group->add(pin_login);
    group->add(get_credentials);
}

void PinLoginController::loginNetwork(Network* network)
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

    connect(login, &Task::failed, this, [=](const QString& error) {
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

    group->add(connect_session);
    group->add(login);

    loadNetwork(group, network);

    m_dispatcher->add(group);
}

void PinLoginController::load()
{
    auto network = m_wallet->network();

    auto group = new TaskGroup(this);

//    for (auto net : NetworkManager::instance()->networks()) {
//        if (network == net) continue;
//        if (network->isMainnet() != net->isMainnet()) continue;
//        qDebug() << Q_FUNC_INFO << "ATTEMPT LOGIN" << net->id() << net->name();
//        loginNetwork(group, net);
//    }

    loadNetwork(group, network);

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

void PinLoginController::loadNetwork(TaskGroup* group, Network* network)
{
    auto session = m_context->getOrCreateSession(network);
    group->add(new GetWatchOnlyDetailsTask(session));
    group->add(new LoadTwoFactorConfigTask(session));
    group->add(new LoadCurrenciesTask(session));
    if (network->isLiquid()) group->add(new LoadAssetsTask(session));
    group->add(new LoadAccountsTask(false, session));
}
