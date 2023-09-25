#include "jadeapi.h"

#include <QCborArray>
#include <QCborMap>
#include <QCborValue>
#include <QCryptographicHash>
#include <QDateTime>
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QThread>
#include <QTimer>
#include <QVariant>

#include "jadebleimpl.h"
#include "jadeserialimpl.h"

// Useful for sending null values in tx-signing calls
QVariant JadeAPI::NULL_CHANGE_ENTRY;
QVariantMap JadeAPI::NULL_COMMITMENT_ENTRY;

// Helpers to build basic jade cbor request object
static inline QCborMap getRequest(const int id, const QString& method) {
    QCborMap req;
    req.insert(QCborValue("id"), QString::number(id));
    req.insert(QCborValue("method"), method);
    return req;
}

static inline QCborMap getRequest(const int id, const QString& method, const QCborValue& params) {
    QCborMap req(getRequest(id, method));
    if (!params.isNull()) {
        req.insert(QCborValue("params"), params);
    }
    return req;
}

// Create with serial connection
JadeAPI::JadeAPI(const QSerialPortInfo& deviceInfo, bool relax_write, QObject *parent)
    : JadeAPI(new JadeSerialImpl(deviceInfo, relax_write, parent), relax_write, parent) // temporary impl owership
{
    // qDebug() << "JadeAPI::JadeAPI(serial)";
}

// Create with BLE connection
JadeAPI::JadeAPI(const QBluetoothDeviceInfo& deviceInfo, QObject *parent)
    : JadeAPI(new JadeBleImpl(deviceInfo, parent), false, parent) // temporary impl owership
{
    // qDebug() << "JadeAPI::JadeAPI(ble)";
}

// Private ctor
JadeAPI::JadeAPI(JadeConnection *connection, bool relax_write, QObject *parent)
    : QObject(parent),
      m_idgen(QRandomGenerator::securelySeeded()),
      m_responseHandlers(),
      m_jade(connection),
      m_relax_write(relax_write)
{
    m_jade->setParent(this);  // take impl ownership here

    // Connect the underlying connection's 'new message' signal to our handler
    connect(m_jade, &JadeConnection::onNewMessageReceived,
            this, &JadeAPI::processResponseMessage);

    // Forward connection/disconnection signals from underlying connection
    connect(m_jade, &JadeConnection::onOpenError,
            this, &JadeAPI::onOpenError);
    connect(m_jade, &JadeConnection::onConnected,
            this, &JadeAPI::onConnected);
    connect(m_jade, &JadeConnection::onDisconnected,
            this, &JadeAPI::onDisconnected);
}

JadeAPI::~JadeAPI()
{
    // Disconnect the underlying connection's signals
    disconnect(m_jade, nullptr, this, nullptr);
}

// Manage the underlying connection
bool JadeAPI::isConnected()
{
    return m_jade->isConnected();
}

void JadeAPI::connectDevice()
{
    m_jade->connectDevice();
}

void JadeAPI::disconnectDevice()
{
    m_jade->disconnectDevice();
}

bool JadeAPI::isIdle() const
{
    return !m_idle_timer.isValid() || m_idle_timer.elapsed() > 30000;
}

bool JadeAPI::isBusy() const
{
    return !m_responseHandlers.isEmpty();
}

// Handle result of an http-request.
// MUST be called when an http-request response is received.
void JadeAPI::handleHttpResponse(const int id, const QJsonObject &httpRequest, const QJsonValue &httpResponse)
{
    m_idle_timer.restart();

    // qDebug() << "JadeAPI::handleHttpResponse() called for" << id << "with response data" << httpResponse;

    Q_ASSERT(httpRequest.contains("on-reply"));
    Q_ASSERT(httpRequest["on-reply"].isString());

    // Make new response handler that forwards the final result back to the prior response handler
    const int newId = registerResponseHandler(
                [this, id](const QVariantMap &latestResponseMsg)
                {
                    forwardToResponseHandler(id, latestResponseMsg);
                });

    // Forward http-response back to 'on-reply' function in Jade using the above response handler
    const QString on_reply = httpRequest["on-reply"].toString();
    const QCborMap newRequest = getRequest(newId, on_reply, httpResponse.isObject() ? QCborMap::fromJsonObject(httpResponse.toObject()) : QCborValue());
    m_request_proxy[newId] = m_request_proxy[id];
    send(newRequest);
}

