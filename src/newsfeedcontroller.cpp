#include "newsfeedcontroller.h"
#include "networkmanager.h"

#include <QNetworkReply>
#include <QDomDocument>
#include <QJsonArray>

NewsFeedController::NewsFeedController(QObject *parent) :
    QObject(parent)
{
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

    for (int i = 0; i < items.size(); i++)
    {
        QJsonObject item = QJsonObject();
        QDomNode n = items.item(i).firstChild();

        while (!n.isNull())
        {
            QDomElement e = n.toElement();

            if (!e.isNull())
            {
                if (e.tagName()=="image")
                {
                    if (e.elementsByTagName("url").size()>0)
                        item[e.tagName()] = e.elementsByTagName("url").at(0).toElement().text();
                }
                else
                {
                    item[e.tagName()] = e.text();
                }
            }

            n = n.nextSibling();
        }

        array.append(item);

        if (array.count()>2) break;
    }

    m_model = array;

    emit modelChanged();
}

QJsonArray NewsFeedController::model()
{
    return m_model;
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
