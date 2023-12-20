#ifndef GREEN_CONVERT_H
#define GREEN_CONVERT_H

#include <QObject>
#include <QtQml>

#include "green.h"

class Convert : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(Asset* asset READ asset WRITE setAsset NOTIFY assetChanged)
    Q_PROPERTY(bool fiat READ fiat NOTIFY fiatChanged)
    Q_PROPERTY(QString unit READ unit WRITE setUnit NOTIFY unitChanged)
    Q_PROPERTY(QString value READ value WRITE setValue NOTIFY valueChanged)
    Q_PROPERTY(QJsonObject result READ result NOTIFY resultChanged)
    QML_ELEMENT
public:
    Convert(QObject* parent = nullptr);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    Asset* asset() const { return m_asset; }
    void setAsset(Asset* asset);
    bool fiat() const { return m_fiat; }
    void setFiat(bool fiat);
    QString unit() const { return m_unit; }
    void setUnit(const QString& unit);
    QString value() const { return m_value; }
    void setValue(const QString& value);
    void clearValue();
    QJsonObject result() const { return m_result; }
    void setResult(const QJsonObject& result);
signals:
    void accountChanged();
    void assetChanged();
    void fiatChanged();
    void unitChanged();
    void valueChanged();
    void resultChanged();
private:
    void invalidate();
    void update();
protected:
    void timerEvent(QTimerEvent* event) override;
private:
    Account* m_account{nullptr};
    Asset* m_asset{nullptr};
    bool m_fiat{false};
    QString m_unit;
    QString m_value;
    QJsonObject m_result;
    int m_timer_id{-1};
};

#endif // GREEN_CONVERT_H
