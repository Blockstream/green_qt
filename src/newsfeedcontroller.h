#ifndef GREEN_NEWSFEEDCONTROLLER_H
#define GREEN_NEWSFEEDCONTROLLER_H

#include "httprequestactivity.h"

#include <QtQml>
#include <QObject>

class NewsFeedController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QJsonArray model READ model NOTIFY modelChanged)
    QML_ELEMENT

public:
    explicit NewsFeedController(QObject* parent = nullptr);

    QJsonArray model() const;

public slots:
    void fetch();

signals:
    void modelChanged();

private:
    void parse();
    void updateModel();

    QJsonArray m_model;
    QString m_feed;
};

class NewsFeedActivity : public HttpRequestActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    NewsFeedActivity(QObject* parent);
    QString feed() const;
};

class NewsImageDownloadActivity : public HttpRequestActivity
{
    Q_OBJECT
    QML_ELEMENT
public:
    NewsImageDownloadActivity(const QString &url, QObject* parent);
private:
    QString m_url;
};

#endif // GREEN_NEWSFEEDCONTROLLER_H
