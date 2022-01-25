#include "ga.h"
#include "handlers/createaccounthandler.h"
#include "handlers/connecthandler.h"
#include "handlers/loginhandler.h"
#include "handlers/updateaccounthandler.h"
#include "json.h"
#include "registeruserhandler.h"
#include "signupcontroller.h"
#include "walletmanager.h"

SignupController::SignupController(QObject *parent)
    : QObject(parent)
{
}

void SignupController::setNetwork(Network *network)
{
    if (!m_network.update(network)) return;
    emit networkChanged(m_network);
    update();
}

void SignupController::setType(const QString& type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged(m_type);
}

void SignupController::update()
{
    if (m_wallet && m_wallet->ready()) return;

    if (!m_active) return;
    if (m_pin.isEmpty()) return;

    if (!m_wallet) {
        m_wallet = WalletManager::instance()->createWallet(m_network);
        m_wallet->m_is_persisted = true;
        emit walletChanged(m_wallet);

        m_wallet->createSession();
        m_session = m_wallet->session();
        m_session.track(QObject::connect(m_session, &Session::connectedChanged, this, &SignupController::update));

        m_session->setActive(true);
    }

    if (!m_session->isConnected()) return;

    // TODO: should only add if signup completes
    m_wallet->setAuthentication(Wallet::Authenticating);

    auto activity = new WalletSignupActivity(m_wallet, this);
    m_wallet->pushActivity(activity);

    auto register_user_handler = new RegisterUserHandler(m_mnemonic, m_session);
    auto login_handler = new LoginHandler(m_mnemonic, m_session);
    auto set_pin_handler = new SetPinHandler(m_pin.toLocal8Bit(), m_session);

    connect(register_user_handler, &Handler::done, this, [register_user_handler, login_handler] {
        register_user_handler->deleteLater();
        login_handler->exec();
    });
    connect(login_handler, &Handler::done, this, [this, login_handler, set_pin_handler] {
        login_handler->deleteLater();

        m_wallet->updateHashId(login_handler->walletHashId());
        if (m_type == "amp") {
            Q_ASSERT(m_network->isLiquid());
            auto create_amp_account_handler = new CreateAccountHandler({{ "name", "AMP Account" }, { "type", "2of2_no_recovery" }}, m_session);
            auto hide_main_account_handler = new UpdateAccountHandler({{ "subaccount", 0 }, { "hidden", true }}, m_session);
            connect(create_amp_account_handler, &Handler::done, this, [=] {
                create_amp_account_handler->deleteLater();
                hide_main_account_handler->exec();
            });
            connect(hide_main_account_handler, &Handler::done, this, [=] {
                hide_main_account_handler->deleteLater();
                set_pin_handler->exec();
            });
            create_amp_account_handler->exec();
        } else if (m_network->isElectrum()) {
            auto create_segwit_account_handler = new CreateAccountHandler({{ "name", "Segwit Account" }, { "type", "p2wpkh" }}, m_session);
            connect(create_segwit_account_handler, &Handler::done, this, [=] {
                create_segwit_account_handler->deleteLater();
                set_pin_handler->exec();
            });
            create_segwit_account_handler->exec();
        } else {
            Q_ASSERT(m_type == "default");
            set_pin_handler->exec();
        }
    });
    connect(set_pin_handler, &Handler::done, this, [this, set_pin_handler, activity] {
        set_pin_handler->deleteLater();
        if (m_type == "amp") {
            Q_ASSERT(m_network->isLiquid());
            m_wallet->setName(WalletManager::instance()->uniqueWalletName("My AMP Wallet"));
        } else {
            m_wallet->setName(WalletManager::instance()->newWalletName(m_network));
        }
        m_wallet->m_pin_data = set_pin_handler->pinData();
        m_wallet->save();
        m_wallet->updateCurrencies();
        m_wallet->reload();
        m_wallet->updateConfig();
        m_wallet->setAuthentication(Wallet::Authenticated);

        activity->finish();
        activity->deleteLater();
    });
    register_user_handler->exec();
    WalletManager::instance()->addWallet(m_wallet);
}

void SignupController::setPin(const QString& pin)
{
    if (m_pin == pin) return;
    m_pin = pin;
    emit pinChanged(m_pin);
    update();
}

void SignupController::setActive(bool active)
{
    if (m_active == active) return;
    m_active = active;
    emit activeChanged(m_active);
    update();
}

int SignupController::mnemonicSize()
{
    return m_mnemonic_size;
}

void SignupController::setMnemonicSize(int mnemonic_size)
{
    if (m_mnemonic_size == mnemonic_size) return;
    m_mnemonic_size = mnemonic_size;
    emit mnemonicSizeChanged(m_mnemonic_size);

    m_mnemonic = gdk::generate_mnemonic(mnemonic_size);
    emit mnemonicChanged(m_mnemonic);
}
