#include "buybitcoinquoteservice.h"

#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QQmlEngine>
#include <QRegularExpression>
#include <QUrl>

#include <algorithm>

#include <countly/countly.hpp>

#include "analytics.h"

BuyBitcoinQuoteService::BuyBitcoinQuoteService(QObject* parent)
    : QObject(parent)
{
    // Connect to Analytics remote config changes to update buy default values
    connect(Analytics::instance(), &Analytics::remoteConfigChanged, this, &BuyBitcoinQuoteService::updateBuyDefaultValues);
    // Initial update
    updateBuyDefaultValues();
}

void BuyBitcoinQuoteService::clearQuote()
{
    // Cancel any pending request
    if (m_reply) {
        disconnect(m_reply, &QNetworkReply::finished, this, &BuyBitcoinQuoteService::onReplyFinished);
        m_reply->abort();
        m_reply->deleteLater();
        m_reply = nullptr;
    }

    // Cancel any pending transactions request
    if (m_transactions_reply) {
        disconnect(m_transactions_reply, &QNetworkReply::finished, this, &BuyBitcoinQuoteService::onTransactionsReplyFinished);
        m_transactions_reply->abort();
        m_transactions_reply->deleteLater();
        m_transactions_reply = nullptr;
    }

    // Reset state
    bool hasState = m_best_destination_amount != 0.0 || m_loading || !m_error.isEmpty() || !m_best_service_provider.isEmpty() || !m_all_quotes.isEmpty() || !m_selected_quote.isEmpty();
    if (hasState) {
        m_best_destination_amount = 0.0;
        m_best_service_provider = QString();
        m_all_quotes.clear();
        m_selected_quote.clear();
        m_loading = false;
        m_error = QString();
        m_preferred_provider = QString();
        if (!m_recently_used_providers.isEmpty()) {
            m_recently_used_providers.clear();
            emit recentlyUsedProvidersChanged();
        }
        emit quoteChanged();
        emit selectedQuoteChanged();
        emit loadingChanged();
        emit errorChanged();
    }
}

void BuyBitcoinQuoteService::setSelectedQuote(const QVariantMap& quote)
{
    if (m_selected_quote != quote) {
        m_selected_quote = quote;
        emit selectedQuoteChanged();
    }
}

double BuyBitcoinQuoteService::selectedDestinationAmount() const
{
    return m_selected_quote.value("destinationAmount").toDouble();
}

QString BuyBitcoinQuoteService::selectedServiceProvider() const
{
    return m_selected_quote.value("serviceProvider").toString();
}

