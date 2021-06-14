#ifndef GREEN_SEMVER_H
#define GREEN_SEMVER_H

#include <QString>

class SemVer
{
    bool m_null{true};
    int m_major{0};
    int m_minor{0};
    int m_patch{0};
public:
    SemVer() {}
    SemVer(int major, int minor, int patch) : m_null{false}, m_major{major}, m_minor(minor), m_patch(patch) {}
    bool isNull() const { return m_null; }
    SemVer& operator=(const SemVer& other);
    bool operator<(const SemVer& other) const;
    bool operator==(const SemVer& other) const;
    bool operator!=(const SemVer& other) const;
    static SemVer parse(const QString& string);
    QString toString() const;
};

#endif // GREEN_SEMVER_H
