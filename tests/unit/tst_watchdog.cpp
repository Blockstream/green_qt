#include <QObject>
#include <QProcess>
#include <QtTest/QtTest>

#include "watchdog.h"

#ifdef Q_OS_UNIX
#include <csignal>
#endif

class WatchdogTest : public QObject
{
    Q_OBJECT

private slots:
    void normalExitIsNotRestarted();
#ifdef Q_OS_UNIX
    void terminatedProcessIsNotRestarted_data();
    void terminatedProcessIsNotRestarted();
    void crashedProcessIsRestarted_data();
    void crashedProcessIsRestarted();
#endif

#ifdef Q_OS_UNIX
private:
    // Starts a process that stays alive until signalled, kills it with signal
    // and returns what QProcess reports once it is gone.
    static void killChild(int signal, QProcess::ExitStatus& exit_status, int& exit_code);
#endif
};

void WatchdogTest::normalExitIsNotRestarted()
{
    // A process that exits on its own is never restarted, whatever its exit code
    QVERIFY(!ShouldRestartUi(QProcess::NormalExit, 0));
    QVERIFY(!ShouldRestartUi(QProcess::NormalExit, 3));
}

#ifdef Q_OS_UNIX

void WatchdogTest::killChild(int signal, QProcess::ExitStatus& exit_status, int& exit_code)
{
    QProcess process;
    // sleep neither exits on its own within the test nor handles any signal
    process.start("/bin/sleep", { "60" });
    QVERIFY(process.waitForStarted(10000));
    QVERIFY(process.processId() > 0);
    QCOMPARE(::kill(process.processId(), signal), 0);
    QVERIFY(process.waitForFinished(10000));
    exit_status = process.exitStatus();
    exit_code = process.exitCode();
}

void WatchdogTest::terminatedProcessIsNotRestarted_data()
{
    QTest::addColumn<int>("signal");
    // macOS Force Quit, and the out of memory killer, use SIGKILL
    QTest::newRow("SIGKILL") << SIGKILL;
    QTest::newRow("SIGTERM") << SIGTERM;
    QTest::newRow("SIGINT") << SIGINT;
    QTest::newRow("SIGHUP") << SIGHUP;
}

void WatchdogTest::terminatedProcessIsNotRestarted()
{
    QFETCH(int, signal);
    QProcess::ExitStatus exit_status = QProcess::NormalExit;
    int exit_code = -1;
    killChild(signal, exit_status, exit_code);
    QCOMPARE(exit_status, QProcess::CrashExit);
    // QProcess reports the terminating signal as the exit code
    QCOMPARE(exit_code, signal);
    QVERIFY(!ShouldRestartUi(exit_status, exit_code));
}

void WatchdogTest::crashedProcessIsRestarted_data()
{
    QTest::addColumn<int>("signal");
    QTest::newRow("SIGSEGV") << SIGSEGV;
    QTest::newRow("SIGABRT") << SIGABRT;
    QTest::newRow("SIGBUS") << SIGBUS;
    QTest::newRow("SIGILL") << SIGILL;
    // Signals that are not crashes as such still leave the UI gone unexpectedly
    QTest::newRow("SIGQUIT") << SIGQUIT;
    QTest::newRow("SIGXCPU") << SIGXCPU;
}

void WatchdogTest::crashedProcessIsRestarted()
{
    QFETCH(int, signal);
    QProcess::ExitStatus exit_status = QProcess::NormalExit;
    int exit_code = -1;
    killChild(signal, exit_status, exit_code);
    QCOMPARE(exit_status, QProcess::CrashExit);
    QCOMPARE(exit_code, signal);
    QVERIFY(ShouldRestartUi(exit_status, exit_code));
}

#endif

QTEST_MAIN(WatchdogTest)
#include "tst_watchdog.moc"
