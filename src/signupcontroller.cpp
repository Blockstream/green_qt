#include "context.h"
#include "signupcontroller.h"
#include "ga.h"
#include "json.h"
#include "network.h"
#include "wallet.h"
#include "walletmanager.h"
#include "task.h"

SignupController::SignupController(QObject *parent)
    : Controller(parent)
{
    setContext(new Context(this));
}

void SignupController::setMnemonic(const QStringList& mnemonic)
{
    if (m_mnemonic == mnemonic) return;
    m_mnemonic = mnemonic;
    emit mnemonicChanged();
}

void SignupController::setNetwork(Network* network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged();
    m_dispatcher->dispatch();
}

void SignupController::setType(const QString& type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged();
}

void SignupController::setPin(const QString& pin)
{
    if (m_pin == pin) return;
    m_pin = pin;
    emit pinChanged();
}

void SignupController::setActive(bool active)
{
    if (m_active == active) return;
    if (m_active) return;
    m_active = active;
    emit activeChanged();

    const QJsonObject credentials({
        { "mnemonic", m_mnemonic.join(' ') },
        { "password", QString() }
    });

    auto group = new TaskGroup(this);

    auto session = m_context->getOrCreateSession(m_network);
    auto connect_session = new ConnectTask(session);
    auto register_user = new RegisterUserTask(m_mnemonic, session);
    auto mnemonic_login = new LoginTask(m_mnemonic, QString(), session);
    auto encrypt_with_pin = new EncryptWithPinTask(credentials, m_pin, session);
    auto create_wallet = new SignupCreateWalletTask(this);
    auto load_twofactor_config = new LoadTwoFactorConfigTask(session);
    auto load_currencies = new LoadCurrenciesTask(session);
    auto get_watchonly_details = new GetWatchOnlyDetailsTask(session);
    auto load_assets = new LoadAssetsTask(session);
    auto load_accounts = new LoadAccountsTask(false, session);
    auto persist_wallet = new SignupPersistWalletTask(this);
    auto get_credentials = new GetCredentialsTask(session);

    group->add(connect_session);
    group->add(register_user);
    group->add(mnemonic_login);
    group->add(encrypt_with_pin);
    group->add(create_wallet);
    group->add(load_twofactor_config);
    group->add(load_currencies);
    group->add(get_watchonly_details);
    group->add(load_assets);
    group->add(load_accounts);
    group->add(persist_wallet);
    group->add(get_credentials);

    register_user->then(mnemonic_login);
    mnemonic_login->then(encrypt_with_pin);
    create_wallet->needs(encrypt_with_pin);
    create_wallet->then(get_credentials);
    load_twofactor_config->needs(create_wallet);
    load_currencies->needs(create_wallet);
    get_watchonly_details->needs(create_wallet);
    load_assets->needs(create_wallet);
    load_accounts->needs(create_wallet);
    persist_wallet->needs(load_accounts);

    if (m_type == "amp") {
        const auto account = QJsonObject{
            { "name", "AMP Account" },
            { "type", "2of2_no_recovery" }
        };

        auto network = m_context->wallet()->network();
        auto session = m_context->getOrCreateSession(network);
        auto create_amp_account = new CreateAccountTask(account, session);
        auto hide_main_account = new UpdateAccountTask(QJsonObject{{ "subaccount", 0 }, { "hidden", true }}, session);

        mnemonic_login->then(create_amp_account);
        create_amp_account->then(hide_main_account);
        hide_main_account->then(load_accounts);

        group->add(mnemonic_login);
        group->add(create_amp_account);
        group->add(hide_main_account);
    }

    if (m_network->isElectrum()) {
        const auto account = QJsonObject{
            { "name", "Segwit Account" },
            { "type", "p2wpkh" }
        };

        auto create_segwit_account = new CreateAccountTask(account, session);

        mnemonic_login->then(create_segwit_account);
        create_segwit_account->then(load_accounts);

        group->add(create_segwit_account);
    }

    m_dispatcher->add(group);
}

void SignupController::setWallet(Wallet *wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();
}

QStringList SignupController::generateMnemonic(int size)
{
    return gdk::generate_mnemonic(size);
}

SignupCreateWalletTask::SignupCreateWalletTask(SignupController* controller)
    : Task(controller->dispatcher())
    , m_controller(controller)
{
}

void SignupCreateWalletTask::update()
{
    if (status() != Status::Ready) return;

    setStatus(Status::Active);

    const auto context = m_controller->context();
    const auto network = m_controller->network();
    const auto wallet_hash_id = context->m_wallet_hash_id;

    const auto wallet = WalletManager::instance()->createWallet(network, wallet_hash_id);
    wallet->m_is_persisted = true;

    if (m_controller->type() == "amp") {
        wallet->setName(WalletManager::instance()->uniqueWalletName("My AMP Wallet"));
    } else {
        wallet->setName(WalletManager::instance()->newWalletName(network));
    }
    wallet->m_pin_data = QJsonDocument(context->m_pin_data).toJson();
    wallet->save();

    m_controller->setWallet(wallet);
    context->setWallet(wallet);

    setStatus(Status::Finished);
}


SignupPersistWalletTask::SignupPersistWalletTask(SignupController* controller)
    : Task(controller->dispatcher())
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

    emit m_controller->signup(wallet);
}
