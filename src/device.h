#ifndef GREEN_DEVICE_H
#define GREEN_DEVICE_H

#include <QObject>

class Device : public QObject
{
    Q_OBJECT
public:
    explicit Device(QObject* parent = nullptr);
};

#endif // GREEN_DEVICE_H
