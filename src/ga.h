#ifndef GREEN_GA_H
#define GREEN_GA_H

#include <QJsonArray>
#include <QJsonObject>

struct GA_session;
struct GA_auth_handler;

namespace GA {

int reconnect_hint(GA_session* session, const QJsonObject& data);
int connect(GA_session* session, const QJsonObject& data);
QJsonObject auth_handler_get_result(GA_auth_handler* call);
QJsonObject convert_amount(GA_session* session, const QJsonObject& input);
QStringList generate_mnemonic();

} // namespace GA

#endif // GREEN_GA_H
