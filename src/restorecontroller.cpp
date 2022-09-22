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
    if (!m_wallet) {
        m_wallet = WalletManager::instance()->restoreWallet(m_network, m_wallet_hash_id);
        emit walletChanged(m_wallet);
    }
    m_wallet->setSession(m_session);
    m_wallet->setSession();
    m_session = nullptr;

    Q_ASSERT(m_wallet->isAuthenticated());
    Q_ASSERT(m_wallet->m_pin_data.isEmpty());
    Q_ASSERT(!m_accepted);
    m_accepted = true;
    emit acceptedChanged(m_accepted);

    auto activity = new AcceptRestoreActivity(m_wallet, this);
    m_wallet->pushActivity(activity);

    QJsonObject credentials({
        { "mnemonic", m_mnemonic.join(" ") },
        { "password", m_password }
    });

    auto handler = new EncryptWithPinHandler(credentials, m_pin, m_wallet->session());
    QObject::connect(handler, &Handler::done, this, [=] {
        handler->deleteLater();
        m_wallet->m_login_attempts_remaining = 3;
        m_wallet->m_pin_data = handler->pinData();
        if (m_wallet->name().isEmpty()) {
            if (m_type == "amp") {
                Q_ASSERT(m_network->isLiquid());
                m_wallet->setName(WalletManager::instance()->uniqueWalletName("My AMP Wallet"));
            } else {
                m_wallet->setName(WalletManager::instance()->newWalletName(m_network));
            }
        }

        WalletManager::instance()->insertWallet(m_wallet);

        activity->finish();
        activity->deleteLater();

        emit finished();
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

    if (m_wallet_hash_id.isEmpty()) {
        auto handler = new LoginHandler(m_mnemonic, m_password, m_session);
        QObject::connect(handler, &Handler::done, this, [=] {
            handler->deleteLater();
            m_wallet_hash_id = handler->walletHashId();
            update();
        });
        QObject::connect(handler, &Handler::error, this, [=] {
            handler->deleteLater();
            const auto error = handler->result().value("error").toString();

            updateError("password", QStringLiteral("mismatch"), error.indexOf("Invalid checksum") >= 0);

            setValid(false);
            setBusy(false);
        });
        handler->exec();
        return;
    }

    m_wallet = WalletManager::instance()->walletWithHashId(m_wallet_hash_id, false);
    if (m_wallet) {
        setBusy(false);
        setValid(!m_wallet->hasPinData());
        emit walletChanged(m_wallet);
        return;
    }

    if (!m_network->isElectrum()) {
        setBusy(false);
        setValid(true);
        return;
    }

    if (m_subaccounts.isEmpty()) {
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