void BuyBitcoinQuoteService::fetchQuote(const QString& countryCode, double sourceAmount, const QString& sourceCurrencyCode, const QString& walletAddress, const QString& walletHashedId)
{
    // Cancel any pending request
    if (m_reply) {
        disconnect(m_reply, &QNetworkReply::finished, this, &BuyBitcoinQuoteService::onReplyFinished);
        m_reply->abort();
        m_reply->deleteLater();
        m_reply = nullptr;
    }

    // Cancel any pending transactions request
    if (m_transactions_reply) {
        disconnect(m_transactions_reply, &QNetworkReply::finished, this, &BuyBitcoinQuoteService::onTransactionsReplyFinished);
        m_transactions_reply->abort();
        m_transactions_reply->deleteLater();
        m_transactions_reply = nullptr;
    }

    // Validate input
    if (sourceAmount <= 0 || sourceCurrencyCode.isEmpty() || walletAddress.isEmpty()) {
        m_best_destination_amount = 0.0;
        m_error = QString();
        emit quoteChanged();
        return;
    }

    // If wallet_hashed_id is provided, fetch transactions first to pre-select provider
    if (!walletHashedId.isEmpty()) {
        m_pending_wallet_hashed_id = walletHashedId;
        m_pending_country_code = countryCode;
        m_pending_source_amount = sourceAmount;
        m_pending_source_currency_code = sourceCurrencyCode;
        m_pending_wallet_address = walletAddress;

        // Set loading state
        m_loading = true;
        m_error = QString();
        emit loadingChanged();
        emit errorChanged();

        // Fetch transactions
        auto engine = qmlEngine(this);
        if (!engine) {
            m_loading = false;
            m_error = "QML engine not available";
            emit loadingChanged();
            emit errorChanged();
            return;
        }

        auto net = engine->networkAccessManager();
        if (!net) {
            m_loading = false;
            m_error = "Network access manager not available";
            emit loadingChanged();
            emit errorChanged();
            return;
        }

        QUrl url("https://ramps.blockstream.com/payments/transactions");
        QUrlQuery query;
        query.addQueryItem("externalCustomerIds", walletHashedId);
        url.setQuery(query);

        QNetworkRequest req(url);
        m_transactions_reply = net->get(req);
        connect(m_transactions_reply, &QNetworkReply::finished, this, &BuyBitcoinQuoteService::onTransactionsReplyFinished);
        return;
    }

    // Set loading state
    m_loading = true;
    m_error = QString();
    emit loadingChanged();
    emit errorChanged();

    // Prepare JSON request body
    QJsonObject requestData;
    requestData["countryCode"] = countryCode;
    requestData["destinationCurrencyCode"] = "BTC";
    requestData["sourceAmount"] = sourceAmount;
    requestData["sourceCurrencyCode"] = sourceCurrencyCode;
    requestData["walletAddress"] = walletAddress;
    requestData["paymentMethodType"] = "CARD";

    QJsonDocument doc(requestData);
    QByteArray jsonData = doc.toJson(QJsonDocument::Compact);

    // Get network access manager
    auto engine = qmlEngine(this);
    if (!engine) {
        m_loading = false;
        m_error = "QML engine not available";
        emit loadingChanged();
        emit errorChanged();
        return;
    }

    auto net = engine->networkAccessManager();
    if (!net) {
        m_loading = false;
        m_error = "Network access manager not available";
        emit loadingChanged();
        emit errorChanged();
        return;
    }

    // Make POST request
    QNetworkRequest req(QUrl("https://ramps.blockstream.com/payments/crypto/quote"));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    m_reply = net->post(req, jsonData);
    connect(m_reply, &QNetworkReply::finished, this, &BuyBitcoinQuoteService::onReplyFinished);
}

