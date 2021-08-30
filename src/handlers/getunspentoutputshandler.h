#ifndef GREEN_GETUNSPENTOUTPUTSHANDLER_H
#define GREEN_GETUNSPENTOUTPUTSHANDLER_H

#include "handler.h"

QT_FORWARD_DECLARE_CLASS(Account)

class GetUnspentOutputsHandler : public Handler
{
    qint32 m_subaccount;
    int m_num_confs;
    bool m_all_coins;
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    GetUnspentOutputsHandler(int num_confs, bool all_coins, Account* account);
    QJsonObject unspentOutputs() const;
};

#endif // GREEN_GETUNSPENTOUTPUTSHANDLER_H
