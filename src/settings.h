#ifndef GREEN_SETTINGS_H
#define GREEN_SETTINGS_H

#include <QObject>
#include <QTimer>

class QSettings;

class Settings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int windowX READ windowX WRITE setWindowX NOTIFY windowXChanged)
    Q_PROPERTY(int windowY READ windowY WRITE setWindowY NOTIFY windowYChanged)
    Q_PROPERTY(int windowWidth READ windowWidth WRITE setWindowWidth NOTIFY windowWidthChanged)
    Q_PROPERTY(int windowHeight READ windowHeight WRITE setWindowHeight NOTIFY windowHeightChanged)
    Q_PROPERTY(QStringList history READ history WRITE setHistory NOTIFY historyChanged)
    Q_PROPERTY(bool enableTestnet READ enableTestnet WRITE setEnableTestnet NOTIFY enableTestnetChanged)
    Q_PROPERTY(bool useProxy READ useProxy WRITE setUseProxy NOTIFY useProxyChanged)
    Q_PROPERTY(QString proxyHost READ proxyHost WRITE setProxyHost NOTIFY proxyHostChanged)
    Q_PROPERTY(int proxyPort READ proxyPort WRITE setProxyPort NOTIFY proxyPortChanged)
    Q_PROPERTY(bool useTor READ useTor WRITE setUseTor NOTIFY useTorChanged)
    Q_PROPERTY(QStringList recentWallets READ recentWallets NOTIFY recentWalletsChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString country READ country NOTIFY languageChanged)
    Q_PROPERTY(bool showNews READ showNews WRITE setShowNews NOTIFY showNewsChanged)
    Q_PROPERTY(bool enableExperimental READ enableExperimental WRITE setEnableExperimental NOTIFY enableExperimentalChanged)
    Q_PROPERTY(bool usePersonalNode READ usePersonalNode WRITE setUsePersonalNode NOTIFY usePersonalNodeChanged)
    Q_PROPERTY(bool enableElectrumTls READ enableElectrumTls WRITE setEnableElectrumTls NOTIFY enableElectrumTlsChanged)
    Q_PROPERTY(QString bitcoinElectrumUrl READ bitcoinElectrumUrl WRITE setBitcoinElectrumUrl NOTIFY bitcoinElectrumUrlChanged)
    Q_PROPERTY(QString testnetElectrumUrl READ testnetElectrumUrl WRITE setTestnetElectrumUrl NOTIFY testnetElectrumUrlChanged)
    Q_PROPERTY(QString liquidElectrumUrl READ liquidElectrumUrl WRITE setLiquidElectrumUrl NOTIFY liquidElectrumUrlChanged)
    Q_PROPERTY(QString liquidTestnetElectrumUrl READ liquidTestnetElectrumUrl WRITE setLiquidTestnetElectrumUrl NOTIFY liquidTestnetElectrumUrlChanged)
    Q_PROPERTY(bool enableSPV READ enableSPV WRITE setEnableSPV NOTIFY enableSPVChanged)
    Q_PROPERTY(QString analytics READ analytics WRITE setAnalytics NOTIFY analyticsChanged)
    Q_PROPERTY(bool acceptedTermsOfService READ acceptedTermsOfService NOTIFY acceptedTermsOfServiceChanged)
    Q_PROPERTY(bool incognito READ incognito NOTIFY incognitoChanged)
    Q_PROPERTY(bool rememberDevices READ rememberDevices NOTIFY rememberDevicesChanged)
    Q_PROPERTY(QStringList promosDismissed READ promosDismissed NOTIFY promosDismissedChanged)
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
    QString language() const { return m_language; }
    void setLanguage(const QString& language);
    QString country() const;
    bool showNews() const { return m_show_news; }
    void setShowNews(bool show_news);
    bool enableExperimental() const { return m_enable_experimental; }
    void setEnableExperimental(bool enable_experimental);
    bool usePersonalNode() const { return m_use_personal_node; }
    void setUsePersonalNode(bool use_personal_node);
    bool enableElectrumTls() const { return m_enable_electrum_tls; }
    void setEnableElectrumTls(bool enable_electrum_tls);
    QString bitcoinElectrumUrl() const { return m_bitcoin_electrum_url; }
    void setBitcoinElectrumUrl(const QString& bitcoin_electrum_url);
    QString testnetElectrumUrl() const { return m_testnet_electrum_url; }
    void setTestnetElectrumUrl(const QString& testnet_electrum_url);
    QString liquidElectrumUrl() const { return m_liquid_electrum_url; }
    void setLiquidElectrumUrl(const QString& liquid_electrum_url);
    QString liquidTestnetElectrumUrl() const { return m_liquid_testnet_electrum_url; }
    void setLiquidTestnetElectrumUrl(const QString& liquid_testnet_electrum_url);
    bool enableSPV() const { return m_enable_spv; }
    void setEnableSPV(bool enable_spv);
    bool isAnalyticsEnabled() const { return m_analytics == "enabled"; }
    QString analytics() const { return m_analytics; }
    void setAnalytics(const QString& analytics);
    bool acceptedTermsOfService() const;
    bool incognito() const { return m_incognito; }
    void setIncognito(bool incognito);
    bool rememberDevices() const { return m_remember_devices; }
    void setRememberDevices(bool remember_devices);
    QStringList promosDismissed() const { return m_promos_dismissed; }
    Q_INVOKABLE bool isEventRegistered(const QJsonObject& event);
    Q_INVOKABLE void registerEvent(const QJsonObject& event);
