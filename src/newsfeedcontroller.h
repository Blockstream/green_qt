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

#endif // NEWSFEEDCONTROLLER_H
