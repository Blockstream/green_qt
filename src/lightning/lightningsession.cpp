#include "glsdk.hpp"
#include "lightningsession.h"

#include <QDebug>
#include <QFuture>
#include <QMetaObject>
#include <QMutex>
#include <QMutexLocker>
#include <QPointer>
#include <QThread>
#include <QWaitCondition>
#include <QtConcurrentRun>

#include <variant>

namespace {

QJsonObject ToJsonObject(const LightningNodeInfo& node_info)
{
    return {
        { "id", node_info.id },
        { "block_height", static_cast<qint64>(node_info.block_height) },
        { "channel_balance", static_cast<qint64>(node_info.channel_balance) },
        { "onchain_balance", static_cast<qint64>(node_info.onchain_balance) },
        { "inbound_liquidity", static_cast<qint64>(node_info.inbound_liquidity) },
        { "max_payable", static_cast<qint64>(node_info.max_payable) },
        { "max_receivable", static_cast<qint64>(node_info.max_receivable) },
    };
}

QFuture<void> DisconnectNodeAsync(const std::shared_ptr<LightningClient>& client, const std::shared_ptr<glsdk::Node>& node, const std::shared_ptr<QMutex>& mutex)
{
    return QtConcurrent::run([client, node, mutex] {
        QMutexLocker locker(mutex.get());
        client->disconnectNode(node);
    });
}

} // namespace

class LightningSessionEventListener final : public glsdk::NodeEventListener
{
public:
    class EventScope
    {
    public:
        explicit EventScope(LightningSessionEventListener* listener)
            : m_listener(listener)
        {
            QMutexLocker locker(&m_listener->m_mutex);
            m_session = m_listener->m_session;
            if (m_session) {
                ++m_listener->m_active_events;
                m_active = true;
            }
        }

        ~EventScope()
        {
            if (!m_active) return;

            QMutexLocker locker(&m_listener->m_mutex);
            --m_listener->m_active_events;
            if (m_listener->m_active_events == 0) {
                m_listener->m_event_condition.wakeAll();
            }
        }

        QPointer<LightningSession> session() const { return m_session; }

    private:
        LightningSessionEventListener* const m_listener;
        QPointer<LightningSession> m_session;
        bool m_active{false};
    };

    explicit LightningSessionEventListener(LightningSession* session)
        : m_session(session)
    {
    }

    void clearSessionAndWait()
    {
        QMutexLocker locker(&m_mutex);
        m_session = nullptr;
        while (m_active_events > 0) {
            m_event_condition.wait(&m_mutex);
        }
    }

    void on_event(glsdk::NodeEvent event) override
    {
        EventScope scope(this);
        const auto session = scope.session();
        if (!session) return;

        const auto& variant = event.get_variant();
        if (std::holds_alternative<glsdk::NodeEvent::kInvoicePaid>(variant)) {
            const auto details = std::get<glsdk::NodeEvent::kInvoicePaid>(variant).details;
            const auto bolt11_invoice = QString::fromStdString(details.bolt11);
            const auto amount_satoshi = details.amount_msat / 1000ULL;

            QMetaObject::invokeMethod(session.data(), [session, bolt11_invoice, amount_satoshi] {
                if (!session) return;
                emit session->invoicePaid(bolt11_invoice, amount_satoshi);
                session->refreshNodeInfo();
                session->refreshPayments();
            }, Qt::QueuedConnection);
        }
    }

private:
    QMutex m_mutex;
    QWaitCondition m_event_condition;
    QPointer<LightningSession> m_session;
    int m_active_events{0};
};

LightningSession::LightningSession(QObject* parent)
    : QObject(parent)
    , m_client(std::make_shared<LightningClient>())
    , m_event_listener(std::make_shared<LightningSessionEventListener>(this))
    , m_node_operation_mutex(std::make_shared<QMutex>())
{
}

