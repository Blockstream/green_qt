#include "httpmanager.h"
#include "newsfeedcontroller.h"
#include "networkmanager.h"
#include "util.h"

#include <QNetworkReply>
#include <QDomDocument>
#include <QJsonArray>

NewsFeedController::NewsFeedController(QObject *parent) :
    QObject(parent)
{
    QFile feed_file(GetDataFile("cache", "feed.xml"));
    if (feed_file.open(QFile::ReadOnly)) {
        m_feed = QString::fromUtf8(feed_file.readAll());
        parse();
    }
}

void NewsFeedController::fetch()
{
    auto activity = new NewsFeedActivity(this);
    connect(activity, &NewsFeedActivity::finished, this, [=] {
        activity->deleteLater();
        // TODO propagate error
        if (activity->hasError()) return;
        m_feed = activity->feed();
        QFile feed_file(GetDataFile("cache", "feed.xml"));
        if (feed_file.open(QFile::WriteOnly)) {
            feed_file.write(m_feed.toUtf8());
        }
        parse();
    });
    HttpManager::instance()->exec(activity);
}

void NewsFeedController::parse()
{
    QDomDocument doc;
    doc.setContent(m_feed);
    QDomNodeList items = doc.elementsByTagName("item");

    for (int i = 0; i < items.size(); ++i) {
        QDomNode n = items.item(i).firstChild();

        while (!n.isNull()) {
            QDomElement e = n.toElement();
            n = n.nextSibling();
            if (e.isNull()) continue;

            if (e.tagName() == "image") {
                if (e.elementsByTagName("url").size() > 0) {
                    const auto url = e.elementsByTagName("url").at(0).toElement().text();
                    const auto path = GetDataFile("cache", Sha256(url));
                    QFile file(path);
                    if (!file.exists()) {
                        auto activity = new NewsImageDownloadActivity(url, this);
                        connect(activity, &NewsImageDownloadActivity::finished, this, [=] {
                            activity->deleteLater();
                            QFile file(path);
                            if (file.open(QFile::WriteOnly)) {
                                file.write(QByteArray::fromBase64(activity->response().value("body").toString().toLocal8Bit()));
                                file.close();
                            }
                            updateModel();
                        });
                        HttpManager::instance()->exec(activity);
                    }
                }
            }
        }
    }
    updateModel();
}

QJsonArray NewsFeedController::model() const
{
    return m_model;
}

void NewsFeedController::updateModel()
{
    QJsonArray array;
    QDomDocument doc;
    doc.setContent(m_feed);
    QDomNodeList items = doc.elementsByTagName("item");

    for (int i = 0; i < items.size(); ++i) {
        QJsonObject item;
        QDomNode n = items.item(i).firstChild();

        while (!n.isNull()) {
            QDomElement e = n.toElement();
            n = n.nextSibling();
            if (e.isNull()) continue;

            if (e.tagName() == "image") {
                if (e.elementsByTagName("url").size() > 0) {
                    const auto url = e.elementsByTagName("url").at(0).toElement().text();
                    const auto path = GetDataFile("cache", Sha256(url));
                    QFile file(path);
                    if (file.exists()) {
                        item["image"] = QUrl::fromLocalFile(path).toString();
                    }
                }
            } else {
                item[e.tagName()] = e.text();
            }
        }
        if (item.contains("image")) {
            array.append(item);
        }
    }

    m_model = array;
    emit modelChanged();
}

NewsFeedActivity::NewsFeedActivity(QObject* parent)
    : HttpRequestActivity(parent)
{
    setMethod("GET");
    addUrl(QStringLiteral("https://blockstream.com/feed.xml"));
    addUrl(QStringLiteral("http://blkstrmccjufnkm3otpwjso67apg3f4e53dxzz7nbvr5zg6kiicq2jqd.onion/feed.xml"));
}

QString NewsFeedActivity::feed() const
{
    return response().value("body").toString();
}

NewsImageDownloadActivity::NewsImageDownloadActivity(const QString& url, QObject* parent)
    : HttpRequestActivity(parent)
{
    m_url = url;
    setMethod("GET");
    setAccept("base64");
    addUrl(url);
    QString onion = url;
    onion.replace(QStringLiteral("https://blockstream.com/"), QStringLiteral("http://blkstrmccjufnkm3otpwjso67apg3f4e53dxzz7nbvr5zg6kiicq2jqd.onion/"));
    addUrl(onion);
}
