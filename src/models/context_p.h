#ifndef BLOCKSTREAM_CONTEXT_P_H
#define BLOCKSTREAM_CONTEXT_P_H

#include "context.h"
#include "task.h"

class ContextPrivate
{
public:
    ContextPrivate(Context* context, const QString& deployment, bool bip39)
        : deployment(deployment)
        , bip39(bip39)
        , dispatcher(new TaskDispatcher(context))
        , transaction_model(new QStandardItemModel(context))
        , address_model(new QStandardItemModel(context))
        , coin_model(new QStandardItemModel(context))
        , payment_model(new QStandardItemModel(context))
    {
        transaction_model->setItemRoleNames({{ Qt::UserRole, "transaction" }});
        address_model->setItemRoleNames({{ Qt::UserRole, "address" }});
        coin_model->setItemRoleNames({{ Qt::UserRole, "output" }});
        payment_model->setItemRoleNames({{ Qt::UserRole, "payment" }});
    }
public:
    const QString deployment;
    const bool bip39;
    TaskDispatcher* const dispatcher;
    Wallet* wallet{nullptr};
    Device* device{nullptr};
    bool skip_load_accounts{false};
    bool remember{true};
    bool watchonly{false};
    bool assets_loaded{false};
    QString xpub_hash_id;
    QJsonObject device_details;
    QJsonObject credentials;
    QStringList mnemonic;
    QMap<Network*, Session*> sessions;
    QList<Session*> sessions_list;
    QList<Notification*> notifications;
    OutageNotification* outage_notification{nullptr};
    QList<Account*> accounts;
    QMap<QPair<Network*, quint32>, Account*> accounts_by_pointer;
    QMap<QString, ChainTransaction*> chain_transactions;
    QMap<QString, LightningTransaction*> lightning_transactions;
    QMap<ContextTransaction*, QStandardItem*> transaction_item;
    QMultiMap<QString, ContextTransaction*> transaction_map;
    QStandardItemModel* const transaction_model;
    QMap<Address*, QStandardItem*> address_item;
    QMap<QString, Address*> address_map;
    QStandardItemModel* const address_model;
    QMap<Output*, QStandardItem*> coin_item;
    QStandardItemModel* const coin_model;
    QMap<Payment*, QStandardItem*> payment_item;
    QStandardItemModel* const payment_model;
    LightningSession* lightning_session{nullptr};
    LwkAmp2AccountController* amp2_account_controller{nullptr};
};

#endif // BLOCKSTREAM_CONTEXT_P_H
