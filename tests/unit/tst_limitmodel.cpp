#include "limitmodel.h"

#include <QObject>
#include <QSignalSpy>
#include <QStringListModel>
#include <QtTest/QtTest>

class LimitModelTest : public QObject
{
    Q_OBJECT

private slots:
    void changingPositiveLimitToNegativeHidesAllRows();
    void settingLimitExposesLeadingRowsInOrder_data();
    void settingLimitExposesLeadingRowsInOrder();
    void settingSourceAndLimitEmitsOnlyWhenValueChanges();
};

void LimitModelTest::changingPositiveLimitToNegativeHidesAllRows()
{
    QStringListModel source({QStringLiteral("alpha"), QStringLiteral("bravo"), QStringLiteral("charlie")});

    LimitModel model;
    model.setSource(&source);
    model.setLimit(3);
    QCOMPARE(model.rowCount(), 3);
    QCOMPARE(model.index(0, 0).data().toString(), QStringLiteral("alpha"));
    QCOMPARE(model.index(2, 0).data().toString(), QStringLiteral("charlie"));

    QSignalSpy limitSpy(&model, &LimitModel::limitChanged);
    model.setLimit(-1);

    QCOMPARE(model.rowCount(), 0);
    QCOMPARE(model.limit(), -1);
    QCOMPARE(limitSpy.count(), 1);
}

void LimitModelTest::settingLimitExposesLeadingRowsInOrder_data()
{
    QTest::addColumn<int>("limit");
    QTest::addColumn<QStringList>("expected");

    const QStringList all{
        QStringLiteral("alpha"),
        QStringLiteral("bravo"),
        QStringLiteral("charlie"),
        QStringLiteral("delta"),
        QStringLiteral("echo")
    };
    QTest::newRow("zero") << 0 << QStringList{};
    QTest::newRow("partial") << 2 << all.mid(0, 2);
    QTest::newRow("all") << 5 << all;
    QTest::newRow("above row count") << 9 << all;
}

void LimitModelTest::settingLimitExposesLeadingRowsInOrder()
{
    QFETCH(int, limit);
    QFETCH(QStringList, expected);

    QStringListModel source({
        QStringLiteral("alpha"),
        QStringLiteral("bravo"),
        QStringLiteral("charlie"),
        QStringLiteral("delta"),
        QStringLiteral("echo")
    });

    LimitModel model;
    model.setSource(&source);
    model.setLimit(limit);

    QCOMPARE(model.rowCount(), expected.size());
    QStringList actual;
    for (int row = 0; row < model.rowCount(); ++row) {
        actual.append(model.index(row, 0).data(Qt::DisplayRole).toString());
    }
    QCOMPARE(actual, expected);
}

void LimitModelTest::settingSourceAndLimitEmitsOnlyWhenValueChanges()
{
    QStringListModel source({QStringLiteral("alpha")});

    LimitModel model;
    QSignalSpy sourceSpy(&model, &LimitModel::sourceChanged);
    QSignalSpy limitSpy(&model, &LimitModel::limitChanged);

    model.setSource(&source);
    model.setSource(&source);
    model.setLimit(1);
    model.setLimit(1);
    model.setLimit(2);

    QCOMPARE(sourceSpy.count(), 1);
    QCOMPARE(limitSpy.count(), 2);
    QCOMPARE(model.source(), &source);
    QCOMPARE(model.limit(), 2);
}

QTEST_GUILESS_MAIN(LimitModelTest)
#include "tst_limitmodel.moc"
