#include "httprequestactivity.h"

#include <gdk.h>

#include <QtConcurrentRun>

#include "json.h"
#include "session.h"

HttpRequestActivity::HttpRequestActivity(QObject* parent)
    : SessionActivity(parent)
{
}

void HttpRequestActivity::setMethod(const QString& method)
{
    m_method = method;
}

void HttpRequestActivity::addUrl(const QString& url)
{
    m_urls.append(url);
}

void HttpRequestActivity::setData(const QJsonValue& data)
{
    m_data = data;
}

void HttpRequestActivity::setAccept(const QString& accept)
{
    m_accept = accept;
}

void HttpRequestActivity::addHeader(const QString& header, const QString& value)
{
    m_headers.insert(header, value);
}

void HttpRequestActivity::setTimeout(int timeout)
{
    m_timeout = timeout;
}

void HttpRequestActivity::addRootCertificate(const QString& root_certificate)
{
    m_root_certificates.append(root_certificate);
}

QString HttpRequestActivity::contentType() const
{
    const auto headers = m_response.value("headers").toObject();
    return headers["content-type"].toString();
}

QVariant HttpRequestActivity::body() const
{
    const auto content_type = contentType();
    qDebug() << Q_FUNC_INFO << "process response body with content type" << content_type;
    const auto body = m_response.value("body").toString();
    if (content_type == "application/json") {
        const auto document = QJsonDocument::fromJson(body.toUtf8());
        if (document.isObject()) return document.object();
        if (document.isArray()) return document.array();
    } else if (content_type.startsWith("text/xml")) {
        return body;
    } else {
        return body.toUtf8();
    }
}

bool HttpRequestActivity::hasError() const
{
    return m_response.contains("error");
}

void HttpRequestActivity::exec()
{
    Q_ASSERT(!m_method.isEmpty());
    Q_ASSERT(!m_urls.isEmpty());

    auto watcher = new QFutureWatcher<QJsonObject>(this);

    connect(this, &QObject::destroyed, watcher, &QObject::deleteLater);
    connect(watcher, &QFutureWatcherBase::finished, this, [this, watcher] {
        watcher->deleteLater();
        m_response = watcher->resultAt(0);
        if (m_response.empty()) {
            fail();
        } else {
            finish();
        }
    });

    watcher->setFuture(QtConcurrent::run([this] {
        QJsonObject details;
        details.insert("method", m_method);
        details.insert("urls", QJsonArray::fromStringList(m_urls));

        if (!m_accept.isEmpty()) details.insert("accept", m_accept);
        if (!m_data.isNull()) details.insert("data", m_data);

        if (!m_headers.isEmpty()) details.insert("headers", QJsonObject::fromVariantMap(m_headers));
        if (m_timeout > 0) details.insert("timeout", m_timeout);

        if (!m_root_certificates.isEmpty()) details.insert("root_certificates", QJsonArray::fromStringList(m_root_certificates));

        auto params = Json::fromObject(details);
        GA_json* output;
        int rc = GA_http_request(session()->m_session, params.get(), &output);
        if (rc != GA_OK) return QJsonObject();
        auto response = Json::toObject(output);
        GA_destroy_json(output);
        return response;
    }));
}
