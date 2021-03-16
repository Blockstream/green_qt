#ifndef GREEN_HTTPREQUESTACTIVITY_H
#define GREEN_HTTPREQUESTACTIVITY_H

#include "session.h"

class HttpRequestActivity : public SessionActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    HttpRequestActivity(Session* session);
    void setMethod(const QString& method);
    void addUrl(const QString& urls);
    void setData(const QString& data);
    void setAccept(const QString& accept);
    void setProxy(const QString& proxy);
    void addHeader(const QString& header, const QString& value);
    void setTimeout(int timeout);
    void addRootCertificate(const QString& root_certificate);
    QJsonObject response() const { return m_response; }
    void exec() override;
private:
    Session* const m_session;
    QString m_method;
    QStringList m_urls;
    QString m_data;
    QString m_accept;
    QString m_proxy;
    QVariantMap m_headers;
    int m_timeout{0};
    QStringList m_root_certificates;
    QJsonObject m_response;
};

#endif // GREEN_HTTPREQUESTACTIVITY_H
