#include "buybitcoinquoteservice.h"

#include <QQmlEngine>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrl>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QRegularExpression>
#include <QDebug>
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

    // Reset state
    bool hasState = m_best_destination_amount != 0.0 || m_loading || !m_error.isEmpty() || !m_best_service_provider.isEmpty() || !m_all_quotes.isEmpty() || !m_selected_quote.isEmpty();
    if (hasState) {
        m_best_destination_amount = 0.0;
        m_best_service_provider = QString();
        m_all_quotes.clear();
        m_selected_quote.clear();
        m_loading = false;
        m_error = QString();
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

void BuyBitcoinQuoteService::fetchQuote(const QString& countryCode, double sourceAmount, const QString& sourceCurrencyCode, const QString& walletAddress)
{
    // Cancel any pending request
    if (m_reply) {
        disconnect(m_reply, &QNetworkReply::finished, this, &BuyBitcoinQuoteService::onReplyFinished);
        m_reply->abort();
        m_reply->deleteLater();
        m_reply = nullptr;
    }

    // Validate input
    if (sourceAmount <= 0 || sourceCurrencyCode.isEmpty() || walletAddress.isEmpty()) {
        m_best_destination_amount = 0.0;
        m_error = QString();
        emit quoteChanged();
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

    // Sort quotes by destinationAmount (descending)
    std::sort(allQuotes.begin(), allQuotes.end(), [](const QVariant& a, const QVariant& b) {
        const double amountA = a.toMap().value("destinationAmount").toDouble();
        const double amountB = b.toMap().value("destinationAmount").toDouble();
        return amountA > amountB; // Descending order
    });

    m_all_quotes = allQuotes;
    m_best_destination_amount = bestAmount;
    m_best_service_provider = bestProvider;
    
    // Update selected quote: keep previous provider if still available,
    // otherwise fall back to the best quote
    if (!m_selected_quote.isEmpty()) {
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

void BuyBitcoinQuoteService::createWidgetSession(const QString& serviceProvider, const QString& countryCode, double sourceAmount, const QString& sourceCurrencyCode, const QString& walletAddress, bool useDebugMode)
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

QJsonValue BuyBitcoinQuoteService::getBuyDefaultValues() const
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

