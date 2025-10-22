#ifndef GREEN_PROMO_H
#define GREEN_PROMO_H

#include "green.h"

#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>
#include <QNetworkReply>

class Promo;
class PromoManager;
class PromoResource;

class PromoResource : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString path READ path NOTIFY pathChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    PromoResource(Promo* promo);
    Promo* promo() const { return m_promo; }
    QString path() const { return m_path; }
    void setPath(const QString& path);
    void download(const QString& source);
    void downloadNow();
    void purge();
    bool ready() const;
signals:
    void pathChanged();
private:
    Promo* const m_promo;
    QString m_source;
    QString m_path;
    QNetworkReply* m_reply{nullptr};
};

class Promo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    Q_PROPERTY(bool dismissed READ dismissed NOTIFY dismissedChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    explicit Promo(const QString& id, PromoManager* manager);
    virtual ~Promo();
    PromoManager* manager() const { return m_manager; }
    QString id() const { return m_id; }
    bool ready() const;
    QJsonObject data() const { return m_data; }
    void setData(const QJsonObject& data);
    bool dismissed() const { return m_dismissed; }
    Q_INVOKABLE PromoResource* getOrCreateResource(const QString& name);
public slots:
    void dismiss();
signals:
    void readyChanged();
    void dataChanged();
    void dismissedChanged();
protected:
    PromoManager* const m_manager;
    const QString m_id;
    QJsonObject m_data;
    bool m_dismissed{false};
    QMap<QString, PromoResource*> m_resources;
};

class PromoManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<Promo> promos READ promos NOTIFY changed)
    QML_ELEMENT
    QML_SINGLETON
public:
    explicit PromoManager();
    virtual ~PromoManager();
    QQmlListProperty<Promo> promos();
signals:
    void changed();
private slots:
    void update();
private:
    void createOrUpdatePromo(const QJsonObject& data);
private:
    QJsonValue m_config;
    QList<Promo*> m_promos;
    QMap<QString, Promo*> m_promo_by_id;
};


#endif // GREEN_PROMO_H
