#ifndef GREEN_CHARTPRICESERVICE_H
#define GREEN_CHARTPRICESERVICE_H

#include <QtQml>

#include <QNetworkReply>
#include <QObject>
#include <QVariant>

class ChartPriceService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currency READ currency WRITE setCurrency NOTIFY currencyChanged)
    Q_PROPERTY(QVariantList pricesDay READ pricesDay NOTIFY pricesChanged)
    Q_PROPERTY(QVariantList pricesMonth READ pricesMonth NOTIFY pricesChanged)
    Q_PROPERTY(QVariantList pricesFull READ pricesFull NOTIFY pricesChanged)
    Q_PROPERTY(QVariantList pricesWeek READ pricesWeek NOTIFY pricesChanged)
    Q_PROPERTY(QVariantList pricesYear READ pricesYear NOTIFY pricesChanged)
    Q_PROPERTY(QVariantList pricesFiveYears READ pricesFiveYears NOTIFY pricesChanged)
    QML_ELEMENT
public:
    explicit ChartPriceService(QObject* parent = nullptr);

    QString currency() const { return m_currency; }
    void setCurrency(const QString& c);

    QVariantList pricesDay() const { return m_prices_day; }
    QVariantList pricesMonth() const { return m_prices_month; }
    QVariantList pricesFull() const { return m_prices_full; }
    QVariantList pricesWeek() const { return m_prices_week; }
    QVariantList pricesYear() const { return m_prices_year; }
    QVariantList pricesFiveYears() const { return m_prices_five_years; }

    Q_INVOKABLE void refresh();

signals:
    void currencyChanged();
    void pricesChanged();

private slots:
    void onReplyFinished();

private:
    QString endpoint() const;
    QString m_currency { QStringLiteral("usd") };
    QVariantList m_prices_day;
    QVariantList m_prices_month;
    QVariantList m_prices_full;
    QVariantList m_prices_week;
    QVariantList m_prices_year;
    QVariantList m_prices_five_years;
};

#endif // GREEN_CHARTPRICESERVICE_H


