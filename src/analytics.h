#ifndef GREEN_ANALYTICS_H
#define GREEN_ANALYTICS_H

#include <QObject>
#include <QtQml>

#include <map>
#include <string>

#include <gdk.h>

class AnalyticsPrivate;
class Analytics : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ isBusy NOTIFY busyChanged)
public:
    explicit Analytics();
    ~Analytics();
    static Analytics* instance();
    bool isActive() const;
    bool isBusy() const;
    QString pushView(const QString &name, const QVariantMap &segmentation);
    void popView(const QString& id);
    std::chrono::seconds timestampOffset() const;
signals:
    void busyChanged();
public slots:
    void recordEvent(const QString& name);
    void recordEvent(const QString& name, const QVariantMap& segmentation);
private slots:
    void check();
    void start();
    void stop(Qt::ConnectionType type = Qt::AutoConnection);
    void restart();
    void updateCustomUserDetails();
private:
    void incrBusy();
    void decrBusy();
private:
    AnalyticsPrivate* const d;
};

class AnalyticsView : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QVariantMap segmentation READ segmentation WRITE setSegmentation NOTIFY segmentationChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    QML_ELEMENT
public:
    AnalyticsView(QObject* parent = nullptr);
    ~AnalyticsView();
    QString name() const { return m_name; }
    void setName(const QString& name);
    QVariantMap segmentation() const { return m_segmentation; }
    void setSegmentation(const QVariantMap& segmentation);
    bool active() const { return m_active; }
    void setActive(bool active);
protected:
    void timerEvent(QTimerEvent* event) override;
private slots:
    void reset();
    void close();
    void open();
signals:
    void nameChanged();
    void segmentationChanged();
    void activeChanged();
private:
    QString m_name;
    QVariantMap m_segmentation;
    bool m_active{false};
    QString m_id;
    int m_reset_timer{0};
};

class AnalyticsEventPrivate;
class AnalyticsEvent : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QVariantMap segmentation READ segmentation WRITE setSegmentation NOTIFY segmentationChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    QML_ELEMENT
public:
    AnalyticsEvent(QObject* parent = nullptr);
    ~AnalyticsEvent();
    QString name() const;
    void setName(const QString& name);
    QVariantMap segmentation() const;
    void setSegmentation(const QVariantMap& segmentation);
    bool active() const;
    void setActive(bool active);
public slots:
    void track();
private slots:
    void reset();
    void stop();
    void start();
signals:
    void nameChanged();
    void segmentationChanged();
    void activeChanged();
protected:
    void timerEvent(QTimerEvent *event);
private:
    QScopedPointer<AnalyticsEventPrivate> d;
};

#endif // GREEN_ANALYTICS_H
