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

void RestoreController::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
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
    Q_ASSERT(!m_wallet || m_wallet->deployment() == deployment);
    setContext(new Context(deployment, false, this));

    auto monitor = new TaskGroupMonitor(this);
    connect(monitor, &TaskGroupMonitor::allFinishedOrFailed, this, [=] {
        if (m_wallet) {
            if (m_wallet->xpubHashId() == m_context->xpubHashId()) {
                m_context->setWallet(m_wallet);
                m_wallet->setContext(m_context);
                setContext(nullptr);
                emit restoreFinished(m_wallet->context());
                return;
            } else {
                m_context->deleteLater();
                setContext(nullptr);
                emit mismatch();
                return;
            }
        }

        Wallet* wallet = nullptr;
        for (auto w : WalletManager::instance()->getWallets()) {
            if (qobject_cast<PinData*>(w->login()) && w->xpubHashId() == m_context->xpubHashId()) {
                m_wallet = w;
                break;
            }
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
        wallet->m_deployment = m_context->deployment();
        wallet->m_is_persisted = true;

        m_context->setWallet(wallet);
        wallet->setContext(m_context);
        setContext(nullptr);

        WalletManager::instance()->insertWallet(wallet);

        emit restoreFinished(wallet->context());
    });

    m_context->primarySession();

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
        auto sync_accounts = new SyncAccountsTask(session);
        auto load_accounts2 = new LoadAccountsTask(true, session);
        load_accounts->then(sync_accounts);
        sync_accounts->then(load_accounts2);
        group->add(load_accounts);
        group->add(sync_accounts);
        group->add(load_accounts2);
    }

    if (network->isLiquid()) {
        auto load_assets = new LoadAssetsTask(true, session);
        group->add(load_assets);
    }

    dispatcher()->add(group);

    connect(group, &TaskGroup::failed, this, [=] {
        m_context->releaseSession(session);
    });

    return group;
}
