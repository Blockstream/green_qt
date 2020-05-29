#include "settingscontroller.h"
#include "ga.h"
#include "json.h"
#include "wallet.h"

#include <gdk.h>

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

    dispatch([data] (GA_session* session, GA_auth_handler** call) {
        auto settings = Json::fromObject(data);
        int err = GA_change_settings(session, settings, call);
        Q_ASSERT(err == GA_OK);
        err = GA_destroy_json(settings);
        Q_ASSERT(err == GA_OK);
    });
}

void SettingsController::sendRecoveryTransactions()
{
    int err = GA_send_nlocktimes(session());
    // Can't Q_ASSERT(err == GA_OK) because err != GA_OK
    // if no utxos found (e.g. new wallet)
    Q_UNUSED(err);
}

bool SettingsController::update(const QJsonObject& result)
{
    if (result.value("status").toString() == "done") {
        wallet()->updateSettings();
    }

    return Controller::update(result);
}
