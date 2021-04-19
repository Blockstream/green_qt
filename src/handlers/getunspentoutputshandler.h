#ifndef GREEN_GETUNSPENTOUTPUTSHANDLER_H
#define GREEN_GETUNSPENTOUTPUTSHANDLER_H

#include "handler.h"

class GetUnspentOutputsHandler : public Handler
{
    int m_subaccount;
    int m_num_confs;
    bool m_all_coins;
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    GetUnspentOutputsHandler(int subaccount, int num_confs, bool all_coins, Wallet *wallet);
    QJsonObject unspentOutputs() const;
};

#endif // GREEN_GETUNSPENTOUTPUTSHANDLER_H