LightningSession::~LightningSession()
{
    m_event_listener->clearSessionAndWait();
    m_connect_synchronizer.waitForFinished();
    if (m_connect_future_started) {
        const auto result = m_connect_future.result();
        if (result.node && result.node != m_node) {
            QMutexLocker locker(m_node_operation_mutex.get());
            m_client->disconnectNode(result.node);
        }
    }
    disconnectNode();
    m_future_synchronizer.waitForFinished();
    m_refresh_synchronizer.waitForFinished();
    m_payments_synchronizer.waitForFinished();
    qDebug() << Q_FUNC_INFO << "Lightning session destroyed";
}

std::shared_ptr<glsdk::NodeEventListener> LightningSession::eventListener() const
{
    return std::static_pointer_cast<glsdk::NodeEventListener>(m_event_listener);
}

QFuture<QString> LightningSession::connectNode(const QString& mnemonic)
{
    if (QThread::currentThread() != thread()) {
        QFuture<QString> future;
        QMetaObject::invokeMethod(this, [this, mnemonic, &future] {
            future = connectNode(mnemonic);
        }, Qt::BlockingQueuedConnection);
        return future;
    }

    bool started = false;
    quint64 node_generation = 0;
    std::shared_ptr<LightningClient> client;
    std::shared_ptr<glsdk::NodeEventListener> event_listener;
    std::shared_ptr<QMutex> mutex;
    const auto begin = [this, &started, &node_generation, &client, &event_listener, &mutex] {
        started = beginConnect();
        if (!started) return;

        client = m_client;
        event_listener = eventListener();
        mutex = m_node_operation_mutex;
        node_generation = m_node_generation;
    };

    begin();

    if (!started) return QtConcurrent::run([] { return QString(); });

    m_connect_future = QtConcurrent::run([=] {
        ConnectNodeResult result;
        QMutexLocker locker(mutex.get());

        const auto connect_result = client->connectNode(mnemonic, event_listener);
        if (!connect_result) {
            result.error = connect_result.error;
            return result;
        } else {
            result.node = *connect_result.value;

            const auto node_info = client->refreshNodeInfo(result.node);
            if (!node_info) {
                result.error = node_info.error;
                client->disconnectNode(result.node);
                result.node.reset();
                return result;
            } else {
                result.node_info = *node_info.value;

                const auto payments = client->listPayments(result.node);
                if (payments) {
                    result.payments = *payments.value;
                } else {
                    result.error = payments.error;
                }
            }
        }
        return result;
    });

    m_connect_future_started = true;

    m_connect_synchronizer.addFuture(m_connect_future);

    return m_connect_future.then(this, [=, this](const ConnectNodeResult& result) -> QString {
        if (m_node_generation != node_generation || m_state != State::Connecting) {
            if (result.node) {
                m_future_synchronizer.addFuture(DisconnectNodeAsync(client, result.node, mutex));
            }
            return {};
        }

        if (result.node && result.node_info) {
            finishConnect(result.node, *result.node_info, result.error);
            if (result.payments) {
                emit paymentsUpdated(*result.payments);
            }
        } else {
            failConnect(result.error);
        }

        return result.error;
    });
}

QFuture<LightningCreateInvoiceResult> LightningSession::createInvoice(const quint64 satoshi, const QString& description) const
{
    if (QThread::currentThread() != thread()) {
        QFuture<LightningCreateInvoiceResult> future;
        QMetaObject::invokeMethod(const_cast<LightningSession*>(this), [this, satoshi, description, &future] {
            future = createInvoice(satoshi, description);
        }, Qt::BlockingQueuedConnection);
        return future;
    }

    const auto client = m_client;
    const auto node = m_node;
    const auto mutex = m_node_operation_mutex;

    return QtConcurrent::run([client, node, mutex, satoshi, description] {
        LightningCreateInvoiceResult result;
        QMutexLocker locker(mutex.get());

        const auto invoice = client->createInvoice(node, satoshi, description);
        if (!invoice) {
            result.error = invoice.error;
            return result;
        }

        result.invoice = invoice.value->bolt11;
        result.opening_fee = invoice.value->opening_fee;

        const auto parsed = client->parseInvoice(result.invoice);
        if (parsed) {
            result.expires_at = QDateTime::fromSecsSinceEpoch(parsed.value->timestamp + parsed.value->expiry);
        }

        return result;
    });
}

