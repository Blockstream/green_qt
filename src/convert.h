#ifndef GREEN_CONVERT_H
#define GREEN_CONVERT_H

#include <QObject>
#include <QtQml>

#include "green.h"

class Convert : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context WRITE setContext NOTIFY contextChanged)
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(Asset* asset READ asset WRITE setAsset NOTIFY assetChanged)
    Q_PROPERTY(bool fiat READ fiat NOTIFY fiatChanged)
    Q_PROPERTY(QString unit READ unit WRITE setUnit NOTIFY unitChanged)
    Q_PROPERTY(QString outputUnit READ outputUnit WRITE setOutputUnit NOTIFY outputUnitChanged)
    Q_PROPERTY(bool user READ user WRITE setUser NOTIFY userChanged)
    Q_PROPERTY(QString value READ value WRITE setValue NOTIFY valueChanged)
    Q_PROPERTY(QJsonObject result READ result NOTIFY resultChanged)
    Q_PROPERTY(QString fiatLabel READ fiatLabel NOTIFY fiatLabelChanged)
    Q_PROPERTY(QString unitLabel READ unitLabel NOTIFY unitLabelChanged)
    Q_PROPERTY(QVariantMap output READ output NOTIFY outputChanged)
    QML_ELEMENT
public:
    Convert(QObject* parent = nullptr);
    Context* context() const { return m_context; }
    void setContext(Context* context);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    Asset* asset() const { return m_asset; }
    void setAsset(Asset* asset);
    bool fiat() const { return m_fiat; }
    void setFiat(bool fiat);
    QString unit() const { return m_unit; }
    void setUnit(const QString& unit);
    QString outputUnit() const { return m_output_unit; }
    void setOutputUnit(const QString& output_unit);
    bool user() const { return m_user; }
    void setUser(bool user);
    QString value() const { return m_value; }
    void setValue(const QString& value);
    void clearValue();
    QJsonObject result() const { return m_result; }
    void setResult(const QJsonObject& result);
    QString fiatLabel() const;
    QString unitLabel() const;
    QVariantMap output() const;
signals:
    void contextChanged();
    void accountChanged();
    void assetChanged();
    void fiatChanged();
    void unitChanged();
    void outputUnitChanged();
    void userChanged();
    void valueChanged();
    void resultChanged();
    void fiatLabelChanged();
    void unitLabelChanged();
    void outputChanged();
private:
    void setSession(Session* session);
    void invalidate();
    void update();
    bool mainnet() const;
    QVariantMap format(const QString& unit) const;
protected:
    void timerEvent(QTimerEvent* event) override;
private:
    Context* m_context{nullptr};
    Account* m_account{nullptr};
    Asset* m_asset{nullptr};
    bool m_liquid_asset{false};
    bool m_fiat{false};
    QString m_unit;
    QString m_output_unit;
    bool m_user{false};
    QString m_value;
    QJsonObject m_result;
    int m_timer_id{-1};
};

#endif // GREEN_CONVERT_H
