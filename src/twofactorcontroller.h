#ifndef GREEN_TWOFACTORCONTROLLER_H
#define GREEN_TWOFACTORCONTROLLER_H

#include "controllers/controller.h"

#include <QByteArray>

class TwoFactorController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QByteArray method READ method WRITE setMethod NOTIFY methodChanged)

public:
    explicit TwoFactorController(QObject *parent = nullptr);

    QByteArray method() const;
    void setMethod(const QByteArray& method);

    Q_INVOKABLE void enable(const QByteArray& data);
    Q_INVOKABLE void disable();

    Q_INVOKABLE void changeLimit(bool is_fiat, const QString &limit);

    bool update(const QJsonObject& result) override;

signals:
    void methodChanged(const QByteArray& method);

private:
    QByteArray m_method;
};

class RequestTwoFactorResetController : public Controller
{
    Q_OBJECT

public:
    explicit RequestTwoFactorResetController(QObject* parent = nullptr);
    Q_INVOKABLE void execute(const QByteArray& email);
    bool update(const QJsonObject& result) override;
};

#endif // GREEN_TWOFACTORCONTROLLER_H
