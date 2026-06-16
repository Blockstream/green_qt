#ifndef GREEN_CONVERT_H
#define GREEN_CONVERT_H

#include <QObject>
#include <QtQml>

#include "green.h"

class ConvertPrivate;

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
    Q_PROPERTY(bool isLiquidAsset READ isLiquidAsset NOTIFY isLiquidAssetChanged)
    Q_DECLARE_PRIVATE(Convert)
    QML_ELEMENT
public:
    Convert(QObject* parent = nullptr);
    ~Convert();
    Context* context() const;
    void setContext(Context* context);
    Account* account() const;
    void setAccount(Account* account);
    Asset* asset() const;
    void setAsset(Asset* asset);
    QVariantMap input() const;
    void setInput(const QVariantMap& input);
    void clearInput();
    QString unit() const;
    void setUnit(const QString& unit);
    Q_INVOKABLE void changeUnit(const QString& unit);
    QJsonObject result() const;
    void setResult(const QJsonObject& result);
    QVariantMap fiat() const;
    QVariantMap output() const;
    bool debug() const;
    void setDebug(bool debug);

    QString satoshi() const;
    bool isLiquidAsset() const;

    Q_INVOKABLE QVariantMap format(const QString& unit) const;
    Q_INVOKABLE QVariantMap formatFiat(double additional_value = 0.0) const;

private:
    Session* assetSession() const;
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
    void isLiquidAssetChanged();
private:
    void connectToSessionSignals();
    void invalidate();
    void update();
    bool mainnet() const;
protected:
    void timerEvent(QTimerEvent* event) override;
private:
    ConvertPrivate* const d_ptr;
};

#endif // GREEN_CONVERT_H
