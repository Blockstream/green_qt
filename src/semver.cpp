#include "semver.h"

#include <QRegularExpression>
#include <QStringList>

#include <string>

SemVer& SemVer::operator=(const SemVer& other)
{
    m_null = other.m_null;
    m_major = other.m_major;
    m_minor = other.m_minor;
    m_patch = other.m_patch;
    return *this;
}

bool SemVer::operator<(const SemVer &v) const
{
    if (m_major < v.m_major) return true;
    if (m_major > v.m_major) return false;
    if (m_minor < v.m_minor) return true;
    if (m_minor > v.m_minor) return false;
    return m_patch < v.m_patch;
}

bool SemVer::operator==(const SemVer &v) const
{
    return m_major == v.m_major && m_minor == v.m_minor && m_patch == v.m_patch;
}

bool SemVer::operator!=(const SemVer &v) const
{
    return m_major != v.m_major || m_minor != v.m_minor || m_patch != v.m_patch;
}

SemVer SemVer::parse(const QString& string)
{
    QRegularExpression re("^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:(?:\\.|-)((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$");
    auto match = re.match(string);
    if (!match.hasMatch()) return {};
    auto parts = match.capturedTexts();
    if (parts.size() < 4) return {};
    bool ok;
    int major = parts[1].toInt(&ok); if (!ok) return {};
    int minor = parts[2].toInt(&ok); if (!ok) return {};
    int patch = parts[3].toInt(&ok); if (!ok) return {};
    return {major, minor, patch};
}

QString SemVer::toString() const
{
    return QString("%1.%2.%3").arg(m_major).arg(m_minor).arg(m_patch);
}