LightningValueResult<LightningParsedInvoice> LightningSession::parseInvoice(const QString& input) const
{
    return m_client->parseInvoice(input);
}

bool LightningSession::beginConnect()
{
    if (m_state != State::Disconnected && m_state != State::Failed) return false;

    setError({});
    setState(State::Connecting);
    return true;
}

void LightningSession::finishConnect(const std::shared_ptr<glsdk::Node>& node, const LightningNodeInfo& node_info, const QString& error)
{
    if (m_node && m_node != node) {
        m_future_synchronizer.addFuture(DisconnectNodeAsync(m_client, m_node, m_node_operation_mutex));
    }
    m_node = node;
    ++m_node_generation;
    setNodeInfo(ToJsonObject(node_info));
    setError(error);
    setState(State::Connected);
}

void LightningSession::failConnect(const QString& error)
{
    const auto node = m_node;
    m_node.reset();
    ++m_node_generation;
    if (node) {
        m_future_synchronizer.addFuture(DisconnectNodeAsync(m_client, node, m_node_operation_mutex));
    }
    setNodeInfo({});
    setError(error);
    setState(State::Failed);
}

void LightningSession::disconnectNode()
{
    const auto node = m_node;
    m_node.reset();
    ++m_node_generation;

    if (node) {
        setState(State::Disconnecting);
        m_future_synchronizer.addFuture(DisconnectNodeAsync(m_client, node, m_node_operation_mutex));
    }

    setNodeInfo({});
    setError({});
    setState(State::Disconnected);
}

void LightningSession::refreshNodeInfo()
{
    const auto node = m_node;
    if (!node) {
        setError(QStringLiteral("GL-SDK node is not connected"));
        return;
    }

    const auto client = m_client;
    const auto mutex = m_node_operation_mutex;
    const auto node_generation = m_node_generation;

    auto future = QtConcurrent::run([client, node, mutex] {
        QMutexLocker locker(mutex.get());
        return client->refreshNodeInfo(node);
    });

    future.then(this, [=, this](LightningValueResult<LightningNodeInfo> result) {
        if (m_node != node || m_node_generation != node_generation) return;

        if (!result) {
            setError(result.error);
            return;
        }

        setNodeInfo(ToJsonObject(*result.value));
    });

    m_refresh_synchronizer.addFuture(future);
}

void LightningSession::refreshPayments()
{
    const auto node = m_node;
    if (!node) {
        setError(QStringLiteral("GL-SDK node is not connected"));
        return;
    }

    const auto client = m_client;
    const auto mutex = m_node_operation_mutex;
    const auto node_generation = m_node_generation;

    auto future = QtConcurrent::run([client, node, mutex] {
        QMutexLocker locker(mutex.get());
        return client->listPayments(node);
    });

    future.then(this, [=, this](LightningValueResult<std::vector<LightningPayment>> result) {
        if (m_node != node || m_node_generation != node_generation) return;

        if (!result) {
            setError(result.error);
            return;
        }

        emit paymentsUpdated(*result.value);
    });

    m_payments_synchronizer.addFuture(future);
}

void LightningSession::setState(State state)
{
    if (m_state == state) return;
    m_state = state;
    emit stateChanged();
}

void LightningSession::setError(const QString& error)
{
    if (m_error == error) return;
    m_error = error;
    emit errorChanged();
}

void LightningSession::setNodeInfo(const QJsonObject& node_info)
{
    if (m_node_info == node_info) return;
    m_node_info = node_info;
    emit nodeInfoChanged();
}