inline int JadeAPI::getNewId() {
    return m_idgen.bounded(10000,100000);
}

// Register callback for request/response when received
int JadeAPI::registerResponseHandler(const ResponseHandler &cb, int timeout) {
    Q_ASSERT(cb);
    Q_ASSERT(timeout >= 0);

    // Get a new id not currently present in the map
    int id = getNewId();
    for (int i = 0; i < 5 && m_responseHandlers.contains(id); ++i) {
        id = getNewId();
    }

    // Insert the callback keyed by id
    // qDebug() << "JadeAPI::registerResponseHandler() - Registering response handler with id" << id;
    m_responseHandlers.insert(id, cb);
    if (timeout > 0) m_msg_timeout[id] = timeout;

    // Return the new callback id
    return id;
}

// Invoke client callback for request/response when received
void JadeAPI::callResponseHandler(const QVariantMap &msg)
{
    m_idle_timer.restart();

    // Get the id from the message
    Q_ASSERT(msg["id"].isValid() && msg["id"].toString().toInt() > 0);
    const int id = msg["id"].toString().toInt();

    // qDebug() << "JadeAPI::callResponseHandler() called for message id" << id;

    // Get (ie. remove) the response handler for that id from the map of registered handlers
    const ResponseHandler handler = m_responseHandlers.take(id);
    m_request_proxy.remove(id);
    if (!handler)
    {
        // qWarning() << "JadeAPI::callResponseHandler() - Message ignored - no handler found for id" << msg;
        return;
    }

    // Call the handler, catching any exceptions
    // qDebug() << "JadeAPI::callResponseHandler() - calling/discarding located handler for id" << id;
    try {
        handler(msg);
    } catch(...) {
        qWarning() << "JadeAPI::callResponseHandler() - Error in client handler for" << msg;
    }
}

// Forward the message to the handler indicated by id, copying the map to update the id if necessary
void JadeAPI::forwardToResponseHandler(const int targetId, const QVariantMap &msg)
{
    m_idle_timer.restart();

    if (msg.contains("id") && msg["id"] == targetId)
    {
        // Already correct id, just forward
        callResponseHandler(msg);
    }
    else
    {
        // Copy result and update id, then forward
        QVariantMap idUpdated(msg);
        idUpdated["id"] = targetId;
        callResponseHandler(idUpdated);
    }
}

// The callback function invoked when a (complete) cbor message is received over the wrapped connection
void JadeAPI::processResponseMessage(const QCborMap &msg)
{
    m_idle_timer.restart();

    // qInfo() << "JadeAPI::processResponseMessage() received <-" << Qt::endl << msg;

    // Ensure the message has an id
    if (!msg.contains(QCborValue("id")) || !msg["id"].isString() || msg["id"].toString().toInt() == 0) {
        qWarning() << "JadeAPI::processResponseMessage() - Message ignored - no numeric string 'id' field:" << msg;
        return;
    }
    const int id = msg["id"].toString().toInt();

    if (msg.contains(QCborValue("result")) && msg["result"].isMap()
            && msg["result"].toMap().contains(QCborValue("http_request")))
    {
        qDebug() << "JadeAPI::processResponseMessage() - Jade response" << id << "requires http-request";
        Q_ASSERT(m_request_proxy.contains(id));

        // Handle responses which require the results of an http_request
        Q_ASSERT(msg["result"]["http_request"].isMap());
        const QCborMap httpRequest = msg["result"]["http_request"].toMap();

        // Make http-request.
        // NOTE: when http request returns, JadeAPI::handleHttpResponse() should be called, which
        // should result in another call to Jade, and ultimately this function being called again.
        m_request_proxy[id](*this, id, httpRequest.toJsonObject());
    }
    else
    {
        // Simple result or error - call registered callback
        callResponseHandler(msg.toVariantMap());
    }

    m_msg_inflight.remove(id);
    QTimer::singleShot(0, this, &JadeAPI::drain);
}

