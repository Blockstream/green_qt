#ifndef GREEN_NAVIGATION_H
#define GREEN_NAVIGATION_H

#include <QtQml>
#include <QObject>
#include <QStack>
#include <QVariantMap>

class Navigation : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString location READ location WRITE setLocation NOTIFY locationChanged)
    Q_PROPERTY(QString path READ path NOTIFY pathChanged)
    Q_PROPERTY(QVariantMap param READ param NOTIFY paramChanged)
    Q_PROPERTY(bool canPop READ canPop NOTIFY locationChanged)
    QML_ELEMENT
public:
    explicit Navigation(QObject* parent = nullptr);
    QString location() const { return m_location; }
    void setLocation(const QString& location);
    QString path() const { return m_path; }
    void setPath(const QString& path);
    QVariantMap param() const { return m_param; }
    void setParam(const QVariantMap& param);
    bool canPop() const { return !m_history.isEmpty(); }
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
    void updateLocation(const QString& location);
};

#endif // GREEN_NAVIGATION_H
