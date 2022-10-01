#ifndef GREEN_BLOGCONTROLLER_H
#define GREEN_BLOGCONTROLLER_H

#include <QObject>
#include <QSortFilterProxyModel>
#include <QStandardItemModel>
#include <QStandardItem>
#include <QUrl>

#include "httprequestactivity.h"

class BlogPost : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString title READ title NOTIFY titleChanged)
    Q_PROPERTY(QString description READ description NOTIFY descriptionChanged)
    Q_PROPERTY(QString category READ category NOTIFY categoryChanged)
    Q_PROPERTY(QDateTime publicationDate READ publicationDate NOTIFY publicationDateChanged)
    Q_PROPERTY(QString link READ link NOTIFY linkChanged)
    Q_PROPERTY(QUrl imagePath READ imagePath NOTIFY imagePathChanged)
public:
    BlogPost(QObject* parent = nullptr);
    QString title() const { return m_title; }
    void setTitle(const QString& title);
    QString description() const { return m_description; }
    void setDescription(const QString& description);
    QString category() const { return m_category; }
    void setCategory(const QString& category);
    QDateTime publicationDate() const { return m_publication_date; }
    void setPublicationDate(const QDateTime& publication_date);
    QString link() const { return m_link; }
    void setLink(const QString& link);
    void setImageUrl(const QUrl& image_url);
    QUrl imagePath();
signals:
    void titleChanged();
    void descriptionChanged();
    void categoryChanged();
    void publicationDateChanged();
    void linkChanged();
    void imagePathChanged();
private:
    QString m_title;
    QString m_description;
    QString m_category;
    QDateTime m_publication_date;
    QString m_link;
    QUrl m_image_url;
    QUrl m_image_path;
    HttpRequestActivity* m_image_request{nullptr};
};

class BlogModel : public QSortFilterProxyModel
{
    Q_OBJECT
public:
    BlogModel(QObject* parent = nullptr);
    void updateFromContent(const QString& content);
protected:
    bool lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const override;
private:
    QStandardItemModel* const m_source;
    QMap<QString, BlogPost*> m_posts;
    QMap<QString, QStandardItem*> m_items;
};

class BlogController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(BlogModel* model READ model CONSTANT)
    Q_PROPERTY(bool fetching READ isFetching NOTIFY isFetchingChanged)
    QML_ELEMENT
public:
    explicit BlogController(QObject* parent = nullptr);
    BlogModel* model() const { return m_model; }
    bool isFetching() const { return m_fetch_activity != nullptr; }
public slots:
    void fetch();
signals:
    void isFetchingChanged();
private:
    BlogModel* const m_model;
    HttpRequestActivity* m_fetch_activity{nullptr};
};

#endif // GREEN_BLOGCONTROLLER_H
