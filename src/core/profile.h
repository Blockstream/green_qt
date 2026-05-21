#ifndef BLOCKSTREAM_CORE_PROFILE_H
#define BLOCKSTREAM_CORE_PROFILE_H

#include <QElapsedTimer>
#include <QLoggingCategory>
#include <QString>

Q_DECLARE_LOGGING_CATEGORY(profile)

class Profile
{
public:
    explicit Profile(const char* name);
    explicit Profile(const QString& name);
    ~Profile();

    Profile(const Profile&) = delete;
    Profile& operator=(const Profile&) = delete;

    qint64 nsecsElapsed() const { return m_timer.nsecsElapsed(); }

private:
    const QString m_name;
    QElapsedTimer m_timer;
};

#define PROFILE_CONCAT_(a, b) a##b
#define PROFILE_CONCAT(a, b) PROFILE_CONCAT_(a, b)
#define PROFILE_SCOPE(name) Profile PROFILE_CONCAT(profile_scope_, __LINE__)(name)
#define PROFILE_FUNCTION() PROFILE_SCOPE(Q_FUNC_INFO)

#endif // BLOCKSTREAM_CORE_PROFILE_H
