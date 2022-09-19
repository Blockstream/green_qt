#ifndef GREEN_ANALYTICS_H
#define GREEN_ANALYTICS_H

#include <QObject>
#include <QtQml>

class Analytics : public QObject
{
    Q_OBJECT
public:
    explicit Analytics();
    ~Analytics();
    static Analytics* instance();
    bool isActive() const { return m_active; }
public slots:
    void recordEvent(const QString& name, const QVariantMap& segmentation);
private slots:
    void check();
    void start();
    void stop();
    void updateCustomUserDetails();
private:
    std::atomic_bool m_active{false};
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
    std::string m_id;
    int m_reset_timer{0};
};

#endif // GREEN_ANALYTICS_H
