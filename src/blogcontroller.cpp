#include "blogcontroller.h"

#include <QDomDocument>

#include "httpmanager.h"
#include "util.h"

BlogPost::BlogPost(QObject* parent)
    : QObject(parent)
{
}

void BlogPost::setTitle(const QString& title)
{
    if (m_title == title) return;
    m_title = title;
    emit titleChanged();
}

void BlogPost::setDescription(const QString& description)
{
    if (m_description == description) return;
    m_description = description;
    emit descriptionChanged();
}

void BlogPost::setCategory(const QString& category)
{
    if (m_category == category) return;
    m_category = category;
    emit categoryChanged();
}

void BlogPost::setPublicationDate(const QDateTime& publication_date)
{
    if (m_publication_date == publication_date) return;
    m_publication_date = publication_date;
    emit publicationDateChanged();
}

void BlogPost::setLink(const QString& link)
{
    if (m_link == link) return;
    m_link = link;
    emit publicationDateChanged();
}

void BlogPost::setImageUrl(const QUrl &image_url)
{
    if (m_image_url == image_url) return;
    m_image_url = image_url;
    m_image_path.clear();
    emit imagePathChanged();
}

QUrl BlogPost::imagePath()
{
    if (!m_image_url.isEmpty() && m_image_path.isEmpty() && !m_image_request) {
        const auto path = GetDataFile("cache", Sha256(m_image_url.toString()));
        if (QFile::exists(path)) {
            m_image_path = QUrl::fromLocalFile(path).toString();
        } else {
            m_image_request = new HttpRequestActivity(this);
            m_image_request->setMethod("GET");
            m_image_request->addUrl(m_image_url.toString());
            m_image_request->addUrl(m_image_url.toString().replace(QStringLiteral("https://blog.blockstream.com/"), QStringLiteral("http://nb2jkovdpcu5l3poiid3sytzjv4d6bgaijj4ktcbyuczxmqph2m4u3id.onion/")));
            m_image_request->setAccept("base64");
            connect(m_image_request, &Activity::finished, this, [=] {
                QFile file(path);
                if (file.open(QFile::WriteOnly)) {
                    file.write(QByteArray::fromBase64(m_image_request->body().toLocal8Bit()));
                    file.close();
                }
                m_image_request->deleteLater();
                m_image_request = nullptr;
                emit imagePathChanged();
            });
            HttpManager::instance()->exec(m_image_request);
        }
    }
    return m_image_path;
}

BlogModel::BlogModel(QObject* parent)
    : QSortFilterProxyModel(parent)
    , m_source(new QStandardItemModel(this))
{
    m_source->setItemRoleNames({
        { Qt::UserRole + 1, QByteArrayLiteral("post") }
    });

    setSourceModel(m_source);
    setDynamicSortFilter(true);
    sort(0, Qt::DescendingOrder); // NOLINT(build/include_what_you_use)
}

void BlogModel::updateFromContent(const QString& content)
{
    QDomDocument doc;
    doc.setContent(content);

    auto item = doc
        .firstChildElement("rss")
        .firstChildElement("channel")
        .firstChildElement("item");

    while (!item.isNull()) {
        const auto guid = item.firstChildElement("guid").text();
        const auto title = item.firstChildElement("title").text();
        const auto description = item.firstChildElement("description").text();
        const auto category = item.firstChildElement("category").text();
        const auto link = item.firstChildElement("link").text();
        const auto pub_date = item.firstChildElement("pubDate").text();
        const auto image_url = item.firstChildElement("media:content").attribute("url");

        if (!m_posts.contains(guid)) {
            auto post = m_posts[guid] = new BlogPost(this);
            post->setTitle(title);
            post->setDescription(description);
            post->setCategory(category);
            post->setLink(link);
            post->setPublicationDate(QDateTime::fromString(pub_date, Qt::RFC2822Date));
            post->setImageUrl(image_url);

            auto row = m_items[guid] = new QStandardItem;
            row->setData(QVariant::fromValue(post));
            m_source->appendRow(row);
        }

        item = item.nextSiblingElement("item");
    }
}

bool BlogModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const
{
    auto left = m_source->data(source_left, Qt::UserRole + 1).value<BlogPost*>();
    auto right = m_source->data(source_right, Qt::UserRole + 1).value<BlogPost*>();
    return left->publicationDate() < right->publicationDate();
}

BlogController::BlogController(QObject* parent)
    : QObject(parent)
    , m_model(new BlogModel(this))
{
    QFile file(GetDataFile("cache", "blog.xml"));
    if (file.open(QFile::ReadOnly)) {
        const auto content = QString::fromUtf8(file.readAll());
        m_model->updateFromContent(content);
    }
}

void BlogController::fetch()
{
    if (m_fetch_activity) return;

    m_fetch_activity = new HttpRequestActivity(this);
    m_fetch_activity->setMethod("GET");
    m_fetch_activity->addUrl("https://blog.blockstream.com/latest-news-rss/rss/");
    m_fetch_activity->addUrl("http://nb2jkovdpcu5l3poiid3sytzjv4d6bgaijj4ktcbyuczxmqph2m4u3id.onion/latest-news-rss/rss/");
    connect(m_fetch_activity, &Activity::finished, this, [=] {
        auto activity = static_cast<HttpRequestActivity*>(sender());
        // TODO propagate error
        if (activity->hasError()) return;
        const auto content = activity->body();
        QFile file(GetDataFile("cache", "blog.xml"));
        if (file.open(QFile::WriteOnly)) {
            file.write(content.toUtf8());
        }
        m_model->updateFromContent(content);
        activity->deleteLater();
        m_fetch_activity = nullptr;
        emit isFetchingChanged();
    });
    HttpManager::instance()->exec(m_fetch_activity);
    emit isFetchingChanged();
}
