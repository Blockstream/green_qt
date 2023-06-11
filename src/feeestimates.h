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
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(QJsonArray fees READ fees NOTIFY feesChanged)
    QML_ELEMENT
public:
    FeeEstimates(QObject* parent = nullptr);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    QJsonArray fees() const { return m_fees; }
signals:
    void accountChanged();
    void feesChanged();
private slots:
    void update();
private:
    Account* m_account{nullptr};
    QJsonArray m_fees;
    QTimer m_update_timer;
};

#endif // GREEN_FEEESTIMATES_H