void JadeAPI::enqueue(const QCborMap &msg)
{
    m_idle_timer.restart();

    if (m_msg_inflight.isEmpty() && m_msg_queue.empty()) {
         // Nothing in progress, nothing queued: can send immediately
        send(msg);
    } else {
        m_msg_queue.enqueue(msg);
    }
}

void JadeAPI::send(const QCborMap &msg)
{
    // qInfo() << "JadeAPI::sendToJade() - Sending message ->" << Qt::endl << msg;
    Q_ASSERT(m_jade);
    m_jade->send(msg);
    int id = msg["id"].toString().toInt();
    int timeout = m_msg_timeout.value(id, 0);
    m_msg_inflight.insert(id);
    if (timeout > 0) QTimer::singleShot(timeout, this, [=] {
        // Get (ie. remove) the response handler for that id from the map of registered handlers
        const ResponseHandler handler = m_responseHandlers.take(id);
        if (!handler) return;
        QVariantMap error = {{ "message", "timeout" }};
        try {
            handler({{ "error", error }});
        } catch(...) {
            qWarning() << "JadeAPI::callResponseHandler() - Error in client handler for" << msg;
        }
        m_msg_inflight.remove(id);
        drain();
    });
}

void JadeAPI::drain()
{
    if (!m_msg_inflight.isEmpty()) return;
    if (m_msg_queue.isEmpty()) return;
    send(m_msg_queue.dequeue());
}

/*
 *  The API calls
 */

static QCborArray convertPath(const QVector<quint32> &path)
{
    QCborArray pathArray;
    for (const quint32 val : path) {
        pathArray.append(val);
    }
    return pathArray;
}
#ifndef QT_NO_DEBUG
// Set debug mnemonic
int JadeAPI::setMnemonic(const QString& mnemonic, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap params = { {"mnemonic", mnemonic} };
    const QCborMap request = getRequest(id, "debug_set_mnemonic", params);
    enqueue(request);
    return id;
}
#endif

// Get version information from the jade
int JadeAPI::getVersionInfo(const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb, 500);
    const QCborMap request = getRequest(id, "get_version_info");
    enqueue(request);
    return id;
}

// Send additional entropy for the rng to jade
int JadeAPI::addEntropy(const QByteArray &entropy, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap params = { {"entropy", entropy} };
    const QCborMap request = getRequest(id, "add_entropy", params);
    enqueue(request);
    return id;
}

// Trigger user authentication on the hw
// Involves pinserver handshake
int JadeAPI::authUser(const QString &network, const ResponseHandler &cb, const HttpRequestProxy& request_proxy)
{
    const int id = registerResponseHandler(cb);
    m_request_proxy[id] = request_proxy;

    const qint64 now_epoch_secs = QDateTime::currentSecsSinceEpoch();
    const QCborMap params = { {"network", network}, {"epoch", now_epoch_secs } };
    const QCborMap request = getRequest(id, "auth_user", params);
    enqueue(request);
    return id;
}

// OTA update the connected Jade
int JadeAPI::otaUpdate(const QByteArray& fwcmp, const int fwlen, const QString& fwhash, const int chunkSize, const ResponseHandler &cbProgress, const ResponseHandler &cb)
{
    // The exposed/returned id that will key the caller's handler (invoked
    // when the OTA completes successfully or errors).
    const int id = registerResponseHandler(cb);

    // Register the recursive callback used to upload ota data chunks
    const int tmpId = registerResponseHandler(makeOtaChunkCallback(id, fwcmp, chunkSize, 0, cbProgress));

    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(fwcmp);
    const auto cmphash = hash.result();

    // Initiate OTA process, and return the exposed id
    const int compressedSize = fwcmp.length();
    QCborMap params = { {"fwsize", fwlen}, {"cmpsize", compressedSize}, {"cmphash", cmphash} };
    if (!fwhash.isEmpty()) params.insert(QString("fwhash"), fwhash);
    const QCborMap request = getRequest(tmpId, "ota", params);
    enqueue(request);
    return id;
}

