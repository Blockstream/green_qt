#ifndef GREEN_SETTINGSCONTROLLER_H
#define GREEN_SETTINGSCONTROLLER_H

#include "controllers/controller.h"

class SettingsController : public Controller
{
    Q_OBJECT
public:
    SettingsController(QObject* parent = nullptr);

    Q_INVOKABLE void changeALTimeout(int al_timeout);
    Q_INVOKABLE void change(const QJsonObject& data);

    bool update(const QJsonObject& result) override;
};

#endif // GREEN_SETTINGSCONTROLLER_H
