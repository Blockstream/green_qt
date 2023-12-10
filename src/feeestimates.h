#ifndef GREEN_FEEESTIMATES_H
#define GREEN_FEEESTIMATES_H

#include "green.h"

#include <QJsonArray>
#include <QObject>
#include <QQmlEngine>
#include <QTimer>

class FeeEstimates : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Session* session READ session WRITE setSession NOTIFY sessionChanged)
    Q_PROPERTY(QJsonArray fees READ fees NOTIFY feesChanged)
    QML_ELEMENT
public:
    FeeEstimates(QObject* parent = nullptr);
    Session* session() const { return m_session; }
    void setSession(Session* session);
    QJsonArray fees() const { return m_fees; }
signals:
    void sessionChanged();
    void feesChanged();
private slots:
    void update();
private:
    Session* m_session{nullptr};
    QJsonArray m_fees;
    QTimer m_update_timer;
};

#endif // GREEN_FEEESTIMATES_H
