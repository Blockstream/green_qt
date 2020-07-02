#ifndef GREEN_SETTINGSCONTROLLER_H
#define GREEN_SETTINGSCONTROLLER_H

#include <QtQml>

#include "controller.h"

class SettingsController : public Controller
{
    Q_OBJECT
    QML_ELEMENT
public:
    SettingsController(QObject* parent = nullptr);

    Q_INVOKABLE void change(const QJsonObject& data);
    Q_INVOKABLE void sendRecoveryTransactions();

    bool update(const QJsonObject& result) override;
};

#endif // GREEN_SETTINGSCONTROLLER_H
