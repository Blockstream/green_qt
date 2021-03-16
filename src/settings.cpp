#include "settings.h"

#include <QtGlobal>
#include <QGuiApplication>
#include <QScreen>
#include <QSettings>

Settings::Settings(QObject* parent)
    : QObject(parent)
{
    load();
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
    emit windowXChanged(m_window_x);
}

void Settings::setWindowY(int window_y)
{
    if (m_window_y == window_y) return;
    m_window_y = window_y;
    emit windowYChanged(m_window_y);
}

void Settings::setWindowWidth(int window_width)
{
    if (m_window_width == window_width) return;
    m_window_width = window_width;
    emit windowWidthChanged(m_window_width);
}

void Settings::setWindowHeight(int window_height)
{
    if (m_window_height == window_height) return;
    m_window_height = window_height;
    emit windowHeightChanged(m_window_height);
}

void Settings::setHistory(const QStringList &history)
{
    if (m_history == history) return;
    m_history = history;
    emit historyChanged(m_history);
}

void Settings::setCollapseSideBar(bool collapse_side_bar)
{
    if (m_collapse_side_bar == collapse_side_bar) return;
    m_collapse_side_bar = collapse_side_bar;
    emit collapseSideBarChanged(m_collapse_side_bar);
}

void Settings::setEnableTestnet(bool enableTestnet)
{
    if (m_enable_testnet == enableTestnet) return;
    m_enable_testnet = enableTestnet;
    emit enableTestnetChanged(m_enable_testnet);
}

void Settings::setUseProxy(bool use_proxy)
{
    if (m_use_proxy == use_proxy) return;
    m_use_proxy = use_proxy;
    emit useProxyChanged(m_use_proxy);
}

void Settings::setUseTor(bool use_tor)
{
    if (m_use_tor == use_tor) return;
    m_use_tor = use_tor;
    emit useTorChanged(m_use_tor);
}

QStringList Settings::recentWallets()
{
    return m_recent_wallets;
}

void Settings::updateRecentWallet(const QString& id)
{
    m_recent_wallets.removeOne(id);
    m_recent_wallets.prepend(id);
    if (m_recent_wallets.size() > 3) m_recent_wallets.removeLast();
    emit recentWalletsChanged(m_recent_wallets);
}

void Settings::setProxyHost(const QString &proxy_host)
{
    if (m_proxy_host == proxy_host) return;
    m_proxy_host = proxy_host;
    emit proxyHostChanged(m_proxy_host);
}

void Settings::setProxyPort(int proxy_port)
{
    if (m_proxy_port == proxy_port) return;
    m_proxy_port = proxy_port;
    emit proxyPortChanged(m_proxy_port);
}

QString Settings::proxy() const
{
    return m_use_proxy ? QString("%1:%2").arg(m_proxy_host).arg(m_proxy_port) : "";
}

void Settings::load()
{
    // By default position window in primary screen with a 200px margin
    qGuiApp->primaryScreen()->geometry().adjusted(200, 200, -200, -200).getRect(&m_window_x, &m_window_y, &m_window_width, &m_window_height);

#define LOAD(v) { const auto k = QLatin1String(QT_STRINGIFY(v)).mid(2); if (settings.contains(k)) v = settings.value(k).value<decltype (v)>(); }
    QSettings settings;
    LOAD(m_window_x);
    LOAD(m_window_y);
    LOAD(m_window_width);
    LOAD(m_window_height);
    LOAD(m_history);
    LOAD(m_collapse_side_bar);
    LOAD(m_enable_testnet);
    LOAD(m_use_proxy)
    LOAD(m_proxy_host)
    LOAD(m_proxy_port)
    LOAD(m_use_tor)
    LOAD(m_recent_wallets)
#undef LOAD
}

void Settings::save()
{
#define SAVE(v) settings.setValue(QLatin1String(QT_STRINGIFY(v)).mid(2), v);
    QSettings settings;
    SAVE(m_window_x);
    SAVE(m_window_y);
    SAVE(m_window_width);
    SAVE(m_window_height);
    SAVE(m_history);
    SAVE(m_collapse_side_bar);
    SAVE(m_enable_testnet);
    SAVE(m_use_proxy)
    SAVE(m_proxy_host)
    SAVE(m_proxy_port)
    SAVE(m_use_tor)
    SAVE(m_recent_wallets)
#undef SAVE
}