int JadeAPI::otaDeltaUpdate(const QByteArray& fwcmp, const int fwlen, const QString& fwhash, const int patch_size, const int chunkSize, const ResponseHandler &cbProgress, const ResponseHandler &cb)
{
    // The exposed/returned id that will key the caller's handler (invoked
    // when the OTA completes successfully or errors).
    const int id = registerResponseHandler(cb);

    // Register the recursive callback used to upload ota data chunks
    const int tmpId = registerResponseHandler(makeOtaChunkCallback(id, fwcmp, chunkSize, 0, cbProgress));

    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(fwcmp);
    const auto cmphash = hash.result();

    // Initiate OTA process, and return the exposed id
    const int compressedSize = fwcmp.length();
    QCborMap params = { {"fwsize", fwlen}, {"cmpsize", compressedSize}, {"cmphash", cmphash}, {"patchsize", patch_size} };
    if (!fwhash.isEmpty()) params.insert(QString("fwhash"), fwhash);
    const QCborMap request = getRequest(tmpId, "ota_delta", params);
    enqueue(request);
    return id;
}

// Helper for OTA (per-)chunk upload
JadeAPI::ResponseHandler JadeAPI::makeOtaChunkCallback(const int id, const QByteArray &fwcmp, const int chunkSize, const int currentPos, const ResponseHandler &cbProgress)
{
    return [this, id, fwcmp, chunkSize, currentPos, cbProgress](const QVariantMap& rslt)
    {
        Q_ASSERT(currentPos >= 0);
        Q_ASSERT(currentPos <= fwcmp.length());

        // If all good, send next chunk (or final message)
        if (rslt.contains("result") && rslt["result"].toBool())
        {
            qDebug() << "JadeAPI::makeOtaChunkCallback()::lambda for" << id << "uploaded" << currentPos << "/" << fwcmp.length();

            // Call progress callback if provided
            if (cbProgress)
            {
                try
                {
                    cbProgress(QVariantMap { {"id", QString::number(id)},
                                             {"size", fwcmp.length()},
                                             {"uploaded", currentPos} });
                }
                catch(...)
                {
                    qWarning() << "JadeAPI::otaUpdate() ERROR calling progress callback (ignored)";
                }
            }

            // Upload next data chunk
            if (currentPos < fwcmp.length())
            {
                // Locate next chunk
                const int nextChunkLen = fwcmp.length() - currentPos >= chunkSize ? chunkSize : fwcmp.size() - currentPos;
                const QByteArray nextChunk = fwcmp.mid(currentPos, nextChunkLen);
                qDebug() << "JadeAPI::makeOtaChunkCallback()::lambda for" << id << "sending chunk of size" << nextChunkLen;

                // Send chunk to Jade, creating a new instance of this callback
                const int tmpId = registerResponseHandler(makeOtaChunkCallback(id, fwcmp, chunkSize, currentPos+nextChunkLen, cbProgress));
                const QCborMap otaData = getRequest(tmpId, "ota_data", nextChunk);
                send(otaData);
            }
            else
            {
                // Upload complete - send final message using exposed id (and hence directing response at callers handler)
                qDebug() << "JadeAPI::makeOtaChunkCallback()::lambda for" << id << "all chunks uploaded - sending ota_complete";
                const QCborMap otaData = getRequest(id, "ota_complete");
                send(otaData);
            }
        }
        else
        {
            // Error - stop loading chunks and forward error to caller's response handler
            forwardToResponseHandler(id, rslt);
        }
    };
}

// Get (receive) green address
int JadeAPI::getReceiveAddress(const QString &network, const quint32 subaccount, const quint32 branch, const quint32 pointer,
                               const QString &recoveryxpub, const quint32 csvBlocks, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap params = { {"network", network},
                              {"subaccount", subaccount},
                              {"branch", branch},
                              {"pointer", pointer},
                              {"recovery_xpub", recoveryxpub},
                              {"csv_blocks", csvBlocks}
                            };
    const QCborMap request = getRequest(id, "get_receive_address", params);
    enqueue(request);
    return id;
}

// Get (receive) green address
int JadeAPI::getReceiveAddress(const QString& network, const QString& variant, const QVector<quint32>& path, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap params = { {"network", network},
                              {"variant", variant},
                              {"path", convertPath(path) },
                            };
    const QCborMap request = getRequest(id, "get_receive_address", params);
    enqueue(request);
    return id;
}

