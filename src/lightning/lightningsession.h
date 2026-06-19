#ifndef BLOCKSTREAM_LIGHTNING_SESSION_H
#define BLOCKSTREAM_LIGHTNING_SESSION_H

#include "lightningclient.h"

#include <QDateTime>
#include <QFuture>
#include <QFutureSynchronizer>
#include <QJsonObject>
#include <QMutex>
#include <QObject>
#include <QString>

#include <memory>

namespace glsdk {
struct Node;
struct NodeEventListener;
}

class LightningSessionEventListener;

struct LightningCreateInvoiceResult {
    QString invoice;
    quint64 opening_fee{0};
    QDateTime expires_at;
    QString error;
};

class LightningSession final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QJsonObject nodeInfo READ nodeInfo NOTIFY nodeInfoChanged)
public:
    enum class State {
        Disconnected,
        Connecting,
        Connected,
        Failed,
        Disconnecting,
    };
    Q_ENUM(State)

    explicit LightningSession(QObject* parent = nullptr);
    ~LightningSession() override;

    State state() const { return m_state; }
    QString error() const { return m_error; }
    QJsonObject nodeInfo() const { return m_node_info; }
    QFuture<QString> connectNode(const QString& mnemonic);
    QFuture<LightningCreateInvoiceResult> createInvoice(quint64 satoshi, const QString& description) const;
    LightningValueResult<LightningParsedInvoice> parseInvoice(const QString& input) const;
    void disconnectNode();
    void refreshNodeInfo();
    void refreshPayments();

signals:
    void stateChanged();
    void errorChanged();
    void nodeInfoChanged();
    void invoicePaid(QString bolt11_invoice, quint64 amount_satoshi);
    void paymentsUpdated(const std::vector<LightningPayment>& payments);

private:
    struct ConnectNodeResult {
        std::shared_ptr<glsdk::Node> node;
        std::optional<LightningNodeInfo> node_info;
        std::optional<std::vector<LightningPayment>> payments;
        QString error;
    };

    std::shared_ptr<glsdk::NodeEventListener> eventListener() const;
    bool beginConnect();
    void finishConnect(const std::shared_ptr<glsdk::Node>& node, const LightningNodeInfo& node_info, const QString& error);
    void failConnect(const QString& error);
    void setState(State state);
    void setError(const QString& error);
    void setNodeInfo(const QJsonObject& node_info);

    std::shared_ptr<LightningClient> m_client;
    std::shared_ptr<LightningSessionEventListener> m_event_listener;
    std::shared_ptr<QMutex> m_node_operation_mutex;
    QFuture<ConnectNodeResult> m_connect_future;
    QFutureSynchronizer<ConnectNodeResult> m_connect_synchronizer;
    bool m_connect_future_started{false};
    QFutureSynchronizer<void> m_future_synchronizer;
    QFutureSynchronizer<LightningValueResult<LightningNodeInfo>> m_refresh_synchronizer;
    QFutureSynchronizer<LightningValueResult<std::vector<LightningPayment>>> m_payments_synchronizer;
    std::shared_ptr<glsdk::Node> m_node;
    QJsonObject m_node_info;
    State m_state{State::Disconnected};
    QString m_error;
    quint64 m_node_generation{0};
};

#endif // BLOCKSTREAM_LIGHTNING_SESSION_H
