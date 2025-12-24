#ifndef GREEN_PAYMENT_H
#define GREEN_PAYMENT_H

#include "green.h"

#include <QJsonObject>
#include <QQmlEngine>

class Payment : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)
    Q_PROPERTY(Address* address READ address NOTIFY addressChanged)
    Q_PROPERTY(Transaction* transaction READ transaction NOTIFY transactionChanged)
    Q_PROPERTY(QDateTime updatedAt READ updatedAt NOTIFY updatedAtChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    Payment(Context* context);

    void update(const QJsonObject& data);
    void refresh();

    QJsonObject data() const { return m_data; }
    Address* address() const { return m_address; }
    Transaction* transaction() const { return m_transaction; }
    QDateTime updatedAt() const { return m_updated_at; }
    void setUpdatedAt(const QDateTime& updated_at);
    QString status() const { return m_status; }
    void setStatus(const QString& status);
signals:
    void dataChanged();
    void addressChanged();
    void transactionChanged();
    void updatedAtChanged();
    void statusChanged();
private:
    Context* const m_context;
    Address* m_address{nullptr};
    Transaction* m_transaction{nullptr};
    QJsonObject m_data;
    QDateTime m_updated_at;
    QString m_status;
};

#endif // GREEN_PAYMENT_H
