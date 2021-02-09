#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QCborMap>
#include <QCborValue>
#include <QCborArray>
#include <QVariant>

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QThread>
#include <QTimer>

#include "jadebleimpl.h"
#include "jadeserialimpl.h"

#include "jadeapi.h"

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
    req.insert(QCborValue("params"), params);
    return req;
}

// The default http proxy request-call/response-handler.
// Uses QNetworkAccessManager to make http call, then passes the response
// to jadeapi.handleHttpResponse() after cleaning up.
// User can override this basic http-request implementation if desired.
// See: JadeAPI::setHttpRequestProxy() below.
static void defaultHttpRequestProxy(JadeAPI& jadeapi, const int id, const QJsonObject &httpRequest)
{
    qDebug() << "JadeAPI defaultHttpRequestProxy() called for" << id << "with" << httpRequest;

    // Assert httpRequest structure looks as exepcted
    Q_ASSERT(httpRequest.contains("params"));
    Q_ASSERT(httpRequest["params"].isObject());
    Q_ASSERT(httpRequest["params"].toObject().contains("urls"));
    Q_ASSERT(httpRequest["params"]["urls"].isArray());
    Q_ASSERT(httpRequest.contains("on-reply"));
    Q_ASSERT(httpRequest["on-reply"].isString());

    // Get http-request parameters
    const QJsonObject httpParams = httpRequest["params"].toObject();

    // Get the url (for now use first in list)
    const QJsonArray urls = httpParams["urls"].toArray();
    QNetworkRequest networkRequest(urls[0].toString());
    networkRequest.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    // Only handle POST atm
    Q_ASSERT(httpParams["method"] == "POST");

    // Get any data payload
    QByteArray data;
    if (httpParams.contains("data") && httpParams["data"].isObject())
    {
        data = QJsonDocument(httpParams["data"].toObject()).toJson(QJsonDocument::Compact);
    }

    // Connect callback for handling http-response
    QNetworkAccessManager *nam = new QNetworkAccessManager(&jadeapi);
    QObject::connect(nam, &QNetworkAccessManager::finished,
                     [nam, id, httpRequest, &jadeapi](QNetworkReply* response) {
        // Callback to handle response
        if (response->error() == QNetworkReply::NoError) {
            const QByteArray strReply = response->readAll();
            const QJsonObject httpResponse = QJsonDocument::fromJson(strReply).object();
            jadeapi.handleHttpResponse(id, httpRequest, httpResponse);
        }
        else
        {
            qWarning() << "JadeAPI defaultHttpRequestProxy() error handling http-response:" << response;
        }

        response->deleteLater();
        nam->deleteLater();
    });

    // Make http call
    nam->post(networkRequest, data);
}

// Create with serial connection
JadeAPI::JadeAPI(const QSerialPortInfo& deviceInfo, QObject *parent)
    : JadeAPI(new JadeSerialImpl(deviceInfo, parent), parent) // temporary impl owership
{
    qDebug() << "JadeAPI::JadeAPI(serial)";
}

// Create with BLE connection
JadeAPI::JadeAPI(const QBluetoothDeviceInfo& deviceInfo, QObject *parent)
    : JadeAPI(new JadeBleImpl(deviceInfo, parent), parent) // temporary impl owership
{
    qDebug() << "JadeAPI::JadeAPI(ble)";
}

// Private ctor
JadeAPI::JadeAPI(JadeConnection *connection, QObject *parent)
    : QObject(parent),
      m_idgen(QRandomGenerator::securelySeeded()),
      m_makeHttpRequest(defaultHttpRequestProxy),
      m_responseHandlers(),
      m_jade(connection)
{
    m_jade->setParent(this);  // take impl ownership here

    // Connect the underlying connection's 'new message' signal to our handler
    connect(m_jade, &JadeConnection::onNewMessageReceived,
            this, &JadeAPI::processResponseMessage);

    // Forward connection/disconnection signals from underlying connection
    connect(m_jade, &JadeConnection::onConnected,
            this, &JadeAPI::onConnected);
    connect(m_jade, &JadeConnection::onDisconnected,
            this, &JadeAPI::onDisconnected);
}