// Get xpub given path
int JadeAPI::getXpub(const QString &network, const QVector<quint32> &path, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap params = { {"network", network}, {"path", convertPath(path)} };
    const QCborMap request = getRequest(id, "get_xpub", params);
    enqueue(request);
    return id;
}

// Sign a message
int JadeAPI::signMessage(const QVector<quint32> &path, const QString &message, const QByteArray& ae_host_commitment, const QByteArray& ae_host_entropy, const ResponseHandler &cb)
{
    const int id = registerResponseHandler([this, ae_host_entropy, cb](const QVariantMap& rslt) {
        if (rslt.contains("error")) {
            cb(rslt);
            return;
        }
        const auto signer_commitment = rslt.value("result").toByteArray();
        const int id = registerResponseHandler([ae_host_entropy, signer_commitment, cb](const QVariantMap& rslt) {
            if (rslt.contains("error")) {
                cb(rslt);
                return;
            }
            const auto signature = rslt.value("result").toString();
            cb({ {"signature", signature}, {"signer_commitment", signer_commitment} });
        });
        const QCborMap params = { {"ae_host_entropy", ae_host_entropy} };
        const QCborMap request = getRequest(id, "get_signature", params);
        send(request);
    });
    const QCborMap params = { {"path", convertPath(path)}, {"message", message}, {"ae_host_commitment", ae_host_commitment} };
    const QCborMap request = getRequest(id, "sign_message", params);
    enqueue(request);
    return id;
}

// Sign a txn
int JadeAPI::signTx(const QString &network, const QByteArray &txn, const QVariantList &inputs, const QVariantList &change, const ResponseHandler &cb)
{
    // Protocol:
    // We send one message per input (which includes host-commitment *but
    // not* the host entropy) and receive the signer-commitment in reply.
    // Once all n input messages are sent, we can request the actual signatures
    // (as the user has a chance to confirm/cancel at this point).
    // We request the signatures passing the ae-entropy for each one.

    // The exposed/returned id that will key the caller's handler (invoked
    // when the signing process completes successfully or errors).
    const int id = registerResponseHandler(cb);

    // Send inputs one at a time, receiving 'signer-commitment' in reply
    // First interim callback to send the tx inputs once the initiating call has succeeded
    const int tmpId = registerResponseHandler(makeSignTxInitialCallback(id, inputs));

    // Initiate signing process, and return the exposed id
    const QCborMap params = { {"network", network},
                              {"use_ae_signatures", true},
                              {"txn", txn},
                              {"num_inputs", inputs.size()},
                              {"change", QCborArray::fromVariantList(change)} };
    const QCborMap request = getRequest(tmpId, "sign_tx", params);
    enqueue(request);
    return id;
}

// Helper for signTx / signLiquidTx for handling initial sign-tx response
JadeAPI::ResponseHandler JadeAPI::makeSignTxInitialCallback(const int id, const QVariantList &inputs)
{
    return [this, id, inputs](const QVariantMap& rslt)
    {
        // If all good, send first tx input
        if (rslt.contains("result") && rslt["result"].toBool())
        {
            Q_ASSERT(!inputs.isEmpty());

            // Structure to hold returned signer-commitments
            const QSharedPointer<QVariantList> commitments(new QVariantList());

            // Send first input (and receive signer-commitment in return)
            sendTxInput(id, 0, inputs, commitments);
        }
        else
        {
            // Error - forward error to caller's response handler
            forwardToResponseHandler(id, rslt);
        }
    };
}

// Helper for signTx / signLiquidTx to send tx input request
void JadeAPI::sendTxInput(const int id, const int index, const QVariantList &inputs, const QSharedPointer<QVariantList> &commitments)
{
    Q_ASSERT(index < inputs.size());

    qDebug() << "JadeAPI::sendTxInput() for " << id << " sending tx input " << index + 1 << " of " << inputs.size();

    auto input = inputs.at(index).toMap();
    input.remove("ae_host_entropy");
    const QCborMap params = QCborMap::fromVariantMap(input);

    const int inputId = registerResponseHandler(makeReceiveCommitmentCallback(id, index, inputs, commitments));
    const QCborMap request = getRequest(inputId, "tx_input", params);
    send(request);
}

