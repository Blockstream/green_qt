#ifndef GREEN_PAYMENT_H
#define GREEN_PAYMENT_H

#include "green.h"

#include <QJsonObject>
#include <QQmlEngine>

class Payment : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    Q_PROPERTY(QDateTime updatedAt READ updatedAt NOTIFY updatedAtChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    Payment(Context* context);
    QJsonObject data() const { return m_data; }
    void update(const QJsonObject& data);
    QDateTime updatedAt() const { return m_updated_at; }
    void setUpdatedAt(const QDateTime& updated_at);
    QString status() const { return m_status; }
    void setStatus(const QString& status);
signals:
    void dataChanged();
    void updatedAtChanged();
    void statusChanged();
private:
    const Context* m_context;
    QJsonObject m_data;
    QDateTime m_updated_at;
    QString m_status;
};

#endif // GREEN_PAYMENT_H
