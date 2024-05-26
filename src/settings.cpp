#include "settings.h"

#include <QDebug>
#include <QFileInfo>
#include <QGuiApplication>
#include <QScreen>
#include <QSettings>
#include <QtGlobal>

#include "util.h"

#define LATEST_TOS_VERSION 1

Settings::Settings(QObject* parent)
    : QObject(parent)
{
    load();
    m_save_timer.setSingleShot(true);
    m_save_timer.setInterval(2000);
    connect(&m_save_timer, &QTimer::timeout, [this] {
        save();
    });
}

Settings::~Settings()
{
    save();
}

Settings* Settings::instance()
{
    static Settings settings;
    return &settings;
}

void Settings::setWindowX(int window_x)
{
    if (m_window_x == window_x) return;
    m_window_x = window_x;
    emit windowXChanged();
    saveLater();
}

void Settings::setWindowY(int window_y)
{
    if (m_window_y == window_y) return;
    m_window_y = window_y;
    emit windowYChanged();
    saveLater();
}

void Settings::setWindowWidth(int window_width)
{
    if (m_window_width == window_width) return;
    m_window_width = window_width;
    emit windowWidthChanged();
    saveLater();
}

void Settings::setWindowHeight(int window_height)
{
    if (m_window_height == window_height) return;
    m_window_height = window_height;
    emit windowHeightChanged();
    saveLater();
}

void Settings::setHistory(const QStringList &history)
{
    if (m_history == history) return;
    m_history = history;
    emit historyChanged();
    saveLater();
}

void Settings::setEnableTestnet(bool enable_testnet)
{
    if (m_enable_testnet == enable_testnet) return;
    m_enable_testnet = enable_testnet;
    emit enableTestnetChanged();
    saveLater();
}

void Settings::setUseProxy(bool use_proxy)
{
    if (m_use_proxy == use_proxy) return;
    m_use_proxy = use_proxy;
    emit useProxyChanged();
    saveLater();
}

void Settings::setUseTor(bool use_tor)
{
    if (m_use_tor == use_tor) return;
    m_use_tor = use_tor;
    emit useTorChanged();
    saveLater();
}

QStringList Settings::recentWallets()
{
    return m_recent_wallets;
}

void Settings::setLanguage(const QString& language)
{
    if (m_language == language) return;
    m_language = language;
    emit languageChanged();
    saveLater();
}

void Settings::setShowNews(bool show_news)
{
    if (m_show_news == show_news) return;
    m_show_news = show_news;
    emit showNewsChanged();
    saveLater();
}

void Settings::setEnableExperimental(bool enable_experimental)
{
    if (m_enable_experimental == enable_experimental) return;
    m_enable_experimental = enable_experimental;
    emit enableExperimentalChanged();
    saveLater();
}

void Settings::setLiquidElectrumUrl(const QString &liquid_electrum_url)
{
    if (m_liquid_electrum_url == liquid_electrum_url) return;
    m_liquid_electrum_url = liquid_electrum_url;
    emit liquidElectrumUrlChanged();
    saveLater();
}

void Settings::setLiquidTestnetElectrumUrl(const QString &liquid_testnet_electrum_url)
{
    if (m_liquid_testnet_electrum_url == liquid_testnet_electrum_url) return;
    m_liquid_testnet_electrum_url = liquid_testnet_electrum_url;
    emit liquidTestnetElectrumUrlChanged();
    saveLater();
}

void Settings::updateRecentWallet(const QString& id)
{
    m_recent_wallets.removeOne(id);
    m_recent_wallets.prepend(id);
    if (m_recent_wallets.size() > 10) m_recent_wallets.removeLast();
    emit recentWalletsChanged();
    saveLater();
}

void Settings::acceptTermsOfService()
{
    if (m_accepted_tos_version == LATEST_TOS_VERSION) return;
    m_accepted_tos_version = LATEST_TOS_VERSION;
    emit acceptedTermsOfServiceChanged();
    saveLater();
}

void Settings::toggleIncognito()
{
    setIncognito(!m_incognito);
}

void Settings::setRememberDevices(bool remember_devices)
{
    if (m_remember_devices == remember_devices) return;
    m_remember_devices = remember_devices;
    emit rememberDevicesChanged();
    saveLater();
}

void Settings::toggleRememberDevices()
{
    setRememberDevices(!m_remember_devices);
}

void Settings::setUsePersonalNode(bool use_personal_node)
{
    if (m_use_personal_node == use_personal_node) return;
    m_use_personal_node = use_personal_node;
    emit usePersonalNodeChanged();
    saveLater();
}

void Settings::setBitcoinElectrumUrl(const QString& bitcoin_electrum_url)
{
    if (m_bitcoin_electrum_url == bitcoin_electrum_url) return;
    m_bitcoin_electrum_url = bitcoin_electrum_url;
    emit bitcoinElectrumUrlChanged();
    saveLater();
}

