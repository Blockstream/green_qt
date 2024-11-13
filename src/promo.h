#ifndef GREEN_PROMO_H
#define GREEN_PROMO_H

#include "green.h"

#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>

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
    explicit Promo(const QString& id, QObject* parent);
    QString id() const { return m_id; }
    bool ready() const { return m_ready; }
    void setReady(bool ready);
    QJsonObject data() const { return m_data; }
    void setData(const QJsonObject& data);
    bool dismissed() const { return m_dismissed; }
public slots:
    void dismiss();
signals:
    void readyChanged();
    void dataChanged();
    void dismissedChanged();
protected:
    const QString m_id;
    bool m_ready{false};
    QJsonObject m_data;
    bool m_dismissed{false};
};

class PromoManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<Promo> promos READ promos NOTIFY changed)
public:
    explicit PromoManager();
    virtual ~PromoManager();
    static PromoManager* instance();
    QQmlListProperty<Promo> promos();
signals:
    void changed();
private slots:
    void update();
private:
    Promo* getOrCreatePromo(const QJsonObject& data);
private:
    QList<Promo*> m_promos;
    QMap<QString, Promo*> m_promo_by_id;
};


#endif // GREEN_PROMO_H
