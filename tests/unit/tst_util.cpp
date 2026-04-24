#include "util.h"

#include <QObject>
#include <QtTest/QtTest>

class UtilTest : public QObject
{
    Q_OBJECT

private slots:
    void parsePathFromArray();
    void parsePathFromEmptyInputs();
    void parsePathFromJsonValue();
    void parseByteArrayFromHex();
    void parseByteArrayFromEmptyValue();
    void reverseByteArray();
    void reverseEmptyByteArray();
    void sha256String();
};

void UtilTest::parsePathFromArray()
{
    const QJsonArray input{1, 2, QJsonValue(qint64(2147483648ULL))};
    QCOMPARE(ParsePath(input), (QVector<uint32_t>{1, 2, 2147483648u}));
}

void UtilTest::parsePathFromEmptyInputs()
{
    QCOMPARE(ParsePath(QJsonArray{}).size(), 0);
    QCOMPARE(ParsePath(QJsonValue()).size(), 0);
    QCOMPARE(ParsePath(QJsonValue(QStringLiteral("not-an-array"))).size(), 0);
}

void UtilTest::parsePathFromJsonValue()
{
    const QJsonArray input{1, 2, QJsonValue(qint64(2147483648ULL))};
    QCOMPARE(ParsePath(QJsonValue(input)), ParsePath(input));
}

void UtilTest::parseByteArrayFromHex()
{
    const QByteArray result = ParseByteArray(QStringLiteral("0a0bff"));
    QCOMPARE(result.toHex(), QByteArray("0a0bff"));
}

void UtilTest::parseByteArrayFromEmptyValue()
{
    QCOMPARE(ParseByteArray(QJsonValue(QString())), QByteArray());
    QCOMPARE(ParseByteArray(QJsonValue()), QByteArray());
}

void UtilTest::reverseByteArray()
{
    const QByteArray input = QByteArray::fromHex("0011aaff");
    const QByteArray reversed = ReverseByteArray(input);
    QCOMPARE(reversed.toHex(), QByteArray("ffaa1100"));
}

void UtilTest::reverseEmptyByteArray()
{
    QCOMPARE(ReverseByteArray(QByteArray()), QByteArray());
}

void UtilTest::sha256String()
{
    QCOMPARE(
        Sha256(QStringLiteral("abc")),
        QStringLiteral("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"));
}

QTEST_GUILESS_MAIN(UtilTest)
#include "tst_util.moc"
