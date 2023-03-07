#ifndef GREEN_FEEESTIMATES_H
#define GREEN_FEEESTIMATES_H

#include <QJsonArray>
#include <QObject>
#include <QQmlEngine>
#include <QTimer>

#include "connectable.h"

class Context;

class FeeEstimates : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context WRITE setContext NOTIFY contextChanged)
    Q_PROPERTY(QJsonArray fees READ fees NOTIFY feesChanged)
    QML_ELEMENT
public:
    FeeEstimates(QObject* parent = nullptr);
    Context* context() const { return m_context; }
    void setContext(Context* context);
    QJsonArray fees() const { return m_fees; }
signals:
    void contextChanged();
    void feesChanged();
private slots:
    void update();
private:
    Context* m_context{nullptr};
    QJsonArray m_fees;
    QTimer m_update_timer;
};

#endif // GREEN_FEEESTIMATES_H
