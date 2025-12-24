#ifndef GREEN_BUYBITCOINQUOTESERVICE_H
#define GREEN_BUYBITCOINQUOTESERVICE_H

#include "controller.h"

#include <QtQml>

#include <QJsonValue>
#include <QNetworkReply>
#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

class BuyBitcoinQuoteService : public Controller
{
    Q_OBJECT
    Q_PROPERTY(double bestDestinationAmount READ bestDestinationAmount NOTIFY quoteChanged)
    Q_PROPERTY(QString bestServiceProvider READ bestServiceProvider NOTIFY quoteChanged)
    Q_PROPERTY(QVariantList allQuotes READ allQuotes NOTIFY quoteChanged)
    Q_PROPERTY(QVariantMap selectedQuote READ selectedQuote NOTIFY selectedQuoteChanged)
    Q_PROPERTY(double selectedDestinationAmount READ selectedDestinationAmount NOTIFY selectedQuoteChanged)
    Q_PROPERTY(QString selectedServiceProvider READ selectedServiceProvider NOTIFY selectedQuoteChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(bool widgetLoading READ widgetLoading NOTIFY widgetLoadingChanged)
    Q_PROPERTY(QString widgetError READ widgetError NOTIFY widgetErrorChanged)
    Q_PROPERTY(QString widgetUrl READ widgetUrl NOTIFY widgetUrlChanged)
    Q_PROPERTY(QStringList recentlyUsedProviders READ recentlyUsedProviders NOTIFY recentlyUsedProvidersChanged)
    Q_PROPERTY(QJsonValue buyDefaultValues READ buyDefaultValues NOTIFY buyDefaultValuesChanged)
    QML_ELEMENT
public:
    explicit BuyBitcoinQuoteService(QObject* parent = nullptr);

    double bestDestinationAmount() const { return m_best_destination_amount; }
    QString bestServiceProvider() const { return m_best_service_provider; }
    QVariantList allQuotes() const { return m_all_quotes; }
    QVariantMap selectedQuote() const { return m_selected_quote; }
    double selectedDestinationAmount() const;
    QString selectedServiceProvider() const;
    bool loading() const { return m_loading; }
    QString error() const { return m_error; }
    bool widgetLoading() const { return m_widget_loading; }
    QString widgetError() const { return m_widget_error; }
    QString widgetUrl() const { return m_widget_url; }
    QStringList recentlyUsedProviders() const { return m_recently_used_providers; }
    QJsonValue buyDefaultValues() const;

    Q_INVOKABLE void fetchQuote(const QString& countryCode, double sourceAmount, const QString& sourceCurrencyCode, const QString& walletAddress);
    Q_INVOKABLE void clearQuote();
    Q_INVOKABLE void setSelectedQuote(const QVariantMap& quote);
    Q_INVOKABLE void createWidgetSession(const QString& serviceProvider, const QString& countryCode, double sourceAmount, const QString& sourceCurrencyCode, const QString& walletAddress, bool useDebugMode = false);

signals:
    void quoteChanged();
    void selectedQuoteChanged();
    void loadingChanged();
    void errorChanged();
    void widgetLoadingChanged();
    void widgetErrorChanged();
    void widgetUrlChanged();
    void buyDefaultValuesChanged();
    void recentlyUsedProvidersChanged();

private slots:
    void updateBuyDefaultValues();
    void onReplyFinished();
    void onWidgetReplyFinished();
    void onTransactionsReplyFinished();

private:
    void sortQuotes();
    double m_best_destination_amount{0.0};
    QString m_best_service_provider;
    QVariantList m_all_quotes;
    QVariantMap m_selected_quote;
    bool m_loading{false};
    QString m_error;
    QNetworkReply* m_reply{nullptr};
    bool m_widget_loading{false};
    QString m_widget_error;
    QString m_widget_url;
    QNetworkReply* m_widget_reply{nullptr};
    QJsonValue m_buy_default_values;
    QNetworkReply* m_transactions_reply{nullptr};
    QString m_pending_country_code;
    double m_pending_source_amount{0.0};
    QString m_pending_source_currency_code;
    QString m_pending_wallet_address;
    QString m_preferred_provider;
    QStringList m_recently_used_providers;
};

class PaymentSyncController : public Controller
{
    Q_OBJECT
    QML_ELEMENT
public:
    PaymentSyncController(QObject* parent = nullptr);
private:
    void sync();
};

#endif // GREEN_BUYBITCOINQUOTESERVICE_H
