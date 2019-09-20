#ifndef GREEN_APPLICATIONENGINE_H
#define GREEN_APPLICATIONENGINE_H

#include <QQmlApplicationEngine>

class ApplicationEngine : public QQmlApplicationEngine
{
    Q_OBJECT
    Q_PROPERTY(bool debug READ isDebug CONSTANT)

public:
    explicit ApplicationEngine(QObject *parent = nullptr);

    bool isDebug() const;

    Q_INVOKABLE void clearCache();
};

#endif // GREEN_APPLICATIONENGINE_H