JadeAPI::~JadeAPI()
{
    qDebug() << "JadeAPI::~JadeAPI()";

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

// Function to override the basic http-request implementation
void JadeAPI::setHttpRequestProxy(const HttpRequestProxy &httpRequestProxy)
{
    m_makeHttpRequest = httpRequestProxy ? httpRequestProxy : defaultHttpRequestProxy;
}

// Handle result of an http-request.
// MUST be called when an http-request response is received.
void JadeAPI::handleHttpResponse(const int id, const QJsonObject &httpRequest, const QJsonObject &httpResponse)
{
    qDebug() << "JadeAPI::handleHttpResponse() called for" << id << "with response data" << httpResponse;

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
    const QCborMap newRequest = getRequest(newId, on_reply, QCborMap::fromJsonObject(httpResponse));
    sendToJade(newRequest);
}

inline int JadeAPI::getNewId() {
    return m_idgen.bounded(10000,100000);
}

// Register callback for request/response when received
int JadeAPI::registerResponseHandler(const ResponseHandler &cb) {
    Q_ASSERT(cb);

    // Get a new id not currently present in the map
    int id = getNewId();
    for (int i = 0; i < 5 && m_responseHandlers.contains(id); ++i) {
        id = getNewId();
    }

    // Insert the callback keyed by id
    qDebug() << "JadeAPI::registerResponseHandler() - Registering response handler with id" << id;
    m_responseHandlers.insert(id, cb);

    // Return the new callback id
    return id;
}

// Invoke client callback for request/response when received
void JadeAPI::callResponseHandler(const QVariantMap &msg)
{
    // Get the id from the message
    Q_ASSERT(msg["id"].isValid() && msg["id"].toString().toInt() > 0);
    const int id = msg["id"].toString().toInt();

    qDebug() << "JadeAPI::callResponseHandler() called for message id" << id;

    // Get (ie. remove) the response handler for that id from the map of registered handlers
    const ResponseHandler handler = m_responseHandlers.take(id);
    if (!handler)
    {
        qWarning() << "JadeAPI::callResponseHandler() - Message ignored - no handler found for id" << msg;
        return;
    }

    // Call the handler, catching any exceptions
    qDebug() << "JadeAPI::callResponseHandler() - calling/discarding located handler for id" << id;
    try {
        handler(msg);
    } catch(...) {
        qWarning() << "JadeAPI::callResponseHandler() - Error in client handler for" << msg;
    }
}

// Forward the message to the handler indicated by id, copying the map to update the id if necessary
void JadeAPI::forwardToResponseHandler(const int targetId, const QVariantMap &msg)
{
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
    qInfo() << "JadeAPI::processResponseMessage() received <-" << Qt::endl << msg;

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
        Q_ASSERT(m_makeHttpRequest);

        // Handle responses which require the results of an http_request
        Q_ASSERT(msg["result"]["http_request"].isMap());
        const QCborMap httpRequest = msg["result"]["http_request"].toMap();

        // Make http-request.
        // NOTE: when http request returns, JadeAPI::handleHttpResponse() should be called, which
        // should result in another call to Jade, and ultimately this function being called again.
        m_makeHttpRequest(*this, id, httpRequest.toJsonObject());
    }
    else
    {
        // Simple result or error - call registered callback
        callResponseHandler(msg.toVariantMap());
    }
}

void JadeAPI::sendToJade(const QCborMap &msg)
{
    qInfo() << "JadeAPI::sendToJade() - Sending message ->" << Qt::endl << msg;
    Q_ASSERT(m_jade);
    m_jade->send(msg);
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
    sendToJade(request);
    return id;
}
#endif

// Get version information from the jade
int JadeAPI::getVersionInfo(const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap request = getRequest(id, "get_version_info");
    sendToJade(request);
    return id;
}

// Send additional entropy for the rng to jade
int JadeAPI::addEntropy(const QByteArray &entropy, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap params = { {"entropy", entropy} };
    const QCborMap request = getRequest(id, "add_entropy", params);
    sendToJade(request);
    return id;
}

// Trigger user authentication on the hw
// Involves pinserver handshake
int JadeAPI::authUser(const QString &network, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap params = { {"network", network} };
    const QCborMap request = getRequest(id, "auth_user", params);
    sendToJade(request);
    return id;
}

