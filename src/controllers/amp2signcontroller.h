#ifndef GREEN_AMP2SIGNCONTROLLER_H
#define GREEN_AMP2SIGNCONTROLLER_H

#include "controller.h"
#include "green.h"

class Account;

// Signs, cosigns and broadcasts an AMP2 spend PSET produced by CreatePsetController.
// The lwk flow (user sign -> AMP2 server cosign -> wollet finalize -> broadcast)
// runs on a worker thread. Requires a software signer (mnemonic) and a registered
// AMP2 client on the Context.
class Amp2SignController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(QString pset READ pset WRITE setPset NOTIFY psetChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    QML_ELEMENT
public:
    Amp2SignController(QObject* parent = nullptr);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    QString pset() const { return m_pset; }
    void setPset(const QString& pset);
    bool busy() const { return m_busy; }
    QString error() const { return m_error; }
public slots:
    void sign();
signals:
    void accountChanged();
    void psetChanged();
    void busyChanged();
    void errorChanged();
    void completed(const QString& txhash);
    void failed(const QString& error);
private:
    void setBusy(bool busy);
    Account* m_account{nullptr};
    QString m_pset;
    bool m_busy{false};
    QString m_error;
};

#endif // GREEN_AMP2SIGNCONTROLLER_H
