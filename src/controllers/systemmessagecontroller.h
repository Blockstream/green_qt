#ifndef GREEN_SYSTEMMESSAGECONTROLLER_H
#define GREEN_SYSTEMMESSAGECONTROLLER_H

#include "controller.h"

class SystemMessageController : public Controller
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit SystemMessageController(QObject *parent = nullptr);
    QString message() const;
public slots:
    void clear();
    void ack();
    void check();
signals:
    void message(const QString& text);
    void empty();
private:
    QStringList m_pending;
    QStringList m_accepted;
};

#endif // GREEN_SYSTEMMESSAGECONTROLLER_H
