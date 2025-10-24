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
    Q_PROPERTY(QJsonObject result READ result NOTIFY resultChanged)
    Q_PROPERTY(QVariantMap input READ input WRITE setInput NOTIFY inputChanged)
    Q_PROPERTY(QVariantMap fiat READ fiat NOTIFY fiatChanged)
    Q_PROPERTY(QVariantMap output READ output NOTIFY outputChanged)
    Q_PROPERTY(QString unit READ unit WRITE setUnit NOTIFY unitChanged)
    Q_PROPERTY(bool debug READ debug WRITE setDebug NOTIFY debugChanged)
    QML_ELEMENT
public:
    Convert(QObject* parent = nullptr);
    Context* context() const { return m_context; }
    void setContext(Context* context);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    Asset* asset() const { return m_asset; }
    void setAsset(Asset* asset);
    QVariantMap input() const { return m_input; }
    void setInput(const QVariantMap& input);
    void clearInput();
    QString unit() const { return m_unit; }
    void setUnit(const QString& unit);
    QJsonObject result() const { return m_result; }
    void setResult(const QJsonObject& result);
    QVariantMap fiat() const;
    QVariantMap output() const;
    bool debug() const { return m_debug; }
    void setDebug(bool debug);

    QString satoshi() const;

    Q_INVOKABLE QVariantMap format(const QString& unit) const;

private:
    bool isLiquidAsset() const;
signals:
    void contextChanged();
    void accountChanged();
    void assetChanged();
    void unitChanged();
    void resultChanged();
    void fiatChanged();
    void inputChanged();
    void inputCleared();
    void outputChanged();
    void debugChanged();
private:
    void setSession(Session* session);
    void invalidate();
    void update();
    bool mainnet() const;
protected:
    void timerEvent(QTimerEvent* event) override;
private:
    Context* m_context{nullptr};
    Account* m_account{nullptr};
    Asset* m_asset{nullptr};
    QString m_unit;
    QVariantMap m_input;
    QJsonObject m_result;
    int m_timer_id{-1};
    bool m_debug{false};
};

#endif // GREEN_CONVERT_H
