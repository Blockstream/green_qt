#ifndef GREEN_CREATEPSETCONTROLLER_H
#define GREEN_CREATEPSETCONTROLLER_H

#include "controller.h"
#include "green.h"
#include "recipient.h"

Q_MOC_INCLUDE("asset.h")

class Account;

// Builds an AMP2 spend PSET via lwk. AMP2 accounts have no gdk session, so the
// normal CreateTransactionController path can't be used; this runs the lwk
// wollet sync + TxBuilder flow on a worker thread. The resulting PSET is handed
// to Amp2SignController to sign, cosign and broadcast.
//
// Rebuilds itself whenever an input changes, via the same debounced
// invalidate()/timerEvent pattern as CreateTransactionController. Building only
// reads the wollet, which LwkAmp2AccountController keeps synced.
class CreatePsetController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(Asset* asset READ asset WRITE setAsset NOTIFY assetChanged)
    Q_PROPERTY(Recipient* recipient READ recipient CONSTANT)
    Q_PROPERTY(QJsonObject transaction READ transaction NOTIFY transactionChanged)
    Q_PROPERTY(QString pset READ pset NOTIFY transactionChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    QML_ELEMENT
public:
    CreatePsetController(QObject* parent = nullptr);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    Asset* asset() const { return m_asset; }
    void setAsset(Asset* asset);
    Recipient* recipient() const { return m_recipient; }
    QJsonObject transaction() const { return m_transaction; }
    QString pset() const { return m_pset; }
    bool busy() const { return m_busy; }
    QString error() const { return m_error; }
public slots:
    void invalidate();
    void create();
signals:
    void accountChanged();
    void assetChanged();
    void transactionChanged();
    void busyChanged();
    void errorChanged();
    void failed(const QString& error);
protected:
    void timerEvent(QTimerEvent* event) override;
private:
    void setBusy(bool busy);
    // Not setError(): that name would hide Controller's keyed setError().
    void setErrorMessage(const QString& error);
    void clearTransaction();
    int m_update_timer{-1};
    quint64 m_seq{0};
    Account* m_account{nullptr};
    Asset* m_asset{nullptr};
    Recipient* const m_recipient;
    QJsonObject m_transaction;
    QString m_pset;
    bool m_busy{false};
    QString m_error;
};

#endif // GREEN_CREATEPSETCONTROLLER_H