public slots:
    void updateRecentWallet(const QString& id);
    void acceptTermsOfService();
    void toggleIncognito();
    void toggleRememberDevices();
    void dismissPromo(const QString& id);
signals:
    void windowXChanged();
    void windowYChanged();
    void windowWidthChanged();
    void windowHeightChanged();
    void historyChanged();
    void enableTestnetChanged();
    void useProxyChanged();
    void proxyHostChanged();
    void proxyPortChanged();
    void useTorChanged();
    void recentWalletsChanged();
    void languageChanged();
    void showNewsChanged();
    void enableExperimentalChanged();
    void usePersonalNodeChanged();
    void enableElectrumTlsChanged();
    void bitcoinElectrumUrlChanged();
    void testnetElectrumUrlChanged();
    void liquidElectrumUrlChanged();
    void liquidTestnetElectrumUrlChanged();
    void enableSPVChanged();
    void analyticsChanged();
    void acceptedTermsOfServiceChanged();
    void incognitoChanged();
    void rememberDevicesChanged();
    void promosDismissedChanged();
private:
    void load();
    void load(const QSettings& settings);
    void save();
    void saveNow();
    void saveLater();
private:
    QTimer m_save_timer;
    bool m_needs_save{false};
    int m_window_x;
    int m_window_y;
    int m_window_width;
    int m_window_height;
    QStringList m_history;
    bool m_enable_testnet{false};
    bool m_use_proxy{false};
    QString m_proxy_host{};
    int m_proxy_port{9001};
    bool m_use_tor{false};
    QStringList m_recent_wallets;
    QString m_language;
    bool m_show_news{true};
    bool m_enable_experimental{false};
    bool m_use_personal_node{false};
    bool m_enable_electrum_tls{true};
    QString m_bitcoin_electrum_url;
    QString m_testnet_electrum_url;
    QString m_liquid_electrum_url;
    QString m_liquid_testnet_electrum_url;
    bool m_enable_spv{false};
    QString m_analytics;
    int m_accepted_tos_version{0};
    bool m_incognito{false};
    bool m_remember_devices{true};
    QStringList m_promos_dismissed;
    QStringList m_registered_events;
};

#endif // GREEN_SETTINGS_H