// Helper for signTx / signLiquidTx to receive and collect the signatures
JadeAPI::ResponseHandler JadeAPI::makeReceiveCommitmentCallback(const int id, const int index, const QVariantList &inputs, const QSharedPointer<QVariantList> &commitments)
{
    Q_ASSERT(index >= 0);
    Q_ASSERT(index < inputs.size());
    Q_ASSERT(!commitments.isNull());

    return [this, id, index, inputs, commitments](const QVariantMap &rslt)
    {
        // We are expecting to receive the signer commitment for the given index
        Q_ASSERT(commitments->size() == index);

        // If all good, collect signatures and send next message
        if (rslt.contains("result"))
        {
            // Store the signer commitment
            commitments->append(rslt["result"].toByteArray());

            // Send next message - depends on whether we have all commitments already
            if (commitments->size() < inputs.size())
            {
                // Not yet recevied all signer-commitments, send next input
                sendTxInput(id, index + 1, inputs, commitments);
            }
            else
            {
                // Got all signer commitments - should be final index - start requesting signatures (one per input)
                Q_ASSERT(index == inputs.size() - 1);

                // Structure to hold returned signatures
                const QSharedPointer<QVariantList> signatures(new QVariantList());

                // Send first signature request, and get signature in return
                sendTxSignatureRequest(id, 0, inputs, commitments, signatures);
            }
        }
        else
        {
            // Error - forward error to caller's response handler
            forwardToResponseHandler(id, rslt);
        }
    };
}

// Helper for signTx / signLiquidTx to get tx signature request
void JadeAPI::sendTxSignatureRequest(const int id, const int index, const QVariantList &inputs, const QSharedPointer<QVariantList> &commitments, const QSharedPointer<QVariantList> &signatures)
{
    Q_ASSERT(index < inputs.size());

    qDebug() << "JadeAPI::sendTxSignatureRequest() for " << id << " sending signature request " << index + 1 << " of " << inputs.size();

    auto input = inputs.at(index).toMap();
    auto ae_host_entropy = input.value("ae_host_entropy").toByteArray();
    const QCborMap params = { {"ae_host_entropy", ae_host_entropy} };

    const int sigId = registerResponseHandler(makeReceiveSignatureCallback(id, index, inputs, commitments, signatures));
    const QCborMap request = getRequest(sigId, "get_signature", params);
    send(request);
}


// Helper for signTx / signLiquidTx to receive and collect the signatures
JadeAPI::ResponseHandler JadeAPI::makeReceiveSignatureCallback(const int id, const int index, const QVariantList &inputs, const QSharedPointer<QVariantList> &commitments, const QSharedPointer<QVariantList> &signatures)
{
    Q_ASSERT(index >= 0);
    Q_ASSERT(index < inputs.size());
    Q_ASSERT(!commitments.isNull());
    Q_ASSERT(!signatures.isNull());

    return [this, id, index, inputs, commitments, signatures](const QVariantMap &rslt)
    {
        // We are expecting to receive the signature for the given index
        Q_ASSERT(signatures->size() == index);

        // If all good, collect signatures
        if (rslt.contains("result"))
        {
            // Store the signature
            signatures->append(rslt["result"].toByteArray());

            // If we have all responses, forward them to caller's handler
            if (signatures->size() < inputs.size())
            {
                // Not yet received all signatures, send next request
                sendTxSignatureRequest(id, index + 1, inputs, commitments, signatures);
            }
            else
            {
                // Finished!  Collate all signatures and signer commitmetns and
                // pass them to the caller's original ResponseHandler callback.
                Q_ASSERT(commitments->size() == inputs.size());
                Q_ASSERT(signatures->size() == inputs.size());

                const QVariantMap result{
                    { "signatures", *signatures },
                    { "signer_commitments", *commitments }
                };
                const QVariantMap rslt = { {"id", id}, {"result", result} };
                forwardToResponseHandler(id, rslt);
            }
        }
        else
        {
            // Error - forward error to caller's response handler
            forwardToResponseHandler(id, rslt);
        }
    };
}

// Get a Liquid public blinding key for a given script
int JadeAPI::getBlindingKey(const QByteArray &script, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap params = { {"script", script} };
    const QCborMap request = getRequest(id, "get_blinding_key", params);
    enqueue(request);
    return id;
}

