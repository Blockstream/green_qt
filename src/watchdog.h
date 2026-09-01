#ifndef GREEN_WATCHDOG_H
#define GREEN_WATCHDOG_H

#include <QProcess>
#include <QString>

// Whether the watchdog should relaunch the UI process after it went away.
bool ShouldRestartUi(QProcess::ExitStatus exit_status, int exit_code);

// Human readable description of how the UI process went away, for the log.
QString DescribeUiExit(QProcess::ExitStatus exit_status, int exit_code);

#endif // GREEN_WATCHDOG_H
