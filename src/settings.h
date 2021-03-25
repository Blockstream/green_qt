#ifndef GREEN_SETTINGS_H
#define GREEN_SETTINGS_H

#include <QObject>
#include <QTimer>

class Settings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int windowX READ windowX WRITE setWindowX NOTIFY windowXChanged)
    Q_PROPERTY(int windowY READ windowY WRITE setWindowY NOTIFY windowYChanged)
    Q_PROPERTY(int windowWidth READ windowWidth WRITE setWindowWidth NOTIFY windowWidthChanged)
    Q_PROPERTY(int windowHeight READ windowHeight WRITE setWindowHeight NOTIFY windowHeightChanged)
    Q_PROPERTY(QStringList history READ history WRITE setHistory NOTIFY historyChanged)
    Q_PROPERTY(bool collapseSideBar READ collapseSideBar WRITE setCollapseSideBar NOTIFY collapseSideBarChanged)
    Q_PROPERTY(bool enableTestnet READ enableTestnet WRITE setEnableTestnet NOTIFY enableTestnetChanged)
    Q_PROPERTY(bool useProxy READ useProxy WRITE setUseProxy NOTIFY useProxyChanged)
    Q_PROPERTY(QString proxyHost READ proxyHost WRITE setProxyHost NOTIFY proxyHostChanged)
    Q_PROPERTY(int proxyPort READ proxyPort WRITE setProxyPort NOTIFY proxyPortChanged)
    Q_PROPERTY(bool useTor READ useTor WRITE setUseTor NOTIFY useTorChanged)
    Q_PROPERTY(QStringList recentWallets READ recentWallets NOTIFY recentWalletsChanged)
public:
    Settings(QObject* parent = nullptr);
    virtual ~Settings();
    static Settings* instance();
    int windowX() const { return m_window_x; }
    void setWindowX(int window_x);
    int windowY() const { return m_window_y; }
    void setWindowY(int window_y);
    int windowWidth() const { return m_window_width; }
    void setWindowWidth(int window_width);
    int windowHeight() const { return m_window_height; }
    void setWindowHeight(int window_height);
    QStringList history() const { return m_history; }
    void setHistory(const QStringList& history);
    bool collapseSideBar() const { return m_collapse_side_bar; }
    void setCollapseSideBar(bool collapse_side_bar);
    bool enableTestnet() const { return m_enable_testnet; }
    void setEnableTestnet(bool enableTestnet);
    bool useProxy() const { return m_use_proxy; }
    void setUseProxy(bool use_proxy);
    QString proxyHost() const { return m_proxy_host; }
    void setProxyHost(const QString& proxy_host);
    int proxyPort() const { return m_proxy_port; }
    void setProxyPort(int proxy_port);
    QString proxy() const;
    bool useTor() const { return m_use_tor; }
    void setUseTor(bool use_tor);
    QStringList recentWallets();
public slots:
    void updateRecentWallet(const QString& id);
signals:
    void windowXChanged(int window_x);
    void windowYChanged(int window_y);
    void windowWidthChanged(int window_width);
    void windowHeightChanged(int window_height);
    void historyChanged(const QStringList& history);
    void collapseSideBarChanged(bool collapse_side_bar);
    void enableTestnetChanged(bool enable_testnet);
    void useProxyChanged(bool use_proxy);
    void proxyHostChanged(const QString& proxy_host);
    void proxyPortChanged(int proxy_port);
    void useTorChanged(bool use_tor);
    void recentWalletsChanged(const QStringList& recent_wallets);
private:
    void load();
    void save();
    void saveLater();
private:
    QTimer m_save_timer;
    bool m_needs_save{false};
    int m_window_x;
    int m_window_y;
    int m_window_width;
    int m_window_height;
    QStringList m_history;
    bool m_collapse_side_bar{false};
    bool m_enable_testnet{false};
    bool m_use_proxy{false};
    QString m_proxy_host{};
    int m_proxy_port{9001};
    bool m_use_tor{false};
    QStringList m_recent_wallets;
};

#endif // GREEN_SETTINGS_H
