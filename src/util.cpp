#include "util.h"

#include <QDir>
#include <QStandardPaths>

QString GetDataDir(const QString& context)
{
    const QString path = QStandardPaths::writableLocation(QStandardPaths::DataLocation) + QDir::separator() + context;
    const QDir dir;
    const bool created = dir.mkpath(path);
    Q_ASSERT(created);
    return path;
}

QString GetDataFile(const QString& context, const QString& name)
{
    return GetDataDir(context) + QDir::separator() + name;
}
