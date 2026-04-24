#include "json.h"

#include <QObject>
#include <QtTest/QtTest>

class JsonTest : public QObject
{
    Q_OBJECT

private slots:
    void objectRoundTrip();
    void arrayFromStringJson();
    void invalidStringReturnsNull();
};

void JsonTest::objectRoundTrip()
{
    const QJsonObject input{
        {QStringLiteral("name"), QStringLiteral("alice")},
        {QStringLiteral("amount"), 42},
        {QStringLiteral("delta"), -7},
        {QStringLiteral("enabled"), true},
        {QStringLiteral("tags"), QJsonArray{QStringLiteral("a"), 1, false, QJsonValue::Null}},
        {QStringLiteral("meta"), QJsonObject{{QStringLiteral("nested"), QStringLiteral("value")}}},
        {QStringLiteral("note"), QJsonValue::Null}
    };

    const auto json = Json::fromObject(input);
    QVERIFY(json);
    const QJsonObject output = Json::toObject(json.get());

    QCOMPARE(output, input);
}

void JsonTest::arrayFromStringJson()
{
    const auto json = Json::stringToJson(QByteArray("[1,2,3]"));
    QVERIFY(json);
    const QJsonArray output = Json::toArray(json.get());

    QCOMPARE(output.size(), 3);
    QCOMPARE(output[0].toInt(), 1);
    QCOMPARE(output[1].toInt(), 2);
    QCOMPARE(output[2].toInt(), 3);
}

void JsonTest::invalidStringReturnsNull()
{
    const QByteArray inputs[] = {
        QByteArray("not-json"),
        QByteArray("{"),
        QByteArray(),
    };
    for (const QByteArray& input : inputs) {
        const auto json = Json::stringToJson(input);
        QVERIFY(!json);
    }
}

QTEST_GUILESS_MAIN(JsonTest)
#include "tst_json.moc"