// OTA update the connected Jade
int JadeAPI::otaUpdate(const QByteArray& fwcmp, const int fwlen, const int chunkSize, const ResponseHandler &cbProgress, const ResponseHandler &cb)
{
    // The exposed/returned id that will key the caller's handler (invoked
    // when the OTA completes successfully or errors).
    const int id = registerResponseHandler(cb);

    // Register the recursive callback used to upload ota data chunks
    const int tmpId = registerResponseHandler(makeOtaChunkCallback(id, fwcmp, chunkSize, 0, cbProgress));

    // Initiate OTA process, and return the exposed id
    const int compressedSize = fwcmp.length();
    const QCborMap params = { {"fwsize", fwlen}, {"cmpsize", compressedSize} };
    const QCborMap request = getRequest(tmpId, "ota", params);
    sendToJade(request);
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
                sendToJade(otaData);
            }
            else
            {
                // Upload complete - send final message using exposed id (and hence directing response at callers handler)
                qDebug() << "JadeAPI::makeOtaChunkCallback()::lambda for" << id << "all chunks uploaded - sending ota_complete";
                const QCborMap otaData = getRequest(id, "ota_complete");
                sendToJade(otaData);
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
    sendToJade(request);
    return id;
}

// Get xpub given path
int JadeAPI::getXpub(const QString &network, const QVector<quint32> &path, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap params = { {"network", network}, {"path", convertPath(path)} };
    const QCborMap request = getRequest(id, "get_xpub", params);
    sendToJade(request);
    return id;
}

// Sign a message
int JadeAPI::signMessage(const QVector<quint32> &path, const QString &message, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap params = { {"path", convertPath(path)}, {"message", message} };
    const QCborMap request = getRequest(id, "sign_message", params);
    sendToJade(request);
    return id;
}

// Sign a txn
int JadeAPI::signTx(const QString &network, const QByteArray &txn, const QVariantList &inputs, const QVariantList &change, const ResponseHandler &cb)
{
    // Protocol:
    // 1st message contains txn and number of inputs we are going to send.
    // Reply ok if that corresponds to the expected number of inputs (n).
    // Then we send one message per input - without expecting replies.
    // Once all n input messages are sent, the hw then sends all n replies
    // (as the user has a chance to confirm/cancel at this point).
    // Then receive all n replies for the n signatures.
    // NOTE: *NOT* a sequence of n blocking rpc calls.

    // The exposed/returned id that will key the caller's handler (invoked
    // when the signing process completes successfully or errors).
    const int id = registerResponseHandler(cb);

    // Interim callback to send the tx inputs once the initiating call has succeeded
    const int tmpId = registerResponseHandler(makeSendInputsCallback(id, inputs));

    // Initiate signing process, and return the exposed id
    const QCborMap params = { {"network", network},
                              {"txn", txn},
                              {"num_inputs", inputs.size()},
                              {"change", QCborArray::fromVariantList(change)} };
    const QCborMap request = getRequest(tmpId, "sign_tx", params);
    sendToJade(request);
    return id;
}

// Helper for signTx / signLiquidTx to send all tx inputs
JadeAPI::ResponseHandler JadeAPI::makeSendInputsCallback(const int id, const QVariantList &inputs)
{
    return [this, id, inputs](const QVariantMap &rslt)
    {
        // If all good, send txn inputs
        if (rslt.contains("result") && rslt["result"].toBool())
        {
            // Structure to hold returned signatures
            QSharedPointer<QMap<int, QVariant>> sigs(new QMap<int, QVariant>());

            // Send each input (using a timer)
            int index = 0;
            const int ninputs = inputs.size();
            for (const QVariant& input : inputs)
            {
                qDebug() << "JadeAPI::makeSendInputsCallback()::lambda for" << id << "scheduling tx input" << index+1 << "of" << ninputs;
                QTimer::singleShot(index*100,
                    [this, id, ninputs, input, index, sigs]()
                    {
                        qDebug() << "JadeAPI::makeSendInputsCallback()::lambda for" << id << "sending tx input" << index+1 << "of" << ninputs;
                        const int inputId = registerResponseHandler(makeRecieveSignatureCallback(id, ninputs, index, input, sigs));
                        const QCborMap params = QCborMap::fromVariantMap(input.toMap());
                        const QCborMap request = getRequest(inputId, "tx_input", params);
                        sendToJade(request);
                    }
                );
                ++index;
            }
        }
        else
        {
            // Error - forward error to caller's response handler
            forwardToResponseHandler(id, rslt);
        }
    };
}

