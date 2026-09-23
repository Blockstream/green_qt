#include <QEventLoop>
#include <QFile>
#include <QProcess>
#include <QTextStream>

#include "application.h"
#include "util.h"
#include "watchdog.h"

#ifdef _WIN32
#include <io.h>
#else
#include <unistd.h>
#endif

extern QString g_data_location;

int watchdog_handler(Application& app)
{
    QStringList args = app.arguments().mid(1);
    for (int i = 0; i < args.length();) {
        if (args[i] == "--tempdatadir") {
            args.removeAt(i);
        } else if (args[i] == "--datadir") {
            args.removeAt(i);
            args.removeAt(i);
        } else {
            i ++;
        }
    }
    args.append({ "--ui", "--datadir", g_data_location });

    const auto start_ui = [&app](QStringList args, int attempts = 1) {
        for (int i = 0; i < attempts; i++) {
            QFile file(GetLogFilename());
            (void)file.open(QFile::WriteOnly | QFile::Append);
            file.write("---------");
            file.flush();
            QProcess process;
            QEventLoop loop;
            QObject::connect(&process, &QProcess::readyReadStandardOutput, &loop, [&] {
                const auto data = process.readAllStandardOutput();
                write(0, data.constData(), data.size());
                file.write(data);
                file.flush();
            });
            QObject::connect(&process, &QProcess::readyReadStandardError, &loop, [&] {
                const auto data = process.readAllStandardError();
                write(1, data.constData(), data.size());
                file.write(data);
                file.flush();
            });
            QObject::connect(&process, &QProcess::finished, &loop, &QEventLoop::quit);
            process.start(app.arguments().constFirst(), args);
            loop.exec();
            const auto exit_status = process.exitStatus();
            const auto exit_code = process.exitCode();
            QTextStream(&file) << Q_FUNC_INFO << ' ' << DescribeUiExit(exit_status, exit_code) << Qt::endl;
            // only bring the UI back when it crashed, not when it was terminated on purpose
            if (!ShouldRestartUi(exit_status, exit_code)) break;
        }
    };

    QObject::connect(&app, &Application::fileOpenEventReceived, [&](const QString& url) {
        // It will start new UI process which will handle the URL and then exit immediately,
        // so we don't need to worry about killing it
        start_ui(args + QStringList{ url });
    });

    start_ui(args, 5);

    return 0;
}
