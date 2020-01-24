#ifndef GREEN_ASSET_H
#define GREEN_ASSET_H

#include <QJsonObject>
#include <QObject>
#include <QString>

class Wallet;

class Asset : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet CONSTANT)
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString icon READ icon NOTIFY iconChanged)
    Q_PROPERTY(QString name READ name NOTIFY dataChanged)
    Q_PROPERTY(bool hasData READ hasData NOTIFY dataChanged)
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)

public:
    explicit Asset(const QString& id, Wallet* wallet);

    Wallet* wallet() const { return m_wallet; }
    QString id() const { return m_id; }

    QString icon() const { return m_icon; }
    void setIcon(const QString& icon);

    QString name() const;

    bool hasData() const { return !m_data.isEmpty(); }
    QJsonObject data() const { return m_data; }
    void setData(const QJsonObject& data);

    qint64 parseAmount(const QString& amount) const;
    QString formatAmount(qint64 amount) const;

signals:
    void iconChanged();
    void dataChanged();

private:
    Wallet* const m_wallet;
    QString const m_id;
    QString m_icon;
    QJsonObject m_data;
};

#endif // GREEN_ASSET_H