// Get the shared secret to unblind a tx, given the receiving script on
// our side and the pubkey of the sender (sometimes called "nonce" in Liquid)
// Get a Liquid public blinding key for a given script
int JadeAPI::getSharedNonce(const QByteArray &script, const QByteArray &their_pubkey, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap params = { {"script", script}, {"their_pubkey", their_pubkey} };
    const QCborMap request = getRequest(id, "get_shared_nonce", params);
    enqueue(request);
    return id;
}

// Get a "trusted" blinding factor to blind an output. Normally the blinding
// factors are generated and returned in the `get_commitments` call, but
// for the last output the VBF must be generated on the host side, so this
// call allows the host to get a valid ABF to compute the generator and
// then the "final" VBF. Nonetheless, this call is kept generic, and can
// also generate VBFs, thus the "type" parameter.
// `hashPrevouts` is computed as specified in BIP143 (double SHA of all
//   the outpoints being spent as input. It's not checked right away since
//   at this point Jade doesn't know anything about the tx we are referring
//   to. It will be checked later during `sign_liquid_tx`.
// `outputIndex` is the output we are trying to blind.
// `type` can either be "ASSET" or "VALUE" to generate ABFs or VBFs.
int JadeAPI::getBlindingFactor(const QByteArray &hashPrevouts, const quint32 outputIndex, const QString& type, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap params = { {"hash_prevouts", hashPrevouts}, {"output_index", outputIndex}, {"type", type} };
    const QCborMap request = getRequest(id, "get_blinding_factor", params);
    enqueue(request);
    return id;
}

// Generate the blinding factors and commitments for a given output.
// Can optionally get a "custom" VBF, normally used for the last
// input where the VBF is not random, but generated accordingly to
// all the others.
// `hashPrevouts` and `outputIndex` have the same meaning as in
//   the `getBlindingFactor()` call.
// NOTE: the `assetId` should be passed as it is normally displayed, so
// reversed compared to the "consensus" representation.
int JadeAPI::getCommitments(const QByteArray& assetId, const qint64 value, const QByteArray &hashPrevouts, const quint32 outputIndex, const QByteArray& vbf, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    QCborMap params = { {"asset_id", assetId}, {"value", value}, {"hash_prevouts", hashPrevouts}, {"output_index", outputIndex} };
    if (!vbf.isEmpty()) {
        params.insert(QCborValue("vbf"), vbf);
    }
    const QCborMap request = getRequest(id, "get_commitments", params);
    enqueue(request);
    return id;
}

// Sign a liquid tx - based on / shares much with signTx() above.
int JadeAPI::signLiquidTx(const QString &network, const QByteArray &txn, const QVariantList &inputs, const QVariantList &commitments, const QVariantList &change, const ResponseHandler &cb)
{
    // Protocol:
    // We send one message per input (which includes host-commitment *but
    // not* the host entropy) and receive the signer-commitment in reply.
    // Once all n input messages are sent, we can request the actual signatures
    // (as the user has a chance to confirm/cancel at this point).
    // We request the signatures passing the ae-entropy for each one.

    // The exposed/returned id that will key the caller's handler (invoked
    // when the signing process completes successfully or errors).
    const int id = registerResponseHandler(cb);

    // Send inputs one at a time, receiving 'signer-commitment' in reply
    // First interim callback to send the tx inputs once the initiating call has succeeded
    const int tmpId = registerResponseHandler(makeSignTxInitialCallback(id, inputs));

    // Initiate signing process, and return the exposed id
    const QCborMap params = { {"network", network},
                              {"use_ae_signatures", true},
                              {"txn", txn},
                              {"num_inputs", inputs.size()},
                              {"trusted_commitments", QCborArray::fromVariantList(commitments)},
                              {"change", QCborArray::fromVariantList(change)} };
    const QCborMap request = getRequest(tmpId, "sign_liquid_tx", params);
    enqueue(request);
    return id;
}

int JadeAPI::getMasterBlindingKey(const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap request = getRequest(id, "get_master_blinding_key");
    enqueue(request);
    return id;
}
