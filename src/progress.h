#ifndef GREEN_PROGRESS_H
#define GREEN_PROGRESS_H

#include <QObject>
#include <QQmlEngine>

class Progress : public QObject
{
    Q_OBJECT
    Q_PROPERTY(qreal from READ from NOTIFY fromChanged)
    Q_PROPERTY(qreal to READ to NOTIFY toChanged)
    Q_PROPERTY(qreal value READ value NOTIFY valueChanged)
    Q_PROPERTY(bool indeterminate READ indeterminate NOTIFY indeterminateChanged)
    QML_ANONYMOUS
public:
    Progress(QObject* parent = nullptr);
    qreal from() const { return m_from; }
    void setFrom(qreal from);
    qreal to() const { return m_to; }
    void setTo(qreal to);
    qreal value() const { return m_value; }
    void setValue(qreal value);
    void incrementValue(int inc = 1);
    bool indeterminate() const { return m_indeterminate; }
    void setIndeterminate(bool indeterminate);
signals:
    void fromChanged(qreal from);
    void toChanged(qreal to);
    void valueChanged(qreal value);
    void indeterminateChanged(bool indeterminate);
private:
    qreal m_from{0};
    qreal m_to{1};
    qreal m_value{0};
    bool m_indeterminate{true};
};

#endif // GREEN_PROGRESS_H
