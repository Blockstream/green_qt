#include "progress.h"

#include <QObject>
#include <QSignalSpy>
#include <QtTest/QtTest>

class ProgressTest : public QObject
{
    Q_OBJECT

private slots:
    void defaults();
    void setFromEmitsOnlyOnChange();
    void setToEmitsOnlyOnChange();
    void setValueEmitsOnlyOnChange();
    void incrementValueUsesCurrentValue();
    void indeterminateToggle();
};

void ProgressTest::defaults()
{
    Progress progress;
    QCOMPARE(progress.from(), 0.0);
    QCOMPARE(progress.to(), 1.0);
    QCOMPARE(progress.value(), 0.0);
    QCOMPARE(progress.indeterminate(), true);
}

void ProgressTest::setFromEmitsOnlyOnChange()
{
    Progress progress;
    QSignalSpy spy(&progress, &Progress::fromChanged);

    progress.setFrom(0.0);
    QCOMPARE(spy.count(), 0);

    progress.setFrom(2.0);
    progress.setFrom(2.0);
    progress.setFrom(4.5);

    QCOMPARE(spy.count(), 2);
    QCOMPARE(spy.at(0).at(0).toDouble(), 2.0);
    QCOMPARE(spy.at(1).at(0).toDouble(), 4.5);
    QCOMPARE(progress.from(), 4.5);
}

void ProgressTest::setToEmitsOnlyOnChange()
{
    Progress progress;
    QSignalSpy spy(&progress, &Progress::toChanged);

    progress.setTo(1.0);
    QCOMPARE(spy.count(), 0);

    progress.setTo(8.0);
    progress.setTo(8.0);
    progress.setTo(9.5);

    QCOMPARE(spy.count(), 2);
    QCOMPARE(spy.at(0).at(0).toDouble(), 8.0);
    QCOMPARE(spy.at(1).at(0).toDouble(), 9.5);
    QCOMPARE(progress.to(), 9.5);
}

void ProgressTest::setValueEmitsOnlyOnChange()
{
    Progress progress;
    QSignalSpy spy(&progress, &Progress::valueChanged);

    progress.setValue(2.5);
    progress.setValue(2.5);
    progress.setValue(3.0);

    QCOMPARE(spy.count(), 2);
    QCOMPARE(spy.at(0).at(0).toDouble(), 2.5);
    QCOMPARE(spy.at(1).at(0).toDouble(), 3.0);
    QCOMPARE(progress.value(), 3.0);
}

void ProgressTest::incrementValueUsesCurrentValue()
{
    Progress progress;
    progress.setValue(10);
    progress.incrementValue(2);
    progress.incrementValue();
    QCOMPARE(progress.value(), 13.0);
}

void ProgressTest::indeterminateToggle()
{
    Progress progress;
    QSignalSpy spy(&progress, &Progress::indeterminateChanged);

    progress.setIndeterminate(false);
    progress.setIndeterminate(false);
    progress.setIndeterminate(true);

    QCOMPARE(spy.count(), 2);
    QCOMPARE(spy.at(0).at(0).toBool(), false);
    QCOMPARE(spy.at(1).at(0).toBool(), true);
    QCOMPARE(progress.indeterminate(), true);
}

QTEST_GUILESS_MAIN(ProgressTest)
#include "tst_progress.moc"
