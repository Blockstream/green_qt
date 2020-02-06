#include "settingscontroller.h"
#include "ga.h"
#include "json.h"
#include "wallet.h"

SettingsController::SettingsController(QObject* parent)
    : Controller(parent)
{

}

void SettingsController::change(const QJsonObject& data)
{
    // Avoid unnecessary calls to GA_change_settings
    bool updated = true;
    auto settings = wallet()->settings();
    for (auto i = data.begin(); i != data.end(); ++i) {
        if (settings.value(i.key()) != i.value()) {
            updated = false;
            break;
        }
    }
    if (updated) return;

    // Check if wallet is undergoing reset
    if (wallet()->isLocked()) return;

    auto result = GA::process_auth([this, data] (GA_auth_handler** call) {
        auto settings = Json::fromObject(data);
        int err = GA_change_settings(session(), settings, call);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(settings);
        Q_ASSERT(err == GA_OK);
    });
    Q_ASSERT(result.value("status").toString() == "done");
    wallet()->updateSettings();
}

bool SettingsController::update(const QJsonObject& result)
{
    if (result.value("status").toString() == "done") {
        wallet()->updateSettings();
    }

    return Controller::update(result);
}
