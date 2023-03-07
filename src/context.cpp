#include "account.h"
#include "asset.h"
#include "context.h"
#include "device.h"
#include "json.h"
#include "network.h"
#include "session.h"
#include "wallet.h"

#include <gdk.h>
#include <nlohmann/json.hpp>

namespace {
void UpdateAsset(GA_session* session, Asset* asset)
{
    const auto id = asset->id().toStdString();

    const nlohmann::json params = {{ "assets_id", { id } }};
    nlohmann::json* output;

    const auto err = GA_get_assets(session, (const GA_json*) &params, (GA_json**) &output);
    Q_ASSERT(err == GA_OK);

    if (output->at("assets").contains(id)) {
        const auto data = output->at("assets").at(id);
        asset->setData(Json::toObject((GA_json*) &data));
    }
    if (output->at("icons").contains(id)) {
        const auto icon = output->at("icons").at(id).get<std::string>();
        asset->setIcon(QString("data:image/png;base64,") + QString::fromStdString(icon));
    }
    GA_destroy_json((GA_json*) output);
}
}


Context::Context(QObject* parent)
    : QObject(parent)
{
}

void Context::setWallet(Wallet* wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged();

    if (m_wallet && !m_network) {
        const auto network = m_wallet->network();
        if (network) setNetwork(network);
    }
}

void Context::setNetwork(Network* network)
{
    if (m_network == network) return;
    m_network = network;
    emit networkChanged();

    if (m_network && !m_session) {
        m_session = new Session(m_network, this);
        m_session->setActive(true);
        emit sessionChanged();
        connect(m_session, &Session::blockEvent, this, [=](const QJsonObject& event) {
            for (auto account : m_accounts) {
                emit account->blockEvent(event);
            }
        });
        connect(m_session, &Session::settingsEvent, this, [this](const QJsonObject& settings) {
            setSettings(settings);
        });
        connect(m_session, &Session::twoFactorResetEvent, this, [this](const QJsonObject& event) {
            setLocked(event.value("is_active").toBool());
        });
        connect(m_session,  &Session::transactionEvent, this, [this](const QJsonObject& transaction) {
            for (auto pointer : transaction.value("subaccounts").toArray()) {
                auto account = m_accounts_by_pointer.value(pointer.toInt());
                if (account) {
                    emit account->transactionEvent(transaction);
                }
            }
            emit hasBalanceChanged();
        });
    }
    if (!m_network && m_session) {
        delete m_session;
        m_session = nullptr;
        emit sessionChanged();
    }
}

void Context::setDevice(Device* device)
{
    if (m_device == device) return;
    m_device = device;
    if (m_device) {
        QObject::connect(m_device, &QObject::destroyed, this, [=] {
            setDevice(nullptr);
        });

        if (m_wallet) {
            m_wallet->updateDeviceDetails(m_device->details());
        }
    }
    emit deviceChanged();
}

void Context::setCredentials(const QJsonObject &credentials)
{
    if (m_credentials == credentials) return;
    m_credentials = credentials;
    emit credentialsChanged();
    setMnemonic(credentials.value("mnemonic").toString().split(" "));
}

void Context::setMnemonic(const QStringList& mnemonic)
{
    if (m_mnemonic == mnemonic) return;
    m_mnemonic = mnemonic;
    emit mnemonicChanged();
}

void Context::setLocked(bool locked)
{
    if (m_locked == locked) return;
    m_locked = locked;
    emit lockedChanged();
}

void Context::setSettings(const QJsonObject& settings)
{
    if (m_settings == settings) return;
    m_settings = settings;
    emit settingsChanged();

    setUnit(m_settings.value("unit").toString());
    setAltimeout(m_settings.value("altimeout").toInt());
}

void Context::setUnit(const QString &unit)
{
    if (m_unit == unit) return;
    m_unit = unit;
    m_display_unit = ComputeDisplayUnit(m_network, m_unit);
    emit unitChanged();
}

void Context::setAltimeout(int altimeout)
{
    if (m_altimeout == altimeout) return;
    m_altimeout = altimeout;
    if (m_logout_timer != -1) {
        killTimer(m_logout_timer);
        m_logout_timer = -1;
    }
    if (m_device) return;
    if (m_altimeout > 0) {
        m_logout_timer = startTimer(m_altimeout * 60 * 1000);
        qApp->installEventFilter(this);
    } else {
        qApp->removeEventFilter(this);
    }
}

void Context::setConfig(const QJsonObject& config)
{
    if (m_config == config) return;
    m_config = config;
    emit configChanged();
    setLocked(m_config.value("twofactor_reset").toObject().value("is_active").toBool());
}

void Context::setCurrencies(const QJsonObject& currencies)
{
    if (m_currencies == currencies) return;
    m_currencies = currencies;
    emit currenciesChanged();
}

void Context::setEvents(const QJsonObject& events)
{
    if (m_events == events) return;
    m_events = events;
    emit eventsChanged();
}

void Context::setUsername(const QString& username)
{
    if (m_username == username) return;
    m_username = username;
    emit usernameChanged();
}

void Context::setWatchonly(bool watchonly)
{
    if (m_watchonly == watchonly) return;
    m_watchonly = watchonly;
    emit watchonlyChanged();
}

bool Context::hasBalance() const
{
    for (const auto& account : m_accounts) {
        if (account->hasBalance()) return true;
    }
    return false;
}

bool Context::eventFilter(QObject *object, QEvent *event)
{
    switch (event->type()) {
    case QEvent::MouseButtonPress:
    case QEvent::MouseButtonRelease:
    case QEvent::MouseButtonDblClick:
    case QEvent::MouseMove:
    case QEvent::KeyPress:
    case QEvent::KeyRelease:
    case QEvent::Wheel:
    {
        Q_ASSERT(m_logout_timer != -1);
        killTimer(m_logout_timer);
        m_logout_timer = startTimer(m_altimeout * 60 * 1000);
        break;
    }
    default:
        break;
    }
    return QObject::eventFilter(object, event);
}

void Context::timerEvent(QTimerEvent* event)
{
    if (event->timerId() == m_logout_timer) {
        killTimer(m_logout_timer);
        if (m_wallet) m_wallet->setContext(nullptr);
        deleteLater();
    }
}

Asset* Context::getOrCreateAsset(const QString& id)
{
    Q_ASSERT(m_network && m_network->isLiquid());
    Q_ASSERT(m_session);
    Q_ASSERT(id != "btc");

    Asset* asset = m_assets.value(id);
    if (!asset) {
        asset = new Asset(id, this);
        m_assets.insert(id, asset);
        UpdateAsset(m_session->m_session, asset);
    }
    return asset;
}

Account* Context::getOrCreateAccount(const QJsonObject& data)
{
    Q_ASSERT(data.contains("pointer"));
    const int pointer = data.value("pointer").toInt();
    Account* account = m_accounts_by_pointer.value(pointer);
    if (account) {
        account->update(data);
    } else {
        account = new Account(data, m_network, this);
        m_accounts_by_pointer.insert(pointer, account);
    }
    return account;
}

Account* Context::getAccountByPointer(int pointer) const
{
    return m_accounts_by_pointer[pointer];
}

QQmlListProperty<Account> Context::accounts()
{
    return { this, &m_accounts };
}