void BuyBitcoinQuoteService::onReplyFinished()
{
    auto reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    // Check if this is still the current reply
    if (reply != m_reply) {
        // This is a stale reply, ignore it
        reply->deleteLater();
        return;
    }

    // Disconnect and clear the reply reference before processing
    disconnect(reply, &QNetworkReply::finished, this, &BuyBitcoinQuoteService::onReplyFinished);
    m_reply = nullptr;

    m_loading = false;
    emit loadingChanged();

    // Read data before deleteLater to avoid potential issues
    QByteArray data = reply->readAll();
    QNetworkReply::NetworkError error = reply->error();
    QString errorString = reply->errorString();

    reply->deleteLater();

    // Even if there's a network error, try to parse the response body
    // as the server might have returned an error message in JSON format
    QJsonParseError parseError;
    QJsonObject json;
    
    if (!data.isEmpty()) {
        json = QJsonDocument::fromJson(data, &parseError).object();
    }

    // Priority 1: Check for error code in JSON (like INVALID_AMOUNT_TOO_HIGH)
    // This takes precedence over network errors as it contains the actual error message
    if (!json.isEmpty() && json.contains("code")) {
        // Extract only the message field, ignoring any errors array
        QJsonValue messageValue = json.value("message");
        QString message;
        
        if (messageValue.isString()) {
            message = messageValue.toString().trimmed();
        }
        
        m_best_destination_amount = 0.0;
        
        // Clean up the message - remove any trailing "errors:" or error array text
        // Sometimes the message might contain additional formatting we don't want
        // Handle variations like "errors:", "Errors:", "ERRORS:", "errors :", etc.
        QRegularExpression errorsPattern(R"(\s*[Ee]rrors?\s*:.*)", QRegularExpression::CaseInsensitiveOption);
        message.remove(errorsPattern);
        message = message.trimmed();
        
        // Also check for common patterns that might indicate array serialization
        // Remove things like "[...]" that might appear at the end
        if (message.endsWith(']')) {
            int lastBracket = message.lastIndexOf('[');
            if (lastBracket > 0) {
                message = message.left(lastBracket).trimmed();
            }
        }
        
        m_error = message.isEmpty() ? "Request failed" : message;
        emit errorChanged();
        emit quoteChanged();
        return;
    }

    // Priority 2: Check for error field in JSON
    if (!json.isEmpty() && json.contains("error") && !json["error"].isNull()) {
        m_best_destination_amount = 0.0;
        m_error = json["error"].toString();
        emit errorChanged();
        emit quoteChanged();
        return;
    }

    // Priority 3: If JSON parsing failed completely, treat as error
    if (!data.isEmpty() && parseError.error != QJsonParseError::NoError) {
        m_best_destination_amount = 0.0;
        m_error = "Invalid response format";
        emit errorChanged();
        emit quoteChanged();
        return;
    }

    // Priority 4: Handle network error case (only if we couldn't parse meaningful JSON)
    if (error != QNetworkReply::NoError) {
        m_best_destination_amount = 0.0;
        m_error = errorString;
        emit errorChanged();
        emit quoteChanged();
        return;
    }

    // Priority 5: If we have no data, something went wrong
    if (data.isEmpty() && json.isEmpty()) {
        m_best_destination_amount = 0.0;
        m_error = "No response received";
        emit errorChanged();
        emit quoteChanged();
        return;
    }

    // Parse quotes array
    const auto quotesArray = json.value("quotes").toArray();
    if (quotesArray.isEmpty()) {
        // Check for message field in case of no quotes
        const auto message = json.value("message").toString();
        m_best_destination_amount = 0.0;
        // Use the message field if available, otherwise default error
        m_error = message.isEmpty() ? "No quotes available" : message;
        emit errorChanged();
        emit quoteChanged();
        return;
    }

    // Store all quotes and find the best one
    QVariantList allQuotes;
    double bestAmount = 0.0;
    QString bestProvider;
    QVariantMap bestQuote;
    
    for (const auto& quoteValue : quotesArray) {
        const auto quote = quoteValue.toObject();
        const double destinationAmount = quote.value("destinationAmount").toDouble();
        
        // Store each quote with only the fields we need
        QVariantMap quoteMap;
        quoteMap["serviceProvider"] = quote.value("serviceProvider").toString();
        quoteMap["destinationAmount"] = destinationAmount;
        allQuotes.append(quoteMap);
        
        // Track the best quote
        if (destinationAmount > bestAmount) {
            bestAmount = destinationAmount;
            bestProvider = quote.value("serviceProvider").toString();
            bestQuote = quoteMap;
        }
    }

    m_all_quotes = allQuotes;
    
    // Sort quotes: recently used providers first, then non-recently used
    // Both groups sorted by destinationAmount (descending)
    sortQuotes();
    m_best_destination_amount = bestAmount;
    m_best_service_provider = bestProvider;
    
    // Update selected quote: keep previous provider if still available,
    // otherwise fall back to the best quote
    // If we have a preferred provider from transactions, try to use it first
    if (!m_preferred_provider.isEmpty()) {
        bool found = false;
        for (const auto& v : allQuotes) {
            const auto q = v.toMap();
            if (q.value("serviceProvider").toString() == m_preferred_provider) {
                m_selected_quote = q;
                found = true;
                break;
            }
        }
        if (!found) {
            // Preferred provider not available, use cheapest (best quote)
            if (!bestQuote.isEmpty()) {
                m_selected_quote = bestQuote;
            } else {
                m_selected_quote.clear();
            }
        }
        m_preferred_provider = QString();
    } else if (!m_selected_quote.isEmpty()) {
        const QString prevProvider = m_selected_quote.value("serviceProvider").toString();
        bool kept = false;
        if (!prevProvider.isEmpty()) {
            for (const auto& v : allQuotes) {
                const auto q = v.toMap();
                if (q.value("serviceProvider").toString() == prevProvider) {
                    m_selected_quote = q; // keep same provider with updated amount
                    kept = true;
                    break;
                }
            }
        }
        if (!kept) {
            if (!bestQuote.isEmpty()) {
                m_selected_quote = bestQuote;
            } else {
                m_selected_quote.clear();
            }
        }
    } else {
        if (!bestQuote.isEmpty()) {
            m_selected_quote = bestQuote;
        } else {
            m_selected_quote.clear();
        }
    }
    
    if (!m_error.isEmpty()) {
        m_error = QString();
        emit errorChanged();
    }
    emit quoteChanged();
    emit selectedQuoteChanged();
}

