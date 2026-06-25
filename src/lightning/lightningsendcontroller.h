#ifndef BLOCKSTREAM_LIGHTNING_SEND_CONTROLLER_H
#define BLOCKSTREAM_LIGHTNING_SEND_CONTROLLER_H

#include "controller.h"
#include "lightningclient.h"

#include <QJsonObject>
#include <QQmlEngine>
#include <QQmlListProperty>
#include <QString>
#include <QVariant>

#include <optional>

Q_MOC_INCLUDE("account.h")
Q_MOC_INCLUDE("asset.h")

class PaymentSource : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Type type READ type CONSTANT)
    Q_PROPERTY(Account* account READ account CONSTANT)
    Q_PROPERTY(Asset* asset READ asset CONSTANT)
    Q_PROPERTY(qint64 balance READ balance CONSTANT)
    Q_PROPERTY(qint64 maxPayable READ maxPayable CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    enum class Type {
        GdkAccount,
        Lightning,
    };
    Q_ENUM(Type)

    PaymentSource(Type type, Account* account, Asset* asset, qint64 balance, qint64 max_payable, QObject* parent = nullptr);

    Type type() const { return m_type; }
    Account* account() const { return m_account; }
    Asset* asset() const { return m_asset; }
    qint64 balance() const { return m_balance; }
    qint64 maxPayable() const { return m_max_payable; }

private:
    Type const m_type;
    Account* const m_account;
    Asset* const m_asset;
    qint64 const m_balance;
    qint64 const m_max_payable;
};

class LightningSendController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QString invoice READ invoice WRITE setInvoice NOTIFY updated)
    Q_PROPERTY(QString input READ input WRITE setInput NOTIFY updated)
    Q_PROPERTY(bool lightningOnly READ lightningOnly WRITE setLightningOnly NOTIFY updated)
    Q_PROPERTY(QString enteredSatoshi READ enteredSatoshi WRITE setEnteredSatoshi NOTIFY updated)
    Q_PROPERTY(bool amountless READ amountless NOTIFY updated)
    Q_PROPERTY(QVariant invoiceAmount READ invoiceAmount NOTIFY updated)
    Q_PROPERTY(QString error READ error NOTIFY updated)
    Q_PROPERTY(bool canPay READ canPay NOTIFY updated)
    Q_PROPERTY(bool busy READ isBusy NOTIFY updated)
    Q_PROPERTY(QJsonObject payment READ payment NOTIFY updated)
    Q_PROPERTY(QQmlListProperty<PaymentSource> sources READ sources NOTIFY updated)
    Q_PROPERTY(PaymentSource* selectedSource READ selectedSource WRITE setSelectedSource NOTIFY updated)
    QML_ELEMENT
public:
    explicit LightningSendController(QObject* parent = nullptr);
    ~LightningSendController() override;

    QString invoice() const { return m_invoice; }
    void setInvoice(const QString& invoice);

    QString input() const { return m_input; }
    void setInput(const QString& input);

    bool lightningOnly() const { return m_lightning_only; }
    void setLightningOnly(bool lightning_only);

    QString enteredSatoshi() const { return m_entered_satoshi; }
    void setEnteredSatoshi(const QString& entered_satoshi);

    bool amountless() const;
    QVariant invoiceAmount() const;
    QString error() const;
    bool canPay() const;
    bool isBusy() const { return m_busy; }
    QJsonObject payment() const { return m_payment; }

    QQmlListProperty<PaymentSource> sources();
    PaymentSource* selectedSource() const { return m_selected_source; }
    void setSelectedSource(PaymentSource* selected_source);

public slots:
    void pay();
    void refresh();

signals:
    void updated();
    void paid();
    void failed(const QString& error);

private:
    std::optional<quint64> amount() const;
    void clearSources();
    void setBusy(bool busy);
    void setError(const QString& error);
    void update();
    void buildSources();

private:
    QString m_invoice;
    QString m_input;
    QString m_entered_satoshi;
    bool m_lightning_only{false};
    bool m_busy{false};
    QString m_error;
    QJsonObject m_payment;
    QList<PaymentSource*> m_sources;
    PaymentSource* m_selected_source{nullptr};
    std::optional<LightningParsedInvoice> m_parsed_invoice;
};

#endif // BLOCKSTREAM_LIGHTNING_SEND_CONTROLLER_H
