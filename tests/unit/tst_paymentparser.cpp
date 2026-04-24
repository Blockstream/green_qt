#include "paymentparser.h"

#include <QDateTime>
#include <QObject>
#include <QSignalSpy>
#include <QtTest/QtTest>

namespace {

QVariantMap addressMap(const QString& network, const QString& address)
{
    return {
        {QStringLiteral("network"), network},
        {QStringLiteral("address"), address},
    };
}

QVariantMap addressRecipient(const QString& input, const QString& network, const QString& address)
{
    return {
        {QStringLiteral("input"), input},
        {QStringLiteral("address"), addressMap(network, address)},
    };
}

const QString kBitcoinMainnet = QStringLiteral("bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq");
const QString kBitcoinTestnet = QStringLiteral("tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx");
const QString kLiquidMainnet = QStringLiteral("lq1qqduq2l8maf4580wle4hevmk62xqqw3quckshkt2rex3ylw83824y4g96xl0uugdz4qks5v7w4pdpvztyy5kw7r7e56jcwm0p0");
const QString kLiquidTestnet = QStringLiteral("tlq1qq02egjncr8g4qn890mrw3jhgupwqymekv383lwpmsfghn36hac5ptpmeewtnftluqyaraa56ung7wf47crkn5fjuhk422d68m");
const QString kLiquidConfidential = QStringLiteral("VJL67HETqJCTg8Jak34N4RQaZD8HopbuhiU6F5kdo4d8QBJKTNJY3N1ictsXc1KAVNpaTEuCEoUCAzEj");
const QString kBolt11 = QStringLiteral("lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpu9qrsgquk0rl77nj30yxdy8j9vdx85fkpmdla2087ne0xh8nhedh8w27kyke0lp53ut353s06fv3qfegext0eh0ymjpf39tuven09sam30g4vgpfna3rh");

QVariantMap bolt11Recipient()
{
    const QVariantMap invoice{
        {QStringLiteral("amount_milli_satoshis"), QStringLiteral("250000000")},
        {QStringLiteral("expiry_time"), QStringLiteral("60")},
        {QStringLiteral("invoice"), kBolt11},
        {QStringLiteral("description"), QStringLiteral("1 cup coffee")},
        {QStringLiteral("min_final_cltv_expiry_delta"), QStringLiteral("18")},
        {QStringLiteral("network"), QStringLiteral("bitcoin")},
        {QStringLiteral("payment_hash"), QStringLiteral("0001020304050607080900010203040506070809000102030405060708090102")},
        {QStringLiteral("payment_secret"), QStringLiteral("1111111111111111111111111111111111111111111111111111111111111111")},
        {QStringLiteral("timestamp"), QDateTime::fromSecsSinceEpoch(1496314658)},
    };
    return {
        {QStringLiteral("input"), kBolt11},
        {QStringLiteral("invoice"), invoice},
    };
}

} // namespace

class RecipientParserTest : public QObject
{
    Q_OBJECT

private slots:
    void invalidInputIsRejected();
    void sameInputDoesNotEmitAgain();
    void validPaymentParsesRecipient_data();
    void validPaymentParsesRecipient();
};

void RecipientParserTest::invalidInputIsRejected()
{
    RecipientParser parser;
    QSignalSpy recipientSpy(&parser, &RecipientParser::recipientChanged);

    parser.setInput(QStringLiteral("definitely-not-a-payment"));

    QTRY_COMPARE_WITH_TIMEOUT(recipientSpy.count(), 1, 1000);
    const QVariantMap recipient = parser.recipient();
    QCOMPARE(recipient.value(QStringLiteral("input")).toString(), QStringLiteral("definitely-not-a-payment"));
    QVERIFY(recipient.contains(QStringLiteral("error")));
}

