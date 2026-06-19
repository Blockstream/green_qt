#ifndef BLOCKSTREAM_LIGHTNING_RECEIVE_CONTROLLER_H
#define BLOCKSTREAM_LIGHTNING_RECEIVE_CONTROLLER_H

#include "controller.h"

#include <QDateTime>
#include <QQmlEngine>
#include <QString>
#include <QVariant>

#include <optional>

class LightningReceiveController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QString satoshi READ satoshi WRITE setSatoshi NOTIFY updated)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY updated)
    Q_PROPERTY(QString invoice READ invoice NOTIFY updated)
    Q_PROPERTY(quint64 openingFeeSatoshi READ openingFeeSatoshi NOTIFY updated)
    Q_PROPERTY(QDateTime expiresAt READ expiresAt NOTIFY updated)
    Q_PROPERTY(QVariant minSatoshi READ minSatoshi NOTIFY updated)
    Q_PROPERTY(QVariant recommendedSatoshi READ recommendedSatoshi NOTIFY updated)
    Q_PROPERTY(QVariant maxSatoshi READ maxSatoshi NOTIFY updated)
    Q_PROPERTY(QString validationState READ validationState NOTIFY updated)
    Q_PROPERTY(QString error READ error NOTIFY updated)
    Q_PROPERTY(bool canCreate READ canCreate NOTIFY updated)
    Q_PROPERTY(bool busy READ isBusy NOTIFY updated)
    QML_ELEMENT
public:
    explicit LightningReceiveController(QObject* parent = nullptr);

    QString satoshi() const { return m_satoshi; }
    void setSatoshi(const QString& satoshi);

    QString description() const { return m_description; }
    void setDescription(const QString& description);

    QString invoice() const { return m_invoice; }
    quint64 openingFeeSatoshi() const { return m_opening_fee_satoshi; }
    QDateTime expiresAt() const { return m_expires_at; }
    
    QVariant minSatoshi() const;
    QVariant recommendedSatoshi() const;
    QVariant maxSatoshi() const;

    QString validationState() const;
    QString error() const;
    bool canCreate() const;
    bool isBusy() const { return m_busy; }

public slots:
    void createInvoice();
    void resetInvoice();

signals:
    void updated();

private:
    quint64 amount() const;
    void setBusy(bool busy);
    void setError(const QString& error);
    void updateLimits();

private:
    QString m_satoshi;
    QString m_description;
    bool m_busy{false};
    QString m_error;
    QString m_invoice;
    quint64 m_opening_fee_satoshi{0};
    QDateTime m_expires_at;
    std::optional<quint64> m_min_satoshi;
    std::optional<quint64> m_recommended_satoshi;
    std::optional<quint64> m_max_satoshi;
};

#endif // BLOCKSTREAM_LIGHTNING_RECEIVE_CONTROLLER_H
