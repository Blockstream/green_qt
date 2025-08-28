#ifndef GREEN_TWOFACTORCONTROLLER_H
#define GREEN_TWOFACTORCONTROLLER_H

#include "sessioncontroller.h"

#include <QQmlEngine>

class TwoFactorController : public SessionController
{
    Q_OBJECT
    Q_PROPERTY(QString method READ method WRITE setMethod NOTIFY methodChanged)
    QML_ELEMENT
public:
    explicit TwoFactorController(QObject* parent = nullptr);
    QString method() const { return m_method; }
    void setMethod(const QString& method);
public slots:
    void enable(const QString& data);
    void disable();
    void changeLimits(const QString& satoshi);
    void setCsvTime(int value);
signals:
    void methodChanged();
private:
    void change(const QJsonObject& details);
    QString m_method;
};

#endif // GREEN_TWOFACTORCONTROLLER_H
