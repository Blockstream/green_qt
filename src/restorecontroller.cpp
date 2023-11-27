#include "account.h"
#include "context.h"
#include "network.h"
#include "networkmanager.h"
#include "restorecontroller.h"
#include "wallet.h"
#include "walletmanager.h"

#include <wally_wrapper.h>

RestoreController::RestoreController(QObject *parent)
    : Controller(parent)
{
}

void RestoreController::setMnemonic(const QStringList& mnemonic)
{
    if (m_mnemonic == mnemonic) return;
    m_mnemonic = mnemonic;
    emit mnemonicChanged();
}

void RestoreController::setPassword(const QString& password)
{
    if (m_password == password) return;
    m_password = password;
    emit passwordChanged();
}

void RestoreController::restore(const QString& deployment)
{
    if (m_context) {
        m_context->deleteLater();
        setContext(nullptr);
    }
    setContext(new Context(deployment, this));

    auto monitor = new TaskGroupMonitor(this);
    connect(monitor, &TaskGroupMonitor::allFinishedOrFailed, this, [=] {
        auto wallet = WalletManager::instance()->findWallet(m_context->xpubHashId());

        if (!wallet) {
            // TODO search for match in existing wallets
            // for (auto session : m_context->getSessions()) {
            // WalletManager::instance()->findWallet(session->nework(), session->m_wallet_hash_id);
            // }
        }

        if (wallet) {
            m_context->deleteLater();
            setContext(nullptr);
            emit alreadyRestored(wallet);
            return;
        }

        wallet = WalletManager::instance()->createWallet();
        wallet->setName(WalletManager::instance()->newWalletName());
        wallet->setXPubHashId(m_context->xpubHashId());
        wallet->m_is_persisted = true;

        m_context->setWallet(wallet);
        wallet->setContext(m_context);
        setContext(nullptr);

        WalletManager::instance()->insertWallet(wallet);

        emit restoreFinished(wallet->context());
    });

    auto network = NetworkManager::instance()->networkForDeployment(deployment);
    m_context->getOrCreateSession(network);

    for (auto network : NetworkManager::instance()->networks()) {
        if (network->deployment() == deployment) {
            auto group = check(network);
            monitor->add(group);
        }
    }
}

TaskGroup* RestoreController::check(Network* network)
{
    auto group = new TaskGroup(this);

    auto session = m_context->getOrCreateSession(network);
    auto connect_session = new ConnectTask(session);
    auto login = new LoginTask(m_mnemonic, m_password, session);
    auto get_credentials = new GetCredentialsTask(session);

    group->add(connect_session);
    group->add(login);
    group->add(get_credentials);

    connect_session->then(login);
    login->then(get_credentials);

    if (network->isElectrum()) {
        auto load_accounts = new LoadAccountsTask(true, session);
        group->add(load_accounts);
    }

    dispatcher()->add(group);

    connect(group, &TaskGroup::failed, this, [=] {
        m_context->releaseSession(session);
    });

    return group;
}

RestoreCheckTask::RestoreCheckTask(RestoreController* controller)
    : Task(controller)
    , m_controller(controller)
{
}

void RestoreCheckTask::update()
{
    if (status() != Status::Ready) return;

    const auto context = m_controller->context();
//    const auto wallet_hash_id = context->m_wallet_hash_id;
//    if (wallet_hash_id.isEmpty()) return;

    setStatus(Status::Active);

    Q_UNREACHABLE();
//    const auto wallet = WalletManager::instance()->walletWithHashId(wallet_hash_id, false);

//    m_controller->setWallet(wallet);
//    m_controller->setValid(!wallet || !wallet->hasPinData());
//    context->setWallet(wallet);

    setStatus(Status::Finished);
}
