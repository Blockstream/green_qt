#include "account.h"
#include "json.h"
#include "getunspentoutputshandler.h"

#include <gdk.h>

void GetUnspentOutputsHandler::call(GA_session *session, GA_auth_handler **auth_handler)
{
    auto details = Json::fromObject({
        { "subaccount", static_cast<qint64>(m_subaccount) },
        { "num_confs", m_num_confs },
        { "all_coins", m_all_coins }
    });

    int err = GA_get_unspent_outputs(session, details.get(), auth_handler);
    Q_ASSERT(err == GA_OK);
}

GetUnspentOutputsHandler::GetUnspentOutputsHandler(int num_confs, bool all_coins, Account* account)
    : Handler(account->wallet()->session())
    , m_subaccount(account->pointer())
    , m_num_confs(num_confs)
    , m_all_coins(all_coins)
{
}

QJsonObject GetUnspentOutputsHandler::unspentOutputs() const
{
    return result().value("result").toObject().value("unspent_outputs").toObject();
}
