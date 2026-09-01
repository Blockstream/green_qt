#include "watchdog.h"

#ifdef Q_OS_UNIX
#include <csignal>
#include <cstring>

namespace {

// On Unix QProcess reports the terminating signal as the exit code when the
// exit status is CrashExit, see QProcessPrivate::waitForDeadChild().
// These signals mean somebody wanted the UI gone: SIGKILL for macOS Force Quit
// and for the out of memory killer, SIGTERM for a shutdown or `kill`, SIGINT
// and SIGHUP from the controlling terminal. Every other signal is treated as a
// crash, so an unexpected termination still gets the UI back.
bool IsIntentionalSignal(int signal)
{
    switch (signal) {
    case SIGHUP:
    case SIGINT:
    case SIGKILL:
    case SIGTERM:
        return true;
    default:
        return false;
    }
}

} // namespace
#endif

bool ShouldRestartUi(QProcess::ExitStatus exit_status, int exit_code)
{
    if (exit_status == QProcess::NormalExit) return false;
#ifdef Q_OS_UNIX
    return !IsIntentionalSignal(exit_code);
#else
    // On Windows the exit code of a crashed process is the exception code, not
    // a signal, and a Force Quit equivalent does not exist, so keep restarting.
    Q_UNUSED(exit_code)
    return true;
#endif
}

QString DescribeUiExit(QProcess::ExitStatus exit_status, int exit_code)
{
    if (exit_status == QProcess::NormalExit) {
        return QString("exited with code %1").arg(exit_code);
    }
#ifdef Q_OS_UNIX
    return QString("terminated by signal %1 (%2)").arg(exit_code).arg(QString::fromLocal8Bit(strsignal(exit_code)));
#else
    return QString("terminated with exit code 0x%1").arg(exit_code, 0, 16);
#endif
}