void BuyBitcoinQuoteService::createWidgetSession(const QString& serviceProvider, const QString& countryCode, double sourceAmount, const QString& sourceCurrencyCode, const QString& walletAddress, bool useDebugMode, const QString& walletHashedId)
{
    // Cancel any pending widget request
    if (m_widget_reply) {
        disconnect(m_widget_reply, &QNetworkReply::finished, this, &BuyBitcoinQuoteService::onWidgetReplyFinished);
        m_widget_reply->abort();
        m_widget_reply->deleteLater();
        m_widget_reply = nullptr;
    }

    // In debug mode, use sandbox domain and force TRANSAK as service provider
    const QString provider = useDebugMode ? "TRANSAK" : serviceProvider;
    const QString baseUrl = useDebugMode ? "https://ramps.sandbox.blockstream.com" : "https://ramps.blockstream.com";

    // Validate input
    if (provider.isEmpty() || countryCode.isEmpty() || sourceAmount <= 0 || sourceCurrencyCode.isEmpty() || walletAddress.isEmpty()) {
        m_widget_error = "Invalid parameters";
        emit widgetErrorChanged();
        return;
    }

    // Set loading state
    m_widget_loading = true;
    m_widget_error = QString();
    m_widget_url = QString();
    emit widgetLoadingChanged();
    emit widgetErrorChanged();
    emit widgetUrlChanged();

    // Prepare JSON request body
    QJsonObject sessionData;
    sessionData["serviceProvider"] = provider;
    sessionData["countryCode"] = countryCode;
    sessionData["destinationCurrencyCode"] = "BTC";
    sessionData["lockFields"] = QJsonArray::fromStringList(QStringList() << "destinationCurrencyCode" << "walletAddress" << "sourceCurrencyCode");
    sessionData["paymentMethodType"] = "CARD";
    sessionData["redirectUrl"] = "https://green-webhooks.blockstream.com/thank-you";
    sessionData["sourceAmount"] = QString::number(sourceAmount);
    sessionData["sourceCurrencyCode"] = sourceCurrencyCode;
    sessionData["walletAddress"] = walletAddress;

    QJsonObject requestData;
    requestData["sessionData"] = sessionData;
    requestData["sessionType"] = "BUY";
    
    // Add externalCustomerIds if wallet_hashed_id is provided
    if (!walletHashedId.isEmpty()) {
        requestData["externalCustomerIds"] = walletHashedId;
    }

    QJsonDocument doc(requestData);
    QByteArray jsonData = doc.toJson(QJsonDocument::Compact);

    // Get network access manager
    auto engine = qmlEngine(this);
    if (!engine) {
        m_widget_loading = false;
        m_widget_error = "QML engine not available";
        emit widgetLoadingChanged();
        emit widgetErrorChanged();
        return;
    }

    auto net = engine->networkAccessManager();
    if (!net) {
        m_widget_loading = false;
        m_widget_error = "Network access manager not available";
        emit widgetLoadingChanged();
        emit widgetErrorChanged();
        return;
    }

    // Make POST request
    QNetworkRequest req(QUrl(baseUrl + "/crypto/session/widget"));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    m_widget_reply = net->post(req, jsonData);
    connect(m_widget_reply, &QNetworkReply::finished, this, &BuyBitcoinQuoteService::onWidgetReplyFinished);
}

