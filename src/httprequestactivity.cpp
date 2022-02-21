#include "httprequestactivity.h"
#include "json.h"
#include "session.h"

#include <gdk.h>

#include <QtConcurrentRun>

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

void HttpRequestActivity::setProxy(const QString& proxy)
{
    m_proxy = proxy;
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

bool HttpRequestActivity::hasError() const
{
    return m_response.contains("error");
}

void HttpRequestActivity::exec()
{
    Q_ASSERT(!m_method.isEmpty());
    Q_ASSERT(!m_urls.isEmpty());

    auto connection = session()->connection();
    Q_ASSERT(connection);

    auto watcher = new QFutureWatcher<QJsonObject>(connection);

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
        if (!m_proxy.isEmpty()) details.insert("proxy", m_proxy);

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
