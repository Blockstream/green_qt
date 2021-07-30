#ifndef NEWSFEEDCONTROLLER_H
#define NEWSFEEDCONTROLLER_H

#include "httprequestactivity.h"

#include <QtQml>
#include <QObject>
#include <QNetworkAccessManager>

class NewsFeedController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QJsonArray model READ model NOTIFY modelChanged)
    QML_ELEMENT

public:
    explicit NewsFeedController(QObject *parent = nullptr);

    QJsonArray model();

public slots:
    void fetch();

signals:
    void modelChanged();

private:
    void parse();
    void updateModel();

    QJsonArray m_model;
    Connectable<Session> m_session;
    QString m_feed;
};

class NewsFeedActivity : public HttpRequestActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    NewsFeedActivity(Session* session);
    QString feed() const;
};

class NewsImageDownloadActivity : public HttpRequestActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    NewsImageDownloadActivity(Session* session, const QString &url);
    void handleResponse();
private:
    QString m_url;
};

#endif // NEWSFEEDCONTROLLER_H
