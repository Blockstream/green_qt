#ifndef JADEAPI_H
#define JADEAPI_H

#include <QObject>
#include <QRandomGenerator>
#include <QMap>

#include "jadeconnection.h"

QT_FORWARD_DECLARE_CLASS(QSerialPortInfo);
QT_FORWARD_DECLARE_CLASS(QBluetoothDeviceInfo);

class JadeAPI : public QObject
{
    Q_OBJECT
public:
    typedef std::function<void(const QVariantMap &)> ResponseHandler;
    typedef std::function<void(JadeAPI&, int, const QJsonObject &)> HttpRequestProxy;

    // Useful for sending null values in tx-signing calls
    static QVariant NULL_CHANGE_ENTRY;
    static QVariantMap NULL_COMMITMENT_ENTRY;

    // Create JadeAPI on a serial connection
    explicit JadeAPI(const QSerialPortInfo& deviceInfo,
                     QObject *parent = nullptr);

    // Create JadeAPI on a ble connection
    explicit JadeAPI(const QBluetoothDeviceInfo& deviceInfo,
                     QObject *parent = nullptr);
    ~JadeAPI();

    // Manage underlying connection
    bool isConnected();
    void connectDevice();
    void disconnectDevice();

    // User can override the basic http-request implementation if desired.
    // NOTE: the funciton MUST ensure JadeAPI::handleHttpResponse() is called
    // when the http-request response is received, passing the originating id
    // and request object, as well as the response body received.
    // Call this with a nullptr to set back to the default proxy function.
    void setHttpRequestProxy(const HttpRequestProxy& makeHttpRequest);

    // Function which must be called whenever an http-request response is received.
    // (If caller sets their own HttpRequestProxy, it should call this when the response is received.)
    void handleHttpResponse(const int id, const QJsonObject &httpRequest, const QJsonObject &httpResponse);

    /*
     *  The API calls
     */

#ifndef QT_NO_DEBUG
    // Set debug mnemonic
    int setMnemonic(const QString& mnemonic, const ResponseHandler &cb);
#endif

    // Get version information from the Jade
    int getVersionInfo(const ResponseHandler &cb);

    // Send additional entropy for the rng to Jade
    int addEntropy(const QByteArray &entropy, const ResponseHandler &cb);

    // Trigger user authentication on the hw
    // Involves pinserver handshake
    int authUser(const QString &network, const ResponseHandler &cb);

    // OTA update the connected Jade
    // The passed ResponseHandler will be called multiple times during the update process
    int otaUpdate(const QByteArray& fwcmp, const int fwlen, const int chunksize, const ResponseHandler &cbProgress, const ResponseHandler &cb);

    // Get (receive) green address
    int getReceiveAddress(const QString &network, quint32 subaccount, quint32 branch, quint32 pointer,
                          const QString &recoveryxpub, quint32 csvBlocks, const ResponseHandler &cb);

    // Get xpub given path
    int getXpub(const QString &network, const QVector<quint32> &path, const ResponseHandler &cb);

    // Sign a message
    int signMessage(const QVector<quint32> &path, const QString &message, const QByteArray& ae_host_commitment, const QByteArray& ae_host_entropy, const ResponseHandler &cb);

    // Sign a txn
    int signTx(const QString &network, const QByteArray &txn, const QVariantList &inputs, const QVariantList &change, const ResponseHandler &cb);

    // Get a Liquid public blinding key for a given script
    int getBlindingKey(const QByteArray &script, const ResponseHandler &cb);

    // Get the shared secret to unblind a tx, given the receiving script on
    // our side and the pubkey of the sender (sometimes called "nonce" in Liquid)
    // Get a Liquid public blinding key for a given script
    int getSharedNonce(const QByteArray &script, const QByteArray &their_pubkey, const ResponseHandler &cb);

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
    int getBlindingFactor(const QByteArray &hashPrevouts, const quint32 outputIndex, const QString& type, const ResponseHandler &cb);

    // Generate the blinding factors and commitments for a given output.
    // Can optionally get a "custom" VBF, normally used for the last
    // input where the VBF is not random, but generated accordingly to
    // all the others.
    // `hashPrevouts` and `outputIndex` have the same meaning as in
    //   the `getBlindingFactor()` call.
    // NOTE: the `assetId` should be passed as it is normally displayed, so
    // reversed compared to the "consensus" representation.
    int getCommitments(const QByteArray& assetId, const qint64 value, const QByteArray &hashPrevouts, const quint32 outputIndex, const QByteArray& vbf, const ResponseHandler &cb);

    // Sign a liquid txn
    int signLiquidTx(const QString &network, const QByteArray &txn, const QVariantList &inputs, const QVariantList &commitments, const QVariantList &change, const ResponseHandler &cb);

    // Get master [un-]blinding key for wallet
    int getMasterBlindingKey(const ResponseHandler &cb);
signals:
    void onOpenError();
    void onConnected();
    void onDisconnected();

private slots:
    // Invoked when a new message is recevied on the connection
    void processResponseMessage(const QCborMap &msg);

private:
    // Private ctor
    JadeAPI(JadeConnection* connection, QObject *parent);

    // Helper to get a new random id
    int getNewId();

    // Client call response handlers for async response
    int registerResponseHandler(const ResponseHandler &cb);
    void callResponseHandler(const QVariantMap &msg);
    void forwardToResponseHandler(const int targetId, const QVariantMap &msg);

    // Helper for OTA (per-)chunk upload
    ResponseHandler makeOtaChunkCallback(const int id, const QByteArray &fwcmp, const int chunkSize, const int currentPos, const ResponseHandler &cbProgress);

    // Helpers for signTx / signLiquidTx to send all tx inputs
    ResponseHandler makeSendInputsCallback(const int id, const QVariantList &inputs);
    ResponseHandler makeReceiveCommitmentCallback(const int id, const int index, const QVariant &input, const QSharedPointer<QMap<int, QVariant>> &commitments);
    ResponseHandler makeReceiveSignatureCallback(const int id, const int nInputs, const int index, const QVariant &input, const QSharedPointer<QMap<int, QVariant>> &sigs, const QSharedPointer<QMap<int, QVariant>> &commitments);

    // Send cbor message to Jade
    void sendToJade(const QCborMap &msg);

    // id generator for Jade messages
    QRandomGenerator            m_idgen;

    // Function to use to make http requests.
    // Must call handleHttpResponse() when response received.
    HttpRequestProxy            m_makeHttpRequest;

    // Map of registered response handlers awaiting response
    QMap<int, ResponseHandler>  m_responseHandlers;

    // Underlying connection - lifetime managed by QObject hierarchy
    JadeConnection              *m_jade;
};

#endif // JADEAPI_H
