#include "handlers/loginhandler.h"
#include "network.h"
#include "restorecontroller.h"
#include "wallet.h"
#include "walletmanager.h"

RestoreController::RestoreController(QObject *parent)
    : Entity(parent)
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
    Q_ASSERT(m_wallet->isAuthenticated());
    Q_ASSERT(m_wallet->m_pin_data.isEmpty());
    Q_ASSERT(!m_accepted);
    m_accepted = true;

    auto activity = new AcceptRestoreActivity(m_wallet, this);
    m_wallet->pushActivity(activity);

    auto handler = new SetPinHandler(m_wallet, m_pin.toLocal8Bit());
    QObject::connect(handler, &Handler::done, this, [this, handler, activity] {
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
    bool valid = check();
    if (m_valid != valid) {
        m_valid = valid;
        emit validChanged(m_valid);
        if (!m_valid && m_wallet) {
            delete m_wallet;
            m_wallet = nullptr;
            emit walletChanged(m_wallet);
        }
    }

    if (!m_valid) return;

    if (!m_active && m_wallet) {
        // TODO delete wallet
    }

    if (m_active && !m_wallet) {
        qDebug() << "setup wallet and activate session";

        m_wallet = WalletManager::instance()->createWallet(m_network);
        emit walletChanged(m_wallet);

        m_wallet->createSession();
        m_session = m_wallet->session();
        m_session.track(QObject::connect(m_session, &Session::connectedChanged, this, &RestoreController::update));

        m_session->setActive(true);
    }

    if (m_active && m_wallet && m_wallet->m_session->isConnected()) {
        auto activity = new CheckRestoreActivity(m_wallet, this);
        m_wallet->pushActivity(activity);
        qDebug() << "attempt login with mnemonic and password";
        m_wallet->setAuthentication(Wallet::Authenticating);

        auto handler = new LoginHandler(m_wallet, m_mnemonic, m_password);
        QObject::connect(handler, &Handler::done, this, [this, handler, activity] {
           handler->deleteLater();
           m_wallet->updateHashId(handler->walletHashId());
           m_wallet->setAuthentication(Wallet::Authenticated);
           activity->finish();
           activity->deleteLater();
        });
        QObject::connect(handler, &Handler::error, this, [this, handler, activity] {
            handler->deleteLater();
            const auto error = handler->result().value("error").toString();
            // TODO: these are examples of errors
            // these sould be handled in Handler class, see TODO above
            // {"action":"get_xpubs","device":{},"error":"get_xpubs exception:login failed:id_login_failed","status":"error"}
            // {"action":"get_xpubs","device":{},"error":"get_xpubs exception:reconnect required","status":"error"}

            // TODO controller should expose error? or activity?
            m_wallet->setAuthentication(Wallet::Unauthenticated);
            activity->finish();
            activity->deleteLater();
            emit loginError(error);
        });
        handler->exec();
    }
}

CheckRestoreActivity::CheckRestoreActivity(Wallet* wallet, QObject* parent)
    : WalletActivity(wallet, parent)
{
}

AcceptRestoreActivity::AcceptRestoreActivity(Wallet* wallet, QObject* parent)
    : WalletActivity(wallet, parent)
{
}