void BuyBitcoinQuoteService::onWidgetReplyFinished()
{
    auto reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    // Check if this is still the current reply
    if (reply != m_widget_reply) {
        // This is a stale reply, ignore it
        reply->deleteLater();
        return;
    }

    // Disconnect and clear the reply reference before processing
    disconnect(reply, &QNetworkReply::finished, this, &BuyBitcoinQuoteService::onWidgetReplyFinished);
    m_widget_reply = nullptr;

    m_widget_loading = false;
    emit widgetLoadingChanged();

    // Read data before deleteLater to avoid potential issues
    QByteArray data = reply->readAll();
    QNetworkReply::NetworkError error = reply->error();
    QString errorString = reply->errorString();
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

    reply->deleteLater();

    // Parse JSON response
    QJsonParseError parseError;
    QJsonObject json;
    
    if (!data.isEmpty()) {
        json = QJsonDocument::fromJson(data, &parseError).object();
    }

    qDebug() << "Widget API response - Status:" << statusCode << "Error:" << error << "Data:" << data;

    // Check for network error
    if (error != QNetworkReply::NoError) {
        m_widget_error = errorString;
        m_widget_url = QString();
        emit widgetErrorChanged();
        emit widgetUrlChanged();
        return;
    }

    // Check for HTTP error status codes
    if (statusCode >= 400) {
        QString errorMsg = json.value("message").toString();
        if (errorMsg.isEmpty()) {
            errorMsg = QString("HTTP Error %1").arg(statusCode);
        }
        m_widget_error = errorMsg;
        m_widget_url = QString();
        emit widgetErrorChanged();
        emit widgetUrlChanged();
        return;
    }

    // Check for JSON parse error
    if (!data.isEmpty() && parseError.error != QJsonParseError::NoError) {
        m_widget_error = "Invalid response format";
        m_widget_url = QString();
        emit widgetErrorChanged();
        emit widgetUrlChanged();
        return;
    }

    // Check for error in JSON response
    if (!json.isEmpty() && json.contains("error")) {
        m_widget_error = json["error"].toString();
        m_widget_url = QString();
        emit widgetErrorChanged();
        emit widgetUrlChanged();
        return;
    }

    // Check for error code in JSON
    if (!json.isEmpty() && json.contains("code")) {
        QString message = json.value("message").toString();
        if (message.isEmpty()) {
            message = "Request failed";
        }
        m_widget_error = message;
        m_widget_url = QString();
        emit widgetErrorChanged();
        emit widgetUrlChanged();
        return;
    }

    // Extract widget URL
    QString widgetUrl = json.value("serviceProviderWidgetUrl").toString();
    if (widgetUrl.isEmpty()) {
        qDebug() << "Widget response JSON:" << QJsonDocument(json).toJson(QJsonDocument::Compact);
        m_widget_error = "No widget URL in response";
        m_widget_url = QString();
        emit widgetErrorChanged();
        emit widgetUrlChanged();
        return;
    }

    // Success - set widget URL
    qDebug() << "Widget URL received:" << widgetUrl;
    m_widget_url = widgetUrl;
    m_widget_error = QString();
    emit widgetUrlChanged();
    emit widgetErrorChanged();
}

QJsonValue BuyBitcoinQuoteService::buyDefaultValues() const
{
    return m_buy_default_values;
}

void BuyBitcoinQuoteService::updateBuyDefaultValues()
{
    auto& countly = cly::Countly::getInstance();
    const auto value = countly.getRemoteConfigValueString("buy_default_values");
    const auto doc = QJsonDocument::fromJson(QByteArray::fromStdString(value));
    QJsonValue newValue;
    if (doc.isObject()) {
        newValue = doc.object();
    } else if (doc.isArray()) {
        newValue = doc.array();
    }
    
    // Compare JSON strings to detect actual changes
    QByteArray currentJson;
    if (m_buy_default_values.isObject()) {
        currentJson = QJsonDocument(m_buy_default_values.toObject()).toJson(QJsonDocument::Compact);
    } else if (m_buy_default_values.isArray()) {
        currentJson = QJsonDocument(m_buy_default_values.toArray()).toJson(QJsonDocument::Compact);
    }
    
    QByteArray newJson;
    if (newValue.isObject()) {
        newJson = QJsonDocument(newValue.toObject()).toJson(QJsonDocument::Compact);
    } else if (newValue.isArray()) {
        newJson = QJsonDocument(newValue.toArray()).toJson(QJsonDocument::Compact);
    }
    
    if (currentJson != newJson) {
        m_buy_default_values = newValue;
        emit buyDefaultValuesChanged();
    }
}