void Settings::setTestnetElectrumUrl(const QString& testnet_electrum_url)
{
    if (m_testnet_electrum_url == testnet_electrum_url) return;
    m_testnet_electrum_url = testnet_electrum_url;
    emit testnetElectrumUrlChanged();
    saveLater();
}

void Settings::setEnableSPV(bool enable_spv)
{
    if (m_enable_spv == enable_spv) return;
    m_enable_spv = enable_spv;
    emit enableSPVChanged();
    saveLater();
}

void Settings::setAnalytics(const QString& analytics)
{
    if (m_analytics == analytics) return;
    m_analytics = analytics;
    emit analyticsChanged();
    saveLater();
}

bool Settings::acceptedTermsOfService() const
{
    return m_accepted_tos_version == LATEST_TOS_VERSION;
}

void Settings::setIncognito(bool incognito)
{
    if (m_incognito == incognito) return;
    m_incognito = incognito;
    emit incognitoChanged();
    saveLater();
}

void Settings::setProxyHost(const QString &proxy_host)
{
    if (m_proxy_host == proxy_host) return;
    m_proxy_host = proxy_host;
    emit proxyHostChanged();
    saveLater();
}

void Settings::setProxyPort(int proxy_port)
{
    if (m_proxy_port == proxy_port) return;
    m_proxy_port = proxy_port;
    emit proxyPortChanged();
    saveLater();
}

QString Settings::proxy() const
{
    if (!m_use_proxy) return QString();
    const auto host = m_proxy_host == "localhost" ? "127.0.0.1" : m_proxy_host;
    return QString("%1:%2").arg(host).arg(m_proxy_port);
}

void Settings::load()
{
    // By default position window in primary screen with a 100px margin
    auto default_rect = qGuiApp->primaryScreen()->geometry().adjusted(100, 100, -100, -100);
    default_rect.getRect(&m_window_x, &m_window_y, &m_window_width, &m_window_height);

    const auto path = GetDataFile("app", "settings.ini");
    if (QFileInfo::exists(path)) {
        QSettings settings(path, QSettings::IniFormat);
        load(settings);
    }

    // verify if window position is contained in any of the available screens and reposition in primary screen if necessary
    bool intersects = false;
    const QRect rect(m_window_x, m_window_y, m_window_width, m_window_height);
    for (QScreen* screen : qGuiApp->screens()) {
        intersects = screen->availableGeometry().intersects(rect);
        if (intersects) break;
    }
    if (!intersects) {
        default_rect.getRect(&m_window_x, &m_window_y, &m_window_width, &m_window_height);
    }
}

void Settings::load(const QSettings& settings)
{
#define LOAD(v) { const auto k = QLatin1String(QT_STRINGIFY(v)).mid(2); if (settings.contains(k)) v = settings.value(k).value<decltype (v)>(); }
    LOAD(m_window_x);
    LOAD(m_window_y);
    LOAD(m_window_width);
    LOAD(m_window_height);
    LOAD(m_history);
    LOAD(m_enable_testnet);
    LOAD(m_use_proxy)
    LOAD(m_proxy_host)
    LOAD(m_proxy_port)
    LOAD(m_use_tor)
    LOAD(m_recent_wallets)
    LOAD(m_language)
    LOAD(m_show_news)
    LOAD(m_enable_experimental)
    LOAD(m_use_personal_node)
    LOAD(m_bitcoin_electrum_url)
    LOAD(m_testnet_electrum_url)
    LOAD(m_liquid_electrum_url)
    LOAD(m_liquid_testnet_electrum_url)
    LOAD(m_enable_spv)
    LOAD(m_analytics)
    LOAD(m_accepted_tos_version)
    LOAD(m_incognito)
    LOAD(m_remember_devices)
#undef LOAD
}

void Settings::save()
{
    if (!m_needs_save) return;
    m_needs_save = false;
    saveNow();
}

void Settings::saveNow()
{
#define SAVE(v) settings.setValue(QLatin1String(QT_STRINGIFY(v)).mid(2), v);
    QSettings settings(GetDataFile("app", "settings.ini"), QSettings::IniFormat);
    SAVE(m_window_x);
    SAVE(m_window_y);
    SAVE(m_window_width);
    SAVE(m_window_height);
    SAVE(m_history);
    SAVE(m_enable_testnet);
    SAVE(m_use_proxy)
    SAVE(m_proxy_host)
    SAVE(m_proxy_port)
    SAVE(m_use_tor)
    SAVE(m_recent_wallets)
    SAVE(m_language)
    SAVE(m_show_news)
    SAVE(m_enable_experimental)
    SAVE(m_use_personal_node)
    SAVE(m_bitcoin_electrum_url)
    SAVE(m_testnet_electrum_url)
    SAVE(m_liquid_electrum_url)
    SAVE(m_liquid_testnet_electrum_url)
    SAVE(m_enable_spv)
    SAVE(m_analytics)
    SAVE(m_accepted_tos_version)
    SAVE(m_incognito)
    SAVE(m_remember_devices)
#undef SAVE
}

void Settings::saveLater()
{
    m_save_timer.start();
    m_needs_save = true;
}
