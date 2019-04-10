#ifndef GREEN_CREATEACCOUNTCONTROLLER_H
#define GREEN_CREATEACCOUNTCONTROLLER_H

#include "controller.h"

class CreateAccountController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)

public:
    explicit CreateAccountController(QObject *parent = nullptr);

    QString name() const;
    void setName(const QString& name);

signals:
    void nameChanged(QString name);

public slots:
    void reset();
    void create();

private:
    QString m_name;
};

#endif // GREEN_CREATEACCOUNTCONTROLLER_H
