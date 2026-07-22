#ifndef GREEN_RECIPIENT_H
#define GREEN_RECIPIENT_H

#include <QObject>
#include <QtQml>

#include "green.h"

class Convert;
class Recipient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Convert* convert READ convert CONSTANT)
    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY addressChanged)
    Q_PROPERTY(bool greedy READ isGreedy WRITE setGreedy NOTIFY greedyChanged)
    QML_ELEMENT
public:
    Recipient(QObject* parent = nullptr);
    Convert* convert() const { return m_convert; }
    QString address() const { return m_address; }
    void setAddress(const QString& address);
    bool isGreedy() const { return m_greedy; }
    void setGreedy(bool greedy);
signals:
    void addressChanged();
    void greedyChanged();
    void changed();
private:
    Convert* const m_convert;
    QString m_address;
    bool m_greedy{false};
};

#endif // GREEN_RECIPIENT_H