void BuyBitcoinQuoteService::onTransactionsReplyFinished()
{
    auto reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    // Disconnect and clear the reply reference before processing
    disconnect(reply, &QNetworkReply::finished, this, &BuyBitcoinQuoteService::onTransactionsReplyFinished);
    m_transactions_reply = nullptr;

    QByteArray data = reply->readAll();
    QNetworkReply::NetworkError error = reply->error();
    QString errorString = reply->errorString();

    reply->deleteLater();

    QString preferredProvider;
    QStringList recentlyUsedProviders;
    
    QJsonParseError parseError;
    QJsonObject json;
    
    if (!data.isEmpty() && error == QNetworkReply::NoError) {
        json = QJsonDocument::fromJson(data, &parseError).object();
        
        if (parseError.error == QJsonParseError::NoError) {
            // Find the most recent SETTLED transaction and collect all SETTLED providers
            const auto transactionsArray = json.value("transactions").toArray();
            QDateTime mostRecentDate;
            QString mostRecentProvider;
            QSet<QString> providersSet;
            
            for (const auto& transactionValue : transactionsArray) {
                const auto transaction = transactionValue.toObject();
                const QString status = transaction.value("status").toString();
                
                if (status == "SETTLED") {
                    const QString provider = transaction.value("serviceProvider").toString();
                    if (!provider.isEmpty()) {
                        providersSet.insert(provider);
                    }
                    
                    const QString createdAt = transaction.value("createdAt").toString();
                    QDateTime transactionDate = QDateTime::fromString(createdAt, Qt::ISODate);
                    
                    if (transactionDate.isValid() && (mostRecentDate.isNull() || transactionDate > mostRecentDate)) {
                        mostRecentDate = transactionDate;
                        mostRecentProvider = provider;
                    }
                }
            }
            
            preferredProvider = mostRecentProvider;
            recentlyUsedProviders = QStringList(providersSet.begin(), providersSet.end());
        }
    }
    
    // Store preferred provider (will be used when quotes are fetched)
    m_preferred_provider = preferredProvider;
    
    // Update recently used providers list
    if (m_recently_used_providers != recentlyUsedProviders) {
        m_recently_used_providers = recentlyUsedProviders;
        emit recentlyUsedProvidersChanged();
        
        // Re-sort quotes if they're already loaded
        if (!m_all_quotes.isEmpty()) {
            sortQuotes();
            emit quoteChanged();
        }
    }
    
    // Now fetch the quotes with the stored parameters
    fetchQuote(m_pending_country_code, m_pending_source_amount, m_pending_source_currency_code, m_pending_wallet_address, QString());
}

void BuyBitcoinQuoteService::sortQuotes()
{
    if (m_all_quotes.isEmpty()) {
        return;
    }
    
    // Separate quotes into recently used and not recently used
    QVariantList recentlyUsedQuotes;
    QVariantList notRecentlyUsedQuotes;
    
    for (const auto& quoteVariant : m_all_quotes) {
        const QVariantMap quote = quoteVariant.toMap();
        const QString provider = quote.value("serviceProvider").toString();
        
        if (m_recently_used_providers.contains(provider)) {
            recentlyUsedQuotes.append(quoteVariant);
        } else {
            notRecentlyUsedQuotes.append(quoteVariant);
        }
    }
    
    // Sort recently used quotes by destinationAmount (descending)
    std::sort(recentlyUsedQuotes.begin(), recentlyUsedQuotes.end(), [](const QVariant& a, const QVariant& b) {
        const double amountA = a.toMap().value("destinationAmount").toDouble();
        const double amountB = b.toMap().value("destinationAmount").toDouble();
        return amountA > amountB;
    });
    
    // Sort not recently used quotes by destinationAmount (descending)
    std::sort(notRecentlyUsedQuotes.begin(), notRecentlyUsedQuotes.end(), [](const QVariant& a, const QVariant& b) {
        const double amountA = a.toMap().value("destinationAmount").toDouble();
        const double amountB = b.toMap().value("destinationAmount").toDouble();
        return amountA > amountB;
    });
    
    m_all_quotes = recentlyUsedQuotes + notRecentlyUsedQuotes;
}

