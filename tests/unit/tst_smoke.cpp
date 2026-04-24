#include <QObject>
#include <QString>
#include <QtTest/QtTest>

class SmokeTest : public QObject
{
    Q_OBJECT

private slots:
    void basicSanity();
    void stringComparison();
};

void SmokeTest::basicSanity()
{
    QVERIFY(true);
}

void SmokeTest::stringComparison()
{
    const QString value = QStringLiteral("blockstream");
    QCOMPARE(value.toUpper(), QStringLiteral("BLOCKSTREAM"));
}

QTEST_MAIN(SmokeTest)
#include "tst_smoke.moc"
