#ifndef GREEN_BUYBITCOINQUOTESERVICE_H
#define GREEN_BUYBITCOINQUOTESERVICE_H

#include <QObject>
#include <QNetworkReply>
#include <QVariantList>
#include <QVariantMap>
#include <QJsonValue>
#include <QtQml>

class BuyBitcoinQuoteService : public QObject
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
    QML_ELEMENT
    QML_SINGLETON
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

    Q_INVOKABLE void fetchQuote(const QString& countryCode, double sourceAmount, const QString& sourceCurrencyCode, const QString& walletAddress);
    Q_INVOKABLE void clearQuote();
    Q_INVOKABLE void setSelectedQuote(const QVariantMap& quote);
    Q_INVOKABLE void createWidgetSession(const QString& serviceProvider, const QString& countryCode, double sourceAmount, const QString& sourceCurrencyCode, const QString& walletAddress, bool useDebugMode = false);
    Q_INVOKABLE QJsonValue getBuyDefaultValues() const;

signals:
    void quoteChanged();
    void selectedQuoteChanged();
    void loadingChanged();
    void errorChanged();
    void widgetLoadingChanged();
    void widgetErrorChanged();
    void widgetUrlChanged();
    void buyDefaultValuesChanged();

private slots:
    void updateBuyDefaultValues();
    void onReplyFinished();
    void onWidgetReplyFinished();

private:
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
};

#endif // GREEN_BUYBITCOINQUOTESERVICE_H

