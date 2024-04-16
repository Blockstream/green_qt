#include "context.h"
#include "networkmanager.h"
#include "signupcontroller.h"
#include "wallet.h"
#include "walletmanager.h"
#include "task.h"

SignupController::SignupController(QObject *parent)
    : Controller(parent)
{
}

void SignupController::setMnemonic(const QStringList& mnemonic)
{
    if (m_mnemonic == mnemonic) return;
    m_mnemonic = mnemonic;
    emit mnemonicChanged();
}

void SignupController::signup(const QString& deployment)
{
    const QJsonObject credentials({
        { "mnemonic", m_mnemonic.join(' ') },
        { "password", QString() }
    });

    auto group = new TaskGroup(this);

    if (!m_context) {
        setContext(new Context(deployment, false, this));
    }

    auto session = m_context->primarySession();
    auto connect_session = new ConnectTask(session);
    auto register_user = new RegisterUserTask(m_mnemonic, session);
    auto mnemonic_login = new LoginTask(m_mnemonic, QString(), session);
    auto create_wallet = new SignupCreateWalletTask(this);
    auto persist_wallet = new SignupPersistWalletTask(this);
    auto get_credentials = new GetCredentialsTask(session);

    group->add(connect_session);
    group->add(register_user);
    group->add(mnemonic_login);
    group->add(create_wallet);
    group->add(persist_wallet);
    group->add(get_credentials);

    register_user->then(mnemonic_login);
    mnemonic_login->then(create_wallet);
    create_wallet->then(get_credentials);
    persist_wallet->needs(get_credentials);

    dispatcher()->add(group);
}

void SignupController::setWallet(Wallet *wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
}

SignupCreateWalletTask::SignupCreateWalletTask(SignupController* controller)
    : Task(controller)
    , m_controller(controller)
{
}

void SignupCreateWalletTask::update()
{
    if (status() != Status::Ready) return;

    setStatus(Status::Active);

    const auto context = m_controller->context();
    const auto network = m_controller->network();

    const auto wallet = WalletManager::instance()->createWallet();
    wallet->setName(WalletManager::instance()->newWalletName());
    wallet->m_deployment = context->deployment();
    wallet->m_is_persisted = true;
    wallet->save();

    m_controller->setWallet(wallet);
    context->setWallet(wallet);

    setStatus(Status::Finished);
}


SignupPersistWalletTask::SignupPersistWalletTask(SignupController* controller)
    : Task(controller)
    , m_controller(controller)
{
}

void SignupPersistWalletTask::update()
{
    if (status() != Status::Ready) return;

    setStatus(Status::Active);

    const auto context = m_controller->context();
    const auto wallet = m_controller->wallet();
    WalletManager::instance()->addWallet(wallet);
    wallet->setContext(context);

    setStatus(Status::Finished);

    emit m_controller->registerFinished(context);
}