void RecipientParserTest::sameInputDoesNotEmitAgain()
{
    RecipientParser parser;
    QSignalSpy inputSpy(&parser, &RecipientParser::inputChanged);
    QSignalSpy busySpy(&parser, &RecipientParser::busyChanged);
    QSignalSpy recipientSpy(&parser, &RecipientParser::recipientChanged);

    parser.setInput(QStringLiteral("still-not-valid"));
    QTRY_COMPARE_WITH_TIMEOUT(recipientSpy.count(), 1, 1000);
    const int inputCount = inputSpy.count();
    const int busyCount = busySpy.count();

    parser.setInput(QStringLiteral("still-not-valid"));
    QCOMPARE(inputSpy.count(), inputCount);
    QCOMPARE(busySpy.count(), busyCount);
    QCOMPARE(recipientSpy.count(), 1);
    QCOMPARE(parser.input(), QStringLiteral("still-not-valid"));
}

void RecipientParserTest::validPaymentParsesRecipient_data()
{
    QTest::addColumn<QString>("input");
    QTest::addColumn<QVariantMap>("recipient");

    QTest::newRow("bitcoin mainnet")
        << kBitcoinMainnet
        << addressRecipient(kBitcoinMainnet, QStringLiteral("bitcoin"), kBitcoinMainnet);
    QTest::newRow("bitcoin testnet")
        << kBitcoinTestnet
        << addressRecipient(kBitcoinTestnet, QStringLiteral("testnet"), kBitcoinTestnet);
    QTest::newRow("liquid mainnet")
        << kLiquidMainnet
        << addressRecipient(kLiquidMainnet, QStringLiteral("liquid"), kLiquidMainnet);
    QTest::newRow("liquid testnet")
        << kLiquidTestnet
        << addressRecipient(kLiquidTestnet, QStringLiteral("testnet-liquid"), kLiquidTestnet);

    const QString bitcoinBip21 = QStringLiteral("bitcoin:%1?amount=0.01&label=Example&message=Donation").arg(kBitcoinMainnet);
    QVariantMap bitcoinBip21Recipient = addressRecipient(bitcoinBip21, QStringLiteral("bitcoin"), kBitcoinMainnet);
    bitcoinBip21Recipient.insert(QStringLiteral("bip21"), QVariantMap{
        {QStringLiteral("amount"), QStringLiteral("1000000")},
        {QStringLiteral("label"), QStringLiteral("Example")},
        {QStringLiteral("message"), QStringLiteral("Donation")},
    });
    QTest::newRow("bitcoin bip21") << bitcoinBip21 << bitcoinBip21Recipient;

    const QString liquidBip21 = QStringLiteral("liquidnetwork:%1?amount=0.00001000&assetid=6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d").arg(kLiquidConfidential);
    QVariantMap liquidBip21Recipient = addressRecipient(liquidBip21, QStringLiteral("liquid"), kLiquidConfidential);
    liquidBip21Recipient.insert(QStringLiteral("bip21"), QVariantMap{
        {QStringLiteral("asset_id"), QStringLiteral("6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d")},
        {QStringLiteral("amount"), QStringLiteral("1000")},
    });
    QTest::newRow("liquid bip21") << liquidBip21 << liquidBip21Recipient;

    QTest::newRow("bolt11") << kBolt11 << bolt11Recipient();
}

void RecipientParserTest::validPaymentParsesRecipient()
{
    QFETCH(QString, input);
    QFETCH(QVariantMap, recipient);

    RecipientParser parser;
    QSignalSpy inputSpy(&parser, &RecipientParser::inputChanged);
    QSignalSpy busySpy(&parser, &RecipientParser::busyChanged);
    QSignalSpy recipientSpy(&parser, &RecipientParser::recipientChanged);

    QVERIFY(!parser.isBusy());
    parser.setInput(input);
    QCOMPARE(parser.input(), input);
    QCOMPARE(inputSpy.count(), 1);
    QVERIFY(parser.isBusy());
    QCOMPARE(busySpy.count(), 1);

    QTRY_COMPARE_WITH_TIMEOUT(recipientSpy.count(), 1, 1000);
    QVERIFY(!parser.isBusy());
    QCOMPARE(busySpy.count(), 2);
    QCOMPARE(recipientSpy.count(), 1);
    QCOMPARE(parser.recipient(), recipient);
}

QTEST_GUILESS_MAIN(RecipientParserTest)
#include "tst_paymentparser.moc"