// Helper for signTx / signLiquidTx to receive and collect the signatures
JadeAPI::ResponseHandler JadeAPI::makeRecieveSignatureCallback(const int id, const int nInputs, const int index, const QVariant &input, const QSharedPointer<QMap<int, QVariant>> &sigs)
{
    Q_ASSERT(nInputs > 0);
    Q_ASSERT(!sigs.isNull());
    Q_ASSERT(sigs->isEmpty());

    // Helper for signTx / signLiquidTx to collect all signatures
    return [this, id, nInputs, index, input, sigs](const QVariantMap &rslt)
    {
        Q_ASSERT(!sigs.isNull());
        qDebug() << "JadeAPI::makeRecieveSignatureCallback()::lambda for" << id << "received signature" << index+1 << "of" << nInputs;

        // If all good, collect signatures
        if (rslt.contains("result"))
        {
            Q_ASSERT(!sigs->contains(index));
            sigs->insert(index, rslt["result"].toByteArray());

            // If we have all responses, forward them to caller's handler
            if (sigs->size() == nInputs)
            {
                qDebug() << "JadeAPI::makeRecieveSignatureCallback()::lambda for" << id << "received all signatures, forwarding to caller's handler";
                const QVariantMap rslt = { {"id", id}, {"result", sigs->values()} };
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
    sendToJade(request);
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
    sendToJade(request);
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
    sendToJade(request);
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
    sendToJade(request);
    return id;
}

// Sign a liquid tx - based on / shares much with signTx() above.
int JadeAPI::signLiquidTx(const QString &network, const QByteArray &txn, const QVariantList &inputs, const QVariantList &commitments, const QVariantList &change, const ResponseHandler &cb)
{
    // Protocol:
    // 1st message contains txn and number of inputs we are going to send.
    // Reply ok if that corresponds to the expected number of inputs (n).
    // Then we send one message per input - without expecting replies.
    // Once all n input messages are sent, the hw then sends all n replies
    // (as the user has a chance to confirm/cancel at this point).
    // Then receive all n replies for the n signatures.
    // NOTE: *NOT* a sequence of n blocking rpc calls.

    // The exposed/returned id that will key the caller's handler (invoked
    // when the signing process completes successfully or errors).
    const int id = registerResponseHandler(cb);

    // Interim callback to send the tx inputs once the initiating call has succeeded
    const int tmpId = registerResponseHandler(makeSendInputsCallback(id, inputs));

    // Initiate signing process, and return the exposed id
    const QCborMap params = { {"network", network},
                              {"txn", txn},
                              {"num_inputs", inputs.size()},
                              {"trusted_commitments", QCborArray::fromVariantList(commitments)},
                              {"change", QCborArray::fromVariantList(change)} };
    const QCborMap request = getRequest(tmpId, "sign_liquid_tx", params);
    sendToJade(request);
    return id;
}

int JadeAPI::signLiquidTxStart(const QString &network, const QByteArray &txn, int num_inputs, const QVariantList &commitments, const QVariantList &change, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    // Initiate signing process, and return the exposed id
    const QCborMap params = { {"network", network},
                              {"txn", txn},
                              {"num_inputs", num_inputs},
                              {"trusted_commitments", QCborArray::fromVariantList(commitments)},
                              {"change", QCborArray::fromVariantList(change)} };
    const QCborMap request = getRequest(id, "sign_liquid_tx", params);
    sendToJade(request);
    return id;

}

int JadeAPI::signLiquidTxInput(const QVariantMap& input, const ResponseHandler &cb)
{
    const int id = registerResponseHandler(cb);
    const QCborMap params = QCborMap::fromVariantMap(input);
    const QCborMap request = getRequest(id, "tx_input", params);
    sendToJade(request);
    return id;

}
