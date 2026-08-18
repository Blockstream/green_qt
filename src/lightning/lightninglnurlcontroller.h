#ifndef BLOCKSTREAM_LIGHTNING_LNURL_CONTROLLER_H
#define BLOCKSTREAM_LIGHTNING_LNURL_CONTROLLER_H

#include "controller.h"
#include "lightningclient.h"

#include <QQmlEngine>
#include <QString>
#include <QVariant>
#include <QVariantMap>

#include <optional>

class LightningLnurlController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QString input READ input WRITE setInput NOTIFY updated)
    Q_PROPERTY(QVariantMap request READ request NOTIFY updated)
    Q_PROPERTY(QString enteredSatoshi READ enteredSatoshi WRITE setEnteredSatoshi NOTIFY updated)
    Q_PROPERTY(QString comment READ comment WRITE setComment NOTIFY updated)
    Q_PROPERTY(QVariantMap amountError READ amountError NOTIFY updated)
    Q_PROPERTY(QString commentError READ commentError NOTIFY updated)
    Q_PROPERTY(QString error READ error NOTIFY updated)
    Q_PROPERTY(bool canContinue READ canContinue NOTIFY updated)
    Q_PROPERTY(bool canPay READ canPay NOTIFY updated)
    Q_PROPERTY(bool busy READ isBusy NOTIFY updated)
    Q_PROPERTY(QVariantMap successAction READ successAction NOTIFY updated)
    QML_ELEMENT
public:
    explicit LightningLnurlController(QObject* parent = nullptr);

    QString input() const { return m_input; }
    void setInput(const QString& input);

    QVariantMap request() const;
    QString enteredSatoshi() const { return m_entered_satoshi; }
    void setEnteredSatoshi(const QString& entered_satoshi);

    QString comment() const { return m_comment; }
    void setComment(const QString& comment);

    QVariantMap amountError() const;
    QString commentError() const;
    QString error() const { return m_error; }
    bool canContinue() const;
    bool canPay() const;
    bool isBusy() const { return m_busy; }
    QVariantMap successAction() const { return m_success_action; }

    Q_INVOKABLE QString mapError(const QString& error) const;

public slots:
    void resolve();
    void pay();

signals:
    void updated();
    void paid();
    void failed(const QString& error);

private:
    quint64 amount() const;
    quint64 channelBalance() const;
    quint64 maxPayable() const;
    void clearRequest();
    void clearPayment();
    void setBusy(bool busy);
    void setError(const QString& error);

private:
    QString m_input;
    QString m_entered_satoshi;
    QString m_comment;
    QString m_error;
    QVariantMap m_success_action;
    bool m_busy{false};
    quint64 m_pay_id{0};
    quint64 m_resolve_id{0};
    std::optional<LightningLnurlPayRequest> m_request;
};

#endif // BLOCKSTREAM_LIGHTNING_LNURL_CONTROLLER_H
