#ifndef GREEN_GA_H
#define GREEN_GA_H

#include <QJsonArray>
#include <QJsonObject>

struct GA_session;

namespace GA {

QJsonObject convert_amount(GA_session* session, const QJsonObject& input);
QStringList generate_mnemonic(int size);

} // namespace GA

#endif // GREEN_GA_H
