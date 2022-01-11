#include "handlers/loginhandler.h"
#include "handlers/gettransactionshandler.h"
#include "network.h"
#include "restorecontroller.h"
#include "wallet.h"
#include "walletmanager.h"

RestoreController::RestoreController(QObject *parent)
    : AbstractController(parent)
{
}

void RestoreController::setNetwork(Network* network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged(m_network);
    update();
}

void RestoreController::setType(const QString& type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged(m_type);
    update();
}

#include <wally_bip39.h>

void RestoreController::setMnemonic(const QStringList& mnemonic)
{
    if (m_mnemonic == mnemonic) return;
    m_mnemonic = mnemonic;
    emit mnemonicChanged(m_mnemonic);
    update();
}

void RestoreController::setPassword(const QString& password)
{
    if (m_password == password) return;
    m_password = password;
    emit passwordChanged(m_password);
    update();
}

void RestoreController::setPin(const QString& pin)
{
    if (m_pin == pin) return;
    m_pin = pin;
    emit pinChanged(m_pin);
}

void RestoreController::setActive(bool active)
{
    if (m_active == active) return;
    m_active = active;
    emit activeChanged(m_active);
    update();
}

void RestoreController::accept()
{
    Q_ASSERT(!m_wallet);
    m_wallet = WalletManager::instance()->restoreWallet(m_network);
    emit walletChanged(m_wallet);
    m_wallet->updateHashId(m_wallet_hash_id);
    m_wallet->setSession(m_session);
    m_wallet->setSession();
    m_session = nullptr;

    Q_ASSERT(m_wallet->isAuthenticated());
    Q_ASSERT(m_wallet->m_pin_data.isEmpty());
    Q_ASSERT(!m_accepted);
    m_accepted = true;

    auto activity = new AcceptRestoreActivity(m_wallet, this);
    m_wallet->pushActivity(activity);

    auto handler = new SetPinHandler(m_pin.toLocal8Bit(), m_wallet->session());
    QObject::connect(handler, &Handler::done, this, [=] {
        handler->deleteLater();
        m_wallet->m_pin_data = handler->pinData();
        if (m_type == "amp") {
            Q_ASSERT(m_network->isLiquid());
            m_wallet->setName(WalletManager::instance()->uniqueWalletName("My AMP Wallet"));
        } else {
            m_wallet->setName(WalletManager::instance()->newWalletName(m_network));
        }

        WalletManager::instance()->insertWallet(m_wallet);

        m_wallet->updateCurrencies();
        m_wallet->reload();
        m_wallet->updateConfig();

        activity->finish();
        activity->deleteLater();
    });
    handler->exec();
}

void RestoreController::update()
{
    if (m_accepted) return;
    auto check = [this] {
        if (!m_network) {
            return false;
        }
        if (m_mnemonic.length() == 27) {
            if (m_password.isEmpty()) return false;
        } else if (m_mnemonic.length() == 24) {
            if (!m_password.isEmpty()) return false;
        } else if (m_mnemonic.length() == 12) {
        } else {
            return false;
        }
        for (auto& word : m_mnemonic) {
            if (word.isEmpty()) return false;
        }
        return true;
    };
    if (!check()) return;

    if (!m_active) {
        if (m_session) {
            // TODO: free session etc
        }
        return;
    }

    setBusy(true);

    if (!m_session) {
        m_session = new Session(m_network, this);
        QObject::connect(m_session, &Session::connectedChanged, this, &RestoreController::update);
        m_session->setActive(true);
        emit sessionChanged(m_session);
        return;
    }

    if (!m_session->isConnected()) {
        return;
    }


//        qDebug() << "setup wallet and activate session";

//        m_wallet = WalletManager::instance()->restoreWallet(m_network);
//        emit walletChanged(m_wallet);

//        m_wallet->createSession();
//        m_session = m_wallet->session();
//        m_session.track(QObject::connect(m_session, &Session::connectedChanged, this, &RestoreController::update));

//        m_session->setActive(true);
//    }

//    if (m_active && m_wallet && m_wallet->m_session->isConnected()) {
//        auto activity = new CheckRestoreActivity(m_wallet, this);
//        m_wallet->pushActivity(activity);
//        qDebug() << "attempt login with mnemonic and password";
//        m_wallet->setAuthentication(Wallet::Authenticating);

    if (m_wallet_hash_id.isEmpty()) {
        auto handler = new LoginHandler(m_mnemonic, m_password, m_session);
        QObject::connect(handler, &Handler::done, this, [=] {
            handler->deleteLater();
            m_wallet_hash_id = handler->walletHashId();

            update();
//           m_wallet->updateHashId();
//           m_wallet->setAuthentication(Wallet::Authenticated);
//           activity->finish();
//           activity->deleteLater();
        });
        QObject::connect(handler, &Handler::error, this, [=] {
            handler->deleteLater();
            const auto error = handler->result().value("error").toString();

            updateError("password", QStringLiteral("mismatch"), error.indexOf("Invalid checksum") >= 0);

            setValid(false);
            setBusy(false);

            // TODO: these are examples of errors
            // these sould be handled in Handler class, see TODO above
            // {"action":"get_xpubs","device":{},"error":"get_xpubs exception:login failed:id_login_failed","status":"error"}
            // {"action":"get_xpubs","device":{},"error":"get_xpubs exception:reconnect required","status":"error"}

            // TODO controller should expose error? or activity?
//            m_wallet->setAuthentication(Wallet::Unauthenticated);
//            activity->finish();
//            activity->deleteLater();
//            emit loginError(error);
        });
        handler->exec();
        return;
    }

    m_wallet = WalletManager::instance()->walletWithHashId(m_wallet_hash_id, false);
    if (m_wallet) {
        qDebug() << Q_FUNC_INFO << m_network->id() << m_wallet_hash_id << m_wallet->name();
        setBusy(false);
        setValid(false);
        emit walletChanged(m_wallet);
        return;
    }

    if (!m_network->isElectrum()) {
        setBusy(false);
        setValid(true);
        return;
    }

    if (m_subaccounts.isEmpty()) {
        qDebug() << Q_FUNC_INFO << "get subaccounts" << m_network->id();

        auto handler = new GetSubAccountsHandler(m_session, true);
        QObject::connect(handler, &Handler::done, this, [=] {
            handler->deleteLater();
            m_subaccounts = handler->subAccounts();
            update();
        });
        handler->exec();
        return;
    }

    for (auto subaccount : m_subaccounts) {
        if (subaccount.toObject().value("bip44_discovered").toBool()) {
            setValid(true);
            break;
        }
    }

    setBusy(false);
}

void RestoreController::setBusy(bool busy)
{
    if (m_busy == busy) return;
    m_busy = busy;
    emit busyChanged(m_busy);
}

void RestoreController::setValid(bool valid)
{
    if (m_valid == valid) return;
    m_valid = valid;
    emit validChanged(m_valid);
}

CheckRestoreActivity::CheckRestoreActivity(Wallet* wallet, QObject* parent)
    : WalletActivity(wallet, parent)
{
}

AcceptRestoreActivity::AcceptRestoreActivity(Wallet* wallet, QObject* parent)
    : WalletActivity(wallet, parent)
{
}
