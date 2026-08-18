#include "lightninglnurl.h"
#include "lightningutil.h"

#include <QObject>
#include <QString>
#include <QtTest/QtTest>

class LightningLnurlTest : public QObject
{
    Q_OBJECT

private slots:
    void parseMetadataDescription();
    void parseMetadataImagePng();
    void parseMetadataImageJpeg();
    void parseMetadataIgnoresInvalid();
    void domainFromLightningAddress();
    void domainFromCallback();
    void domainPrefersAddress();
    void satoshiMsatRoundTrip();
    void sendableSatoshiNonWholeBoundary();
    void commentLengthAscii();
    void commentLengthMultibyte();
    void commentLengthSurrogatePair();
    void userFacingErrorInvalidAddress();
    void userFacingErrorPassthrough();
};

void LightningLnurlTest::parseMetadataDescription()
{
    const auto metadata = ParseLightningLnurlMetadata(QStringLiteral(R"([["text/plain","Pay to Alice"]])"));
    QCOMPARE(metadata.description, QStringLiteral("Pay to Alice"));
    QVERIFY(metadata.image.isEmpty());
}

void LightningLnurlTest::parseMetadataImagePng()
{
    const auto metadata = ParseLightningLnurlMetadata(QStringLiteral(R"([["text/plain","Tip"],["image/png;base64","abc123"]])"));
    QCOMPARE(metadata.description, QStringLiteral("Tip"));
    QCOMPARE(metadata.image, QStringLiteral("data:image/png;base64,abc123"));
}

void LightningLnurlTest::parseMetadataImageJpeg()
{
    const auto metadata = ParseLightningLnurlMetadata(QStringLiteral(R"([["image/jpeg;base64","xyz"]])"));
    QCOMPARE(metadata.image, QStringLiteral("data:image/jpeg;base64,xyz"));
}

void LightningLnurlTest::parseMetadataIgnoresInvalid()
{
    const auto metadata = ParseLightningLnurlMetadata(QStringLiteral("not-json"));
    QVERIFY(metadata.description.isEmpty());
    QVERIFY(metadata.image.isEmpty());
}

void LightningLnurlTest::domainFromLightningAddress()
{
    QCOMPARE(LightningLnurlDomain(QStringLiteral("alice@getalby.com")), QStringLiteral("getalby.com"));
}

void LightningLnurlTest::domainFromCallback()
{
    QCOMPARE(
        LightningLnurlDomain(QStringLiteral("LNURL1EP..."), QStringLiteral("https://lnurl.example.com/callback")),
        QStringLiteral("lnurl.example.com"));
}

void LightningLnurlTest::domainPrefersAddress()
{
    QCOMPARE(
        LightningLnurlDomain(QStringLiteral("bob@wallet.example"), QStringLiteral("https://other.example/callback")),
        QStringLiteral("wallet.example"));
}

void LightningLnurlTest::satoshiMsatRoundTrip()
{
    QCOMPARE(LightningSatoshiToMsat(21), quint64(21000));
    QCOMPARE(LightningMsatToDisplaySatoshi(21000), quint64(21));
    QCOMPARE(LightningMsatToDisplaySatoshi(21001), quint64(22));
}

void LightningLnurlTest::sendableSatoshiNonWholeBoundary()
{
    // 1,500 msat: ceil min to 2 sat (pays 2,000 ≥ 1,500), floor max to 1 sat (pays 1,000 ≤ 1,500).
    QCOMPARE(LightningMsatToDisplaySatoshi(1500), quint64(2));
    QCOMPARE(LightningMsatToSatoshi(1500), quint64(1));
    QVERIFY(LightningSatoshiToMsat(LightningMsatToDisplaySatoshi(1500)) >= 1500);
    QVERIFY(LightningSatoshiToMsat(LightningMsatToSatoshi(1500)) <= 1500);

    // Whole-satoshi bounds stay exact.
    QCOMPARE(LightningMsatToDisplaySatoshi(2000), quint64(2));
    QCOMPARE(LightningMsatToSatoshi(2000), quint64(2));
}

void LightningLnurlTest::commentLengthAscii()
{
    QCOMPARE(LightningLnurlCommentLength(QStringLiteral("hello")), quint64(5));
}

void LightningLnurlTest::commentLengthMultibyte()
{
    // "café" is 4 UTF-16 units / characters, but 5 UTF-8 bytes.
    const auto comment = QStringLiteral("café");
    QCOMPARE(LightningLnurlCommentLength(comment), quint64(4));
    QVERIFY(static_cast<quint64>(comment.toUtf8().size()) > LightningLnurlCommentLength(comment));
}

void LightningLnurlTest::commentLengthSurrogatePair()
{
    // U+1F600 😀 is one code point / two UTF-16 units — same as TextInput.maximumLength.
    const auto comment = QString::fromUtf8("\xF0\x9F\x98\x80");
    QCOMPARE(comment.size(), 2);
    QCOMPARE(LightningLnurlCommentLength(comment), quint64(2));
}

void LightningLnurlTest::userFacingErrorInvalidAddress()
{
    QCOMPARE(
        LightningLnurlUserFacingError(QStringLiteral("error sending request for url (https://example.com/lnurlp/x)")),
        QStringLiteral("id_invalid_address"));
    QCOMPARE(
        LightningLnurlUserFacingError(QStringLiteral("error sending request for url (https://example.com): error trying to connect: dns error")),
        QStringLiteral("id_invalid_address"));
    QCOMPARE(
        LightningLnurlUserFacingError(QStringLiteral("Reqwest error: connection refused")),
        QStringLiteral("id_invalid_address"));
    QCOMPARE(
        LightningLnurlUserFacingError(QStringLiteral("HTTP status client error (404 Not Found)")),
        QStringLiteral("id_invalid_address"));
}

void LightningLnurlTest::userFacingErrorPassthrough()
{
    QCOMPARE(LightningLnurlUserFacingError(QStringLiteral("Payment failed")), QStringLiteral("Payment failed"));
}

QTEST_MAIN(LightningLnurlTest)
#include "tst_lightninglnurl.moc"
