#ifndef BLOCKSTREAM_LIGHTNING_LNURL_H
#define BLOCKSTREAM_LIGHTNING_LNURL_H

#include <QString>

struct LightningLnurlMetadata {
    QString description;
    QString image;
};

LightningLnurlMetadata ParseLightningLnurlMetadata(const QString& metadata_json);
QString LightningLnurlDomain(const QString& lnurl_or_address, const QString& callback = {});

quint64 LightningLnurlCommentLength(const QString& comment);

// Map LWK/GLSDK LNURL resolution failures to id_invalid_address (Android/iOS parity).
QString LightningLnurlUserFacingError(const QString& error);

#endif // BLOCKSTREAM_LIGHTNING_LNURL_H
