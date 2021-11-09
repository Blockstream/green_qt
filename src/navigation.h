#ifndef GREEN_NAVIGATION_H
#define GREEN_NAVIGATION_H

#include <QtQml>
#include <QObject>
#include <QVariantMap>
#include <QStack>

class Navigation : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString location READ location WRITE setLocation NOTIFY locationChanged)
    Q_PROPERTY(QString path READ path NOTIFY pathChanged)
    Q_PROPERTY(QVariantMap param READ param NOTIFY paramChanged)
    QML_ELEMENT
public:
    explicit Navigation(QObject* parent = nullptr);
    QString location() const { return m_location; }
    void setLocation(const QString& location);
    QString path() const { return m_path; }
    void setPath(const QString& path);
    QVariantMap param() const { return m_param; }
    void setParam(const QVariantMap& param);
public slots:
    void go(const QString& location, const QVariantMap& param = {});
    void pop();
    void set(const QVariantMap& kvs);
signals:
    void locationChanged(const QString& location);
    void pathChanged(const QString& path);
    void paramChanged(const QVariantMap& param);
private:
    QString m_location;
    QStack<QString> m_history;
    QString m_path;
    QVariantMap m_param;
};

class Route : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString location READ location WRITE setLocation NOTIFY locationChanged)
    Q_PROPERTY(QString previous READ previous NOTIFY previousChanged)
    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(bool active READ isActive NOTIFY activeChanged)
    QML_ELEMENT
public:
    Route(QObject* parent = nullptr);
    QString location() const { return m_location; }
    void setLocation(const QString& location);
    QString previous() const { return m_previous ; }
    QString path() const { return m_path; }
    void setPath(const QString& path);
    bool isActive() const { return m_active; }
public slots:
signals:
    void locationChanged(const QString& location);
    void previousChanged(const QString& previous);
    void pathChanged(const QString& path);
    void activeChanged(bool active);
private:
    void update();
    void setPrevious(const QString& previous);
    void setActive(bool active);
private:
    QString m_location;
    QString m_previous;
    QString m_path;
    bool m_active{false};
};

#endif // GREEN_NAVIGATION_H
