#include "profile.h"

Q_LOGGING_CATEGORY(profile, "profile")

namespace {
thread_local int g_depth = 0;
} // namespace

Profile::Profile(const char* name)
    : Profile(QString::fromUtf8(name))
{
}

Profile::Profile(const QString& name)
    : m_name(name)
{
    ++g_depth;
    m_timer.start();
}

Profile::~Profile()
{
    const qint64 nsecs = m_timer.nsecsElapsed();
    --g_depth;
    qCDebug(profile).noquote()
        << QString(g_depth * 2, QLatin1Char(' ')) + m_name
        << "took" << QString::number(nsecs / 1e6, 'f', 3) << "ms";
}
