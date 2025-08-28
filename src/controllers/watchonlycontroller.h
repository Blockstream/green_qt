#ifndef GREEN_WATCHONLYCONTROLLER_H
#define GREEN_WATCHONLYCONTROLLER_H

#include "sessioncontroller.h"

#include <QQmlEngine>

class WatchOnlyController : public SessionController
{
    Q_OBJECT
    QML_ELEMENT
public:
    WatchOnlyController(QObject* parent = nullptr);
public slots:
    void update(const QString& username, const QString& password);
    void clear();
signals:
};

#endif // GREEN_WATCHONLYCONTROLLER_H
