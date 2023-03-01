#ifndef GREEN_NAVIGATION_H
#define GREEN_NAVIGATION_H

#include <QObject>
#include <QStack>
#include <QtQml>
#include <QVariantMap>

class Navigation : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString description READ description NOTIFY paramChanged)
    Q_PROPERTY(QVariantMap param READ param NOTIFY paramChanged)
    Q_PROPERTY(bool canPop READ canPop NOTIFY paramChanged)
    QML_ELEMENT
public:
    explicit Navigation(QObject* parent = nullptr);
    QString description() const;
    QVariantMap param() const { return m_param; }
    bool canPop() const { return m_history.size() > 1; }
public slots:
    void push(const QVariantMap& param);
    void set(const QVariantMap& param);
    void pop();
signals:
    void paramChanged();
private:
    QStack<QVariantMap> m_history;
    QVariantMap m_param;
};

#endif // GREEN_NAVIGATION_H
