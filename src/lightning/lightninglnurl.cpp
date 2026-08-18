#include "lightninglnurl.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QUrl>

LightningLnurlMetadata ParseLightningLnurlMetadata(const QString& metadata_json)
{
    LightningLnurlMetadata result;
    const auto document = QJsonDocument::fromJson(metadata_json.toUtf8());
    if (!document.isArray()) return result;

    const auto entries = document.array();
    for (const auto& entry : entries) {
        const auto pair = entry.toArray();
        if (pair.size() < 2) continue;

        const auto type = pair.at(0).toString();
        const auto value = pair.at(1).toString();
        if (type == QLatin1String("text/plain") && result.description.isEmpty()) {
            result.description = value;
            continue;
        }

        if (result.image.isEmpty() && (type.startsWith(QLatin1String("image/png")) || type.startsWith(QLatin1String("image/jpeg")))) {
            const auto separator = type.indexOf(QLatin1Char(';'));
            const auto mime = separator >= 0 ? type.left(separator) : type;
            if (!value.isEmpty()) {
                result.image = QStringLiteral("data:%1;base64,%2").arg(mime, value);
            }
        }
    }

    return result;
}

QString LightningLnurlDomain(const QString& lnurl_or_address, const QString& callback)
{
    const auto trimmed = lnurl_or_address.trimmed();
    const auto at = trimmed.lastIndexOf(QLatin1Char('@'));
    if (at >= 0 && at + 1 < trimmed.size()) {
        auto host = trimmed.mid(at + 1);
        const auto slash = host.indexOf(QLatin1Char('/'));
        if (slash >= 0) host = host.left(slash);
        const auto query = host.indexOf(QLatin1Char('?'));
        if (query >= 0) host = host.left(query);
        if (!host.isEmpty()) return host.toLower();
    }

    const auto url = QUrl(callback);
    if (url.isValid()) return url.host().toLower();
    return {};
}

quint64 LightningLnurlCommentLength(const QString& comment)
{
    return static_cast<quint64>(comment.size());
}

QString LightningLnurlUserFacingError(const QString& error)
{
    const auto trimmed = error.trimmed();
    if (trimmed.isEmpty()) return trimmed;
    if (trimmed.startsWith(QLatin1String("id_"))) return trimmed;

    const auto lower = trimmed.toLower();
    if (lower.contains(QLatin1String("error sending request for url"))
        || lower.contains(QLatin1String("reqwest error"))
        || lower.contains(QLatin1String("status client error"))
        || lower.contains(QLatin1String("status server error"))) {
        return QStringLiteral("id_invalid_address");
    }

    return trimmed;
}
