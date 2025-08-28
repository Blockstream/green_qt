#ifndef GREEN_ABSTRACTCONTROLLER_H
#define GREEN_ABSTRACTCONTROLLER_H

#include "entity.h"

#include <QVariantMap>
#include <QObject>
#include <QQmlEngine>

class AbstractController : public Entity
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap errors READ errors NOTIFY errorsChanged)
    Q_PROPERTY(bool noErrors READ noErrors NOTIFY errorsChanged)
    QML_ELEMENT
public:
    AbstractController(QObject* parent = nullptr);
    QVariantMap errors() const { return m_errors; }
    bool noErrors() const { return m_errors.isEmpty(); }
public slots:
    void clearErrors();
signals:
    void errorsChanged();
protected:
    void setError(const QString& key, const QVariant& value);
    void clearError(const QString& key);
    bool updateError(const QString &key, const QVariant &value, bool when);
private:
    QVariantMap m_errors;
};

#endif // GREEN_ABSTRACTCONTROLLER_H
