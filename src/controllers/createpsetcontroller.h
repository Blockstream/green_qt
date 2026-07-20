#ifndef GREEN_CREATEPSETCONTROLLER_H
#define GREEN_CREATEPSETCONTROLLER_H

#include "controller.h"
#include "green.h"

class Account;

// Builds an AMP2 spend PSET via lwk. AMP2 accounts have no gdk session, so the
// normal CreateTransactionController path can't be used; this runs the lwk
// wollet sync + TxBuilder flow on a worker thread. The resulting PSET is handed
// to Amp2SignController to sign, cosign and broadcast.
class CreatePsetController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY addressChanged)
    Q_PROPERTY(QString amount READ amount WRITE setAmount NOTIFY amountChanged)
    Q_PROPERTY(QString assetId READ assetId WRITE setAssetId NOTIFY assetIdChanged)
    Q_PROPERTY(QJsonObject transaction READ transaction NOTIFY transactionChanged)
    Q_PROPERTY(QString pset READ pset NOTIFY transactionChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    QML_ELEMENT
public:
    CreatePsetController(QObject* parent = nullptr);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    QString address() const { return m_address; }
    void setAddress(const QString& address);
    QString amount() const { return m_amount; }
    void setAmount(const QString& amount);
    QString assetId() const { return m_asset_id; }
    void setAssetId(const QString& asset_id);
    QJsonObject transaction() const { return m_transaction; }
    QString pset() const { return m_pset; }
    bool busy() const { return m_busy; }
    QString error() const { return m_error; }
public slots:
    void create();
signals:
    void accountChanged();
    void addressChanged();
    void amountChanged();
    void assetIdChanged();
    void transactionChanged();
    void busyChanged();
    void errorChanged();
    void created();
    void failed(const QString& error);
private:
    void setBusy(bool busy);
    Account* m_account{nullptr};
    QString m_address;
    QString m_amount;
    QString m_asset_id;
    QJsonObject m_transaction;
    QString m_pset;
    bool m_busy{false};
    QString m_error;
};

#endif // GREEN_CREATEPSETCONTROLLER_H
