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
    if (!m_session) {
        auto network = NetworkManager::instance()->network("mainnet");
        m_session = new Session(this);
        m_session->setNetwork(network);
        m_session->setActive(true);
        m_session.track(connect(m_session, &Session::connectedChanged, this, [this] {
            if (!m_session->isConnected()) return;
            fetch();

        }));
        return;
    }

    auto activity = new NewsFeedActivity(m_session);
    connect(activity, &NewsFeedActivity::finished, this, [=] {
        activity->deleteLater();
        m_feed = activity->feed();
        QFile feed_file(GetDataFile("cache", "feed.xml"));
        if (feed_file.open(QFile::WriteOnly)) {
            feed_file.write(m_feed.toUtf8());
        }
        parse();
    });
    activity->exec();
}

void NewsFeedController::parse()
{
    QJsonArray array;
    QDomDocument doc;
    doc.setContent(m_feed);
    QDomNodeList items = doc.elementsByTagName("item");

    for (int i = 0; i < items.size(); ++i) {
        QJsonObject item = QJsonObject();
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
                        auto activity = new NewsImageDownloadActivity(m_session, url);
                        connect(activity, &NewsImageDownloadActivity::finished, this, [=] {
                            activity->deleteLater();
                            QFile file(path);
                            if (file.open(QFile::WriteOnly)) {
                                file.write(QByteArray::fromBase64(activity->response().value("body").toString().toLocal8Bit()));
                                file.close();
                            }
                            updateModel();
                        });
                        activity->exec();
                    }
                    item[e.tagName()] = QUrl::fromLocalFile(path).toString();
                }
            } else {
                item[e.tagName()] = e.text();
            }
        }

        array.append(item);
        // Limit to 3 entries
        if (array.count() == 3) break;
    }

    m_model = array;
    emit modelChanged();
}

QJsonArray NewsFeedController::model()
{
    return m_model;
}

void NewsFeedController::updateModel()
{
    QJsonArray tmp = m_model;
    m_model = QJsonArray();
    emit modelChanged();
    m_model = tmp;
    emit modelChanged();
}

NewsFeedActivity::NewsFeedActivity(Session* session)
    : HttpRequestActivity(session)
{
    setMethod("GET");
    addUrl(QString("https://blockstream.com/feed.xml"));
    //addUrl(QString("http://greenupjcyad2xow7xmrunreetczmqje2nz6bdez3a5xhddlockoqryd.onion/desktop/%1.json").arg(channel));
}

QString NewsFeedActivity::feed() const
{
    return response().value("body").toString();
}

NewsImageDownloadActivity::NewsImageDownloadActivity(Session* session, const QString &url)
    : HttpRequestActivity(session)
{
    m_url = url;
    setMethod("GET");
    setAccept("base64");
    addUrl(url);
    //addUrl(QString("http://greenupjcyad2xow7xmrunreetczmqje2nz6bdez3a5xhddlockoqryd.onion/desktop/%1.json").arg(channel));
}
