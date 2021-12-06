#include "createtransactionhandler.h"
#include "json.h"
#include "network.h"
#include "session.h"

#include <gdk.h>
#include <QDebug>


CreateTransactionHandler::CreateTransactionHandler(const QJsonObject& details, Session* session)
    : Handler(session)
    , m_details(details)
{
}

QJsonObject CreateTransactionHandler::transaction() const
{
    auto network = session()->network();
    auto data = result().value("result").toObject();
    QJsonArray addressees;
    auto send_all = data.value("send_all").toBool();
    if (send_all && !network->isElectrum()) {
        for (auto value : data.value("addressees").toArray()) {
            auto object = value.toObject();
            auto asset_id = network->isLiquid() ? object.value("asset_id").toString() : "btc";
            auto satoshi = data.value("satoshi").toObject().value(asset_id).toDouble();
            object.insert("satoshi", satoshi);
            addressees.append(object);
        }
    } else {
        addressees = data.value("addressees").toArray();
    }
    data.insert("_addressees", addressees);
    qDebug() << Q_FUNC_INFO << data;
    return data;
}

void CreateTransactionHandler::call(GA_session* session, GA_auth_handler** auth_handler)
{
    auto details = Json::fromObject(m_details);
    int err = GA_create_transaction(session, details.get(), auth_handler);
    Q_ASSERT(err == GA_OK);
}

