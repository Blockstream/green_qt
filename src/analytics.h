#ifndef GREEN_ANALYTICS_H
#define GREEN_ANALYTICS_H

#include <QJsonValue>
#include <QObject>
#include <QtQml>

#include <chrono>

class AnalyticsPrivate;
class Analytics : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ isBusy NOTIFY busyChanged)
public:
    explicit Analytics();
    ~Analytics();
    static Analytics* instance();
    void start();
    bool isActive() const;
    bool isBusy() const;
    QString pushView(const QString &name, const QVariantMap &segmentation);
    void popView(const QString& id);
    std::chrono::seconds timestampOffset() const;
    QJsonValue getRemoteConfigValue(const QString& key) const;
signals:
    void busyChanged();
    void remoteConfigChanged();
public slots:
    void recordEvent(const QString& name);
    void recordEvent(const QString& name, const QVariantMap& segmentation);
private:
    void incrBusy();
    void decrBusy();
private:
    AnalyticsPrivate* const d;
    friend class AnalyticsPrivate;
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

class AnalyticsAlert : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString screen READ screen WRITE setScreen NOTIFY screenChanged)
    Q_PROPERTY(QString network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(bool active READ isActive NOTIFY dataChanged)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    Q_PROPERTY(QString title READ title NOTIFY dataChanged)
    Q_PROPERTY(QString message READ message NOTIFY dataChanged)
    Q_PROPERTY(QString link READ link NOTIFY dataChanged)
    Q_PROPERTY(bool dismissable READ isDismissable NOTIFY dataChanged)
    QML_ELEMENT
public:
    AnalyticsAlert(QObject* parent = nullptr);
    QString screen() const { return m_screen; }
    void setScreen(const QString& screen);
    QString network() const { return m_network; }
    void setNetwork(const QString& network);
    bool isActive() const { return !m_data.empty(); }
    QJsonObject data() const { return m_data; }
    QString title() const;
    QString message() const;
    QString link() const;
    bool isDismissable() const;
signals:
    void activeChanged();
    void screenChanged();
    void networkChanged();
    void dataChanged();
private slots:
    void update();
private:
    QString m_screen;
    QString m_network;
    QJsonObject m_data;
};

class AnalyticsRemoteConfig : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString key READ key WRITE setKey NOTIFY keyChanged)
    Q_PROPERTY(QJsonValue value READ value NOTIFY valueChanged)
    QML_ELEMENT
public:
    AnalyticsRemoteConfig(QObject* parent = nullptr);
    QString key() const { return m_key; }
    void setKey(const QString& key);
    QJsonValue value() const { return m_value; }
    void setValue(const QJsonValue& value);
signals:
    void keyChanged();
    void valueChanged();
private:
    void update();
private:
    QString m_key;
    QJsonValue m_value;
};

#endif // GREEN_ANALYTICS_H
