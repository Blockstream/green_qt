#ifndef GREEN_GA_H
#define GREEN_GA_H

#include <QCommandLineParser>
#include <QJsonArray>
#include <QJsonObject>

struct GA_session;

namespace gdk {

void init(const QCommandLineParser& args);
QJsonObject convert_amount(GA_session* session, const QJsonObject& input);
QStringList generate_mnemonic(int size);
QJsonObject get_settings(GA_session* session);
QJsonObject get_twofactor_config(GA_session* session);
QJsonObject get_available_currencies(GA_session* session);
QJsonArray get_fee_estimates(GA_session* session);

} // namespace gdk

#endif // GREEN_GA_H
