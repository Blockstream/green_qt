#include "settingscontroller.h"
#include "ga.h"
#include "json.h"
#include "wallet.h"

SettingsController::SettingsController(QObject* parent)
    : Controller(parent)
{

}

void SettingsController::changeALTimeout(int altimeout)
{
    dispatch([this, altimeout] (GA_session* session, GA_auth_handler** call) {
        auto settings = Json::fromObject({
            { "altimeout", altimeout }
        });
        int err = GA_change_settings(session, settings, call);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(settings);
        Q_ASSERT(err == GA_OK);
    });
}

bool SettingsController::update(const QJsonObject& result)
{
    if (result.value("status").toString() == "done") {
        wallet()->updateSettings();
    }

    return Controller::update(result);
}
